// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <algorithm>
#import <atomic>
#import <cassert>
#import <functional>
#import <string>
#import <vector>

#import <AudioToolbox/AudioToolbox.h>

#import "DSPHeaders/SampleBuffer.hpp"
#import "DSPHeaders/BusBuffers.hpp"
#import "DSPHeaders/Parameters/Base.hpp"

namespace DSPHeaders {

/**
 Base template class for DSP kernels that provides common functionality. It uses the "Curiously Recurring Template
 Pattern (CRTP)" to interleave base functionality contained in this class with custom functionality from the derived
 class without the need for virtual dispatching.

 It is expected that the template parameter class T defines the following methods which this class will
 invoke at the appropriate times but without any virtual dispatching.

 - doParameterEvent -- process AURenderEventParameterRamp or AURenderEventParameter event and return `true` if valid
 - doMIDIEvent
 - doRendering

 */
template <typename ValueType>
class EventProcessor {
public:
  using ParameterVector = std::vector<std::reference_wrapper<DSPHeaders::Parameters::Base>>;

  /**
   Construct new instance.
   */
  EventProcessor() noexcept : derived_{static_cast<ValueType&>(*this)}, buffers_{}, facets_{} {}

  /**
   Set the bypass mode.

   @param bypass if true disable filter processing and just copy samples from input to output
   */
  void setBypass(bool bypass) noexcept {
    bypassed_.store(bypass, std::memory_order_relaxed);
  }

  /// @returns true if effect is bypassed
  bool isBypassed() const noexcept { return bypassed_; }

  /// @returns true if actively rendering samples
  bool isRendering() const noexcept { return rendering_; }

  /// @returns true if actively ramping one or more parameters
  bool isRamping() const noexcept { return rampRemaining_ > 0; }

  /**
   Update kernel and buffers to support the given format.

   @param busCount the number of busses being used in the audio processing flow
   @param format the sample format to expect
   @param maxFramesToRender the maximum number of frames to expect on input
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) noexcept {
    sampleRate_ = format.sampleRate;
    rampDuration_ = AUAudioFrameCount(floor(0.02 * sampleRate_));

    auto channelCount{[format channelCount]};

    // We want an internal buffer for each bus that we can generate output on. This is not strictly required since we
    // will be rendering one bus at a time, but doing so allows us to process the samples "in-place" and pass the buffer
    // to the audio unit without having to make a copy for the next element in the signal processing chain.
    while (buffers_.size() < size_t(busCount)) {
      buffers_.emplace_back();
      facets_.emplace_back();
    }

    // Extra facet to use for input buffer used by a `pullInputBlock`
    facets_.emplace_back();

    // Setup facets to have the right channel count so we do not allocate while rendering
    for (auto& entry : facets_) {
      entry.setChannelCount(channelCount);
    }

    // Setup sample buffers to have the right format and capacity
    for (auto& entry : buffers_) {
      entry.allocate(format, maxFramesToRender);
    }

    // Link the output buffers with their corresponding facets. This only needs to be done once.
    for (size_t busIndex = 0; busIndex < buffers_.size(); ++busIndex) {
      facets_[busIndex].assignBufferList(buffers_[busIndex].mutableAudioBufferList());
    }

    setRendering(true);
  }

  /// @returns current sample rate that is in effect
  double sampleRate() const noexcept { return sampleRate_; }

  /**
   Rendering has stopped. Free up any resources it used.
   */
  void deallocateRenderResources() noexcept {
    setRendering(false);

    for (auto& entry : facets_) {
      if (entry.isLinked()) entry.unlink();
    }

    for (auto& entry : buffers_) {
      entry.release();
    }
  }

