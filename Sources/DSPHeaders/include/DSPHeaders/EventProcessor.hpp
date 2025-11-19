// Copyright © 2021-2025 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <algorithm>
#import <atomic>
#import <cassert>
#import <concepts>
#import <functional>
#import <initializer_list>
#import <ranges>
#import <string>
#import <unordered_map>

#import <AudioToolbox/AudioToolbox.h>

#import "DSPHeaders/BusBufferFacet.hpp"
#import "DSPHeaders/BusSampleBuffer.hpp"
#import "DSPHeaders/BusBuffers.hpp"
#import "DSPHeaders/Parameters/Base.hpp"
#import "DSPHeaders/Concepts.hpp"

namespace DSPHeaders {

/**
 Base template class for DSP kernels that provides common functionality. It uses the "Curiously Recurring Template
 Pattern (CRTP)" to interleave base functionality contained in this class with custom functionality from the derived
 class without the need for virtual dispatching.

 It is expected that the template parameter class T defines the following methods which this class will
 invoke at the appropriate times but without any virtual dispatching. The only one that is required is
 the `doRendering` method.

 - doRendering -- perform rendering of samples
 - doSetImmediateParameterValue [optional] -- set a parameter value from within the render loop. The default action
 is to invoke the parameter's setImmediate method.
 - doSetPendingParameterValue [optional] -- set a paramete value from outside render loop (AUParameterTree)
 - doGetImmediateParameterValue [optional] -- read parameter value set by render loop
 - doGetPendingParameterValue [optional] -- read parameter value set outside render loop (AUParameterTree)
 - doMIDIEvent [optional] -- process MIDI v1 message
 - doRenderingStateChanged [optional] -- notification that the rendering state has changed
 */
template <typename KernelType>
class EventProcessor {
public:
  using ParameterMap = std::unordered_map<AUParameterAddress, std::reference_wrapper<DSPHeaders::Parameters::Base>>;

  /**
   Construct new instance.
   */
  EventProcessor(std::string name) noexcept
  : log_{os_log_create(name.c_str(), "Kernel")}, derived_{static_cast<KernelType&>(*this)} {}

  /**
   Set the bypass mode.

   NOTE: we expose this to the kernel, but the AUv3 component has a value as well which actually does the
   right thing when set to `true` in which case the kernel's rendering routines will not be called at all.

   @param bypass if true disable filter processing and just copy samples from input to output
   */
  inline void setBypass(bool bypass) noexcept { bypassed_.store(bypass, std::memory_order_relaxed); }

  /// @returns true if effect is bypassed
  inline bool isBypassed() const noexcept { return bypassed_.load(std::memory_order_relaxed); }

  /// @returns true if actively rendering samples
  inline bool isRendering() const noexcept { return rendering_.load(std::memory_order_relaxed); }

  /// @returns true if actively ramping one or more parameters
  inline bool isRamping() const noexcept { return rampRemaining_ > 0; }

  /**
   Update kernel and buffers to support the given format.

   @param busCount the number of busses being used in the audio processing flow
   @param format the sample format to expect
   @param maxFramesToRender the maximum number of frames to expect on input
   @param treeBasedRampDuration the number of frames to ramp a parameter value change
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* _Nonnull format,
                          AUAudioFrameCount maxFramesToRender, AUAudioFrameCount treeBasedRampDuration = 16) noexcept {
    sampleRate_ = format.sampleRate;
    treeBasedRampDuration_ = treeBasedRampDuration;

    auto channelCount{format.channelCount};

    // We want an internal buffer for each bus that we can generate output on. This is not strictly required since we
    // will be rendering one bus at a time, but doing so allows us to process the samples "in-place" and pass the buffer
    // to the audio unit without having to make a copy for the next element in the signal processing chain.
    while (outputBusses_.size() < size_t(busCount)) {
      outputBusses_.emplace_back();
      outputFacets_.emplace_back();
    }

    // Extra facet at end is reserved for `pullInputBlock` processing to hold input samples.
    // facets_.emplace_back();

    // Setup facets to have the right channel count so we do not allocate while rendering.
    for (auto& facet : outputFacets_) facet.setChannelCount(channelCount);
    inputFacet_.setChannelCount(channelCount);

    // Setup sample buffers to have the right format and capacity. This is constant as long as rendering is active.
    for (auto& entry : outputBusses_) entry.allocate(format, maxFramesToRender);

    // Link the output buffers with their corresponding facets. This only needs to be done once.
    for (auto pair : std::views::zip(outputFacets_, outputBusses_)) {
      std::get<0>(pair).assignBufferList(std::get<1>(pair).mutableAudioBufferList());
    }

    setRendering(true);
  }

  /// @returns current sample rate that is in effect
  inline double sampleRate() const noexcept { return sampleRate_; }

  /**
   Rendering has stopped. Free up any resources it used.
   */
  void deallocateRenderResources() noexcept {
    setRendering(false);
    for (auto& facet : outputFacets_) if (facet.isLinked()) facet.unlink();
    for (auto& bus : outputBusses_) bus.release();
  }