  /**
   Process events and render a given number of frames. Events and rendering are interleaved if necessary so that
   event times align with samples.

   @param timestamp the timestamp of the first sample or the first event
   @param frameCount the number of frames to process
   @param outputBusNumber the bus to render (normally only 0)
   @param output the buffer to hold the rendered samples
   @param realtimeEventListHead pointer to the first AURenderEvent (may be null)
   @param pullInputBlock the closure to call to obtain upstream samples
   */
  AUAudioUnitStatus processAndRender(const AudioTimeStamp* timestamp, UInt32 frameCount, NSInteger outputBusNumber,
                                     AudioBufferList* output, const AURenderEvent* realtimeEventListHead,
                                     AURenderPullInputBlock pullInputBlock) noexcept {
    size_t outputBusIndex = size_t(outputBusNumber);
    assert(outputBusIndex < buffers_.size());

    // Get a buffer to use to read into if there is a `pullInputBlock`. We will also modify it in-place if necessary
    // use it for an output buffer if necessary.
    auto& outputBusBuffer{buffers_[outputBusIndex]};
    if (frameCount > outputBusBuffer.capacity()) [[unlikely]] {
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    // Setup the rendering destination to properly use the internal buffer or the buffer attached to `output`.
    facets_[outputBusIndex].assignBufferList(output, outputBusBuffer.mutableAudioBufferList());
    facets_[outputBusIndex].setFrameCount(frameCount);

    if (pullInputBlock) [[likely]] {

      // Pull input samples from upstream. Use same output buffer to perform in-place rendering.
      BufferFacet& input{inputFacet()};
      input.assignBufferList(output, outputBusBuffer.mutableAudioBufferList());
      input.setFrameCount(frameCount);

      AudioUnitRenderActionFlags actionFlags = 0;
      auto status = input.pullInput(&actionFlags, timestamp, frameCount, outputBusNumber, pullInputBlock);
      if (status != noErr) {
        return status;
      }
    } else [[unlikely]] {

      // Clear the output buffer before use when there is no input data. Important if we are in bypass mode.
      UInt32 byteSize = frameCount * sizeof(AUValue);
      for (UInt32 index = 0; index < output->mNumberBuffers; ++index) {
        auto& buf{output->mBuffers[index]};
        memset(buf.mData, 0, byteSize);
      }
    }

    // Apply any paramter changes posted by the UI
    checkForParameterChanges();
    render(outputBusNumber, timestamp, frameCount, realtimeEventListHead);

    return noErr;
  }

protected:

  /**
   Set the rendering state of the host.

   @param rendering if true the host is "transport" is moving and we are expected to render samples.
   */
  void setRendering(bool rendering) noexcept {
    if (rendering == rendering_) return;
    rendering_.store(rendering, std::memory_order_relaxed);
    renderingStateChanged();
  }

  void registerParameters(ParameterVector&& collection) {
    parameters_ = collection;
  }

  void registerParameter(Parameters::Base& parameter) { parameters_.push_back(parameter); }

  /**
   Obtain a `busBuffer` for the given bus.

   @param bus the bus to whose buffers will be pointed to
   @returns BusBuffers instance
   */
  BusBuffers busBuffers(size_t bus) noexcept { return facets_[bus].busBuffers(); }

  void checkForParameterChanges() noexcept {
    auto changed = false;
    for (auto param : parameters_) {
      changed |= param.get().checkForChange(rampDuration_);
    }
    if (changed && rampDuration_ > rampRemaining_) [[unlikely]] rampRemaining_ = rampDuration_;
  }

private:

  void renderingStateChanged() noexcept {
    for (auto param : parameters_) {
      param.get().stopRamping();
    }
    rampRemaining_ = 0;
  }

  BufferFacet& inputFacet() noexcept { assert(!facets_.empty()); return facets_.back(); }

  void render(NSInteger outputBusNumber, AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount,
              AURenderEvent const* events) noexcept {
    auto zero = AUEventSampleTime(0);
    auto now = AUEventSampleTime(timestamp->mSampleTime);
    auto framesRemaining = frameCount;

    while (framesRemaining > 0) {

      // Short-circuit if there are no more events to interleave
      if (events == nullptr) [[likely]] {
        renderFrames(outputBusNumber, framesRemaining, frameCount - framesRemaining);
        return;
      }

      auto framesThisSegment = AUAudioFrameCount(std::max(events->head.eventSampleTime - now, zero));
      if (framesThisSegment > 0) [[likely]] {
        renderFrames(outputBusNumber, framesThisSegment, frameCount - framesRemaining);
        framesRemaining -= framesThisSegment;
        now += AUEventSampleTime(framesThisSegment);
      }

      // Process the events for the current time
      events = processEventsUntil(now, events);
    }
  }

  AURenderEvent const* processEventsUntil(AUEventSampleTime now, AURenderEvent const* event) noexcept {
    // See http://devnotes.kymatica.com/auv3_parameters.html for some nice details and advice about parameter event
    // processing.
    while (event != nullptr && event->head.eventSampleTime <= now) {
      switch (event->head.eventType) {
        case AURenderEventParameter:
          if (derived_.doParameterEvent(event->parameter, rampDuration_)) {
            if (rampDuration_ > rampRemaining_) rampRemaining_ = rampDuration_;
          }
          break;

        case AURenderEventParameterRamp:
          if (derived_.doParameterEvent(event->parameter, event->parameter.rampDurationSampleFrames)) {
            if (event->parameter.rampDurationSampleFrames > rampRemaining_) {
              rampRemaining_ = event->parameter.rampDurationSampleFrames;
            }
          }
          break;

        case AURenderEventMIDI:
        case AURenderEventMIDISysEx:
          derived_.doMIDIEvent(event->MIDI);
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

  void renderFrames(NSInteger outputBusNumber, AUAudioFrameCount frameCount, AUAudioFrameCount processedFrameCount) {
    size_t outputBusIndex = size_t(outputBusNumber);

    // This method can be called multiple times during one `processAndRender` call due to interleaved audio events
    // such as MIDI messages. We will generate in total `frameCount` + `processedFrameCount` samples, but maybe not in
    // one shot. As a result, we must adjust buffer pointers by the number of processed samples so far before we
    // let the kernel render into our buffers.
    for (size_t busIndex = 0; busIndex < buffers_.size(); ++busIndex) {
      auto& facet{facets_[busIndex]};
      facet.setOffset(processedFrameCount);
    }

    auto& input{inputFacet()};
    if (isBypassed()) [[unlikely]] {
      // If we have input samples from an upstream node, either use the sample buffers directly or copy samples over
      // to the output buffer. Otherwise, we have already zero'd out the output buffer, so we are done.
      if (input.isLinked()) {
        input.copyInto(facets_[outputBusIndex], processedFrameCount, frameCount);
      }
      return;
    }

    auto& output{facets_[outputBusIndex]};

    // If ramping one or more parameters, we must render one frame at a time. Since this is more expensive than the
    // non-ramp case, we only do it when necessary.
    if (isRamping()) [[unlikely]] {
      auto rampCount = std::min(rampRemaining_, frameCount);
      frameCount -= rampCount;
      for (; rampCount > 0; --rampCount) {
        derived_.doRendering(outputBusNumber, input.busBuffers(), output.busBuffers(), 1);
      }
      rampRemaining_ -= rampCount;
    }

    // Non-ramping case. NOTE: do not use else since we could end a ramp while still having frameCount > 0.
    if (frameCount > 0) [[likely]] {
      derived_.doRendering(outputBusNumber, input.busBuffers(), output.busBuffers(), frameCount);
    }
  }

  ValueType& derived_;
  std::vector<SampleBuffer> buffers_;
  std::vector<BufferFacet> facets_;
  AUAudioFrameCount rampDuration_{0};
  AUAudioFrameCount rampRemaining_{0};

  std::atomic<bool> bypassed_{false};
  std::atomic<bool> rendering_{false};

  double sampleRate_{};

  ParameterVector parameters_{};
  AUParameterTree* parameterTree_ = nullptr;
};

/**
 Concept definition for a valid Kernel class, one that provides method definitions for the functions
 used by the EventProcessor template.
 */
template<typename T>
concept KernelT = requires(T a, const AUParameterEvent& param, const AUMIDIEvent& midi, BusBuffers bb)
{
  { a.doParameterEvent(param, AUAudioFrameCount(1)) } -> std::convertible_to<bool>;
  { a.doMIDIEvent(midi) } -> std::convertible_to<void>;
  { a.doRendering(NSInteger(1), bb, bb, AUAudioFrameCount(1) ) } -> std::convertible_to<void>;
};

/**
 A semi-hacky way to obtain compile-time errors for a Kernel class that is not configured correctly.
 Ideally this would be part of the `EventProcessor` template but that is not possible due to the use
 of CRTP since the traits defined in `KernelT` require a complete type, but the use of CRTP results
 in an incomplete type until the type is closed.
 ```
 ValidatedKernel<MyKernel> _;
 ```
 */
template <KernelT T>
struct ValidatedKernel {};

} // end namespace DSPHeaders