  /**
   Process an AU parameter value change from the parameter tree. This is only called from the KernelBridge class to
   handle UI component changes.

   @param address the address of the parameter that changed
   @param value the new value for the parameter
   @returns `true` if the parameter is valid
   */
  inline bool setParameterValue(AUParameterAddress address, AUValue value) noexcept {
    return isRendering() ? setPendingParameterValue(address, value) : setImmediateParameterValue(address, value, 0);
  }

  /**
   Process an AU parameter value request from the parameter tree. This is only called from the KernelBridge class to
   handle UI component requests for values.

   @param address the address of the parameter
   @returns the value for the parameter
   */
  inline AUValue getParameterValue(AUParameterAddress address) noexcept {
    return isRendering() ? getPendingParameterValue(address) : getImmediateParameterValue(address);
  }

  /**
   Process events and render a given number of frames. Events and rendering are interleaved when necessary so that
   event times align with samples.

   @param timestamp the timestamp of the first sample or the first event
   @param frameCount the number of frames to process
   @param outputBusNumber the bus to render (normally only 0)
   @param output the buffer to hold the rendered samples
   @param realtimeEventListHead pointer to the first AURenderEvent (may be null)
   @param pullInputBlock the closure to call to obtain upstream samples
   */
  AUAudioUnitStatus processAndRender(const AudioTimeStamp* _Nonnull timestamp,
                                     UInt32 frameCount,
                                     NSInteger outputBusNumber,
                                     AudioBufferList* _Nonnull output,
                                     const AURenderEvent* _Nullable realtimeEventListHead,
                                     AURenderPullInputBlock _Nullable pullInputBlock) noexcept {
    size_t outputBusIndex = size_t(outputBusNumber);
    assert(outputBusIndex < outputBusses_.size());

    // Get a buffer to use to read into if there is a `pullInputBlock`. We will also modify it in-place if necessary
    // use it for an output buffer if necessary.
    auto& outputBus{outputBusses_[outputBusIndex]};
    if (frameCount > outputBus.capacity()) [[unlikely]] {
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    // Setup the rendering destination to properly use the internal buffer or the buffer attached to `output`.
    outputFacets_[outputBusIndex].assignBufferList(output, outputBus.mutableAudioBufferList());
    outputFacets_[outputBusIndex].setFrameCount(frameCount);

    if (pullInputBlock) [[likely]] {

      // Pull input samples from upstream. If the output buffer we are given has no storage assigned to it, then we
      // will use our own and perform in-place rendering of the samples. This is detected and handled in the
      // `assignBufferList` method.
      inputFacet_.assignBufferList(output, outputBus.mutableAudioBufferList());
      inputFacet_.setFrameCount(frameCount);

      AudioUnitRenderActionFlags actionFlags = 0;
      auto status = inputFacet_.pullInput(&actionFlags, timestamp, frameCount, outputBusNumber, pullInputBlock);
      if (status != noErr) [[unlikely]] {
        return status;
      }
    } else {

      // Clear the output buffer before use when there is no input data.
      outputFacets_[outputBusIndex].clear(frameCount);
    }

    // Apply any paramter changes posted by the UI
    checkForParameterValueChanges();
    render(outputBusNumber, timestamp, frameCount, realtimeEventListHead);

    return noErr;
  }

  /// @returns the ramp duration to use for UI changes
  AUAudioFrameCount treeBasedRampDuration() const noexcept { return treeBasedRampDuration_; }

  /// @returns the max number of frames remaining in any parameter ramping.
  AUAudioFrameCount rampRemaining() const noexcept { return rampRemaining_; }

protected:

  /**
   Set the rendering state of the host.

   @param rendering if true the host is "transport" is moving and we are expected to render samples.
   */
  void setRendering(bool rendering) noexcept {
    if (rendering != rendering_) [[likely]] {
      rendering_.store(rendering, std::memory_order_relaxed);
      renderingStateChanged();
    }
  }

  /**
   Register one or more parameters.

   @param params the collection of parameters to register
   */
  void registerParameters(std::initializer_list<std::reference_wrapper<Parameters::Base>> params) noexcept {
    for (auto param : params) {
      registerParameter(param);
    }
  }

  /**
   Register one parameter.

   @param parameter the parameter to register
   */
  void registerParameter(Parameters::Base& parameter) {
    auto result = parameters_.emplace(parameter.address(), parameter);
    assert(result.second);
  }

  /**
   Obtain a `busBuffer` for the given bus.

   @param bus the bus to whose buffers will be pointed to
   @returns BusBuffers instance
   */
  BusBuffers busBuffers(size_t bus) noexcept { return outputFacets_[bus].busBuffers(); }

  /**
   Visit registered parameters and see if they have a change pending from the AUParameterTree.

   @returns true if there is was a new change
   */
  bool checkForParameterValueChanges() noexcept {
    auto changed = false;
    for (auto param : parameters_) {
      changed |= param.second.get().checkForValueChange(treeBasedRampDuration_);
    }

    if (changed) {
      rampRemaining_ = std::max(treeBasedRampDuration_ - 1, rampRemaining_);
    } else if (rampRemaining_ > 0) {
      rampRemaining_ -= 1;
    }

    return changed;
  }

  os_log_t _Nonnull log_;

private:

  bool setPendingParameterValue(AUParameterAddress address, AUValue value) noexcept {
    os_log_info(log_, "setPendingParameterValue - %llu %f", address, value);
    if constexpr (HasSetPendingParameterValue<KernelType>) return derived_.doSetPendingParameterValue(address, value);
    auto pos = parameters_.find(address);
    return pos != parameters_.end() ? pos->second.get().setPending(value), true : false;
  }

  bool setImmediateParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept {
    os_log_info(log_, "setImmediateParameterValue - %llu %f", address, value);
    if constexpr (HasSetImmediateParameterValue<KernelType>)
      return derived_.doSetImmediateParameterValue(address, value, duration);
    auto pos = parameters_.find(address);
    return pos != parameters_.end() ? pos->second.get().setImmediate(value, duration), true : false;
  }

  AUValue getPendingParameterValue(AUParameterAddress address) const noexcept {
    if constexpr (HasGetPendingParameterValue<KernelType>) return derived_.doGetPendingParameterValue(address);
    auto pos = parameters_.find(address);
    return pos != parameters_.end() ? pos->second.get().getPending() : 0.0;
  }

  AUValue getImmediateParameterValue(AUParameterAddress address) const noexcept {
    if constexpr (HasGetImmediateParameterValue<KernelType>) return derived_.doGetImmediateParameterValue(address);
    auto pos = parameters_.find(address);
    return pos != parameters_.end() ? pos->second.get().getImmediate() : 0.0;
  }

  void renderingStateChanged() noexcept {
    for (auto param : parameters_) param.second.get().stopRamping();
    rampRemaining_ = 0;
    if constexpr (HasRenderingStateChangedT<KernelType>) derived_.doRenderingStateChanged(isRendering());
  }

  void render(NSInteger outputBusNumber, AudioTimeStamp const* _Nonnull timestamp, AUAudioFrameCount frameCount,
              AURenderEvent const* _Nullable events) noexcept {
    auto& outputFacet{outputFacets_[size_t(outputBusNumber)]};
    auto now = AUEventSampleTime(timestamp->mSampleTime);
    auto framesRemaining = frameCount;

    while (framesRemaining > 0) [[likely]] {

      // Short-circuit if there are no more events to interleave
      if (events == nullptr) [[likely]] {
        makeFrames(outputFacet, framesRemaining, frameCount - framesRemaining);
        return;
      }

      // See if there are frames to process before the next event. Here "time" is measured in samples, so we just need
      // to change type to convert between the two.
      auto eventSampleTime = events->head.eventSampleTime;
      auto framesBefore = AUAudioFrameCount(eventSampleTime < now ? 0 : eventSampleTime - now);

      if (framesBefore > 0) [[likely]] {
        makeFrames(outputFacet, framesBefore, frameCount - framesRemaining);
        framesRemaining -= framesBefore;
        now += AUEventSampleTime(framesBefore);
      }

      // Process the events for the current time
      events = processEventsUntil(now, events);
    }
  }

  void processEventParameterChange(const AUParameterEvent& event, AUAudioFrameCount duration) noexcept {
    if (setImmediateParameterValue(event.parameterAddress, event.value, duration)) {
      rampRemaining_ = std::max(duration - 1, rampRemaining_);
    }
  }

  AURenderEvent const* _Nullable processEventsUntil(AUEventSampleTime now,
                                                    AURenderEvent const* _Nonnull event) noexcept {
    while (event != nullptr && event->head.eventSampleTime <= now) {
      switch (event->head.eventType) {
        case AURenderEventParameter:
          os_log_info(log_, "AURenderEventParameter - %llu %f", event->parameter.parameterAddress,
                      event->parameter.value);
          processEventParameterChange(event->parameter, treeBasedRampDuration_);
          break;

        case AURenderEventParameterRamp:
          os_log_info(log_, "AURenderEventParameterRamp - %llu %f %d", event->parameter.parameterAddress,
                      event->parameter.value, event->parameter.rampDurationSampleFrames);
          processEventParameterChange(event->parameter, event->parameter.rampDurationSampleFrames);
          break;

        case AURenderEventMIDI:
        case AURenderEventMIDISysEx:
          if constexpr (HasMIDIEventV1<KernelType>) derived_.doMIDIEvent(event->MIDI);
          break;

        case AURenderEventMIDIEventList:
          // TODO: handle MIDI v2 packets
          break;

        default:
          break;
      }
      event = event->head.next;
    }
    return event;
  }

  inline void makeFrames(BusBufferFacet& outputFacet, AUAudioFrameCount frameCount, AUAudioFrameCount processed) {
    // This method may be called multiple times during one `processAndRender` call due to interleaved audio events
    // such as MIDI messages. We will generate in total `frameCount` + `processedFrameCount` samples, but maybe not in
    // one shot. As a result, we must adjust buffer pointers by the number of processed samples so far before we
    // let the kernel render into our buffers.
    for (auto& facet : outputFacets_) facet.setOffset(processed);
    isBypassed() ? bypassedFrames(outputFacet, frameCount, processed) : renderedFrames(outputFacet, frameCount);
  }

  inline void bypassedFrames(BusBufferFacet& outputFacet, AUAudioFrameCount frameCount, AUAudioFrameCount processed) {
    // If we have input samples from an upstream node, either use the sample buffers directly or copy samples over
    // to the output buffer. Otherwise, we have already zero'd out the output buffer, so we are done.
    if (inputFacet_.isLinked()) {
      inputFacet_.copyInto(outputFacet, processed, frameCount);
    }
  }

  inline void renderedFrames(BusBufferFacet& outputFacet, AUAudioFrameCount frameCount) {
    derived_.doRendering(inputFacet_.busBuffers(), outputFacet.busBuffers(), frameCount);
  }

  KernelType& derived_;
  std::vector<BusSampleBuffer> outputBusses_{};
  std::vector<BusBufferFacet> outputFacets_{};
  BusBufferFacet inputFacet_{};
  AUAudioFrameCount treeBasedRampDuration_{0};
  AUAudioFrameCount rampRemaining_{0};

  std::atomic<bool> bypassed_{false};
  std::atomic<bool> rendering_{false};

  double sampleRate_{};

  ParameterMap parameters_{};
};

/**
 A semi-hacky way to obtain compile-time errors for a Kernel class that is not configured correctly.
 Ideally this would be part of the `EventProcessor` template but that is not possible due to the use
 of CRTP since the traits defined in `T` require a complete type, but the use of CRTP results
 in an incomplete type until the type is closed.
 ```
 ValidatedKernel<MyKernel> _;
 ```
 */
template <IsViableKernelType T>
struct ValidatedKernel {};

} // end namespace DSPHeaders
