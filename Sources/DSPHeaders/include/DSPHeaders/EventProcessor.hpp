// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <algorithm>
#import <string>
#import <vector>

#import <AudioToolbox/AudioToolbox.h>

#import "DSPHeaders/SampleBuffer.hpp"
#import "DSPHeaders/BusBuffers.hpp"

namespace DSPHeaders {

/**
 Base template class for DSP kernels that provides common functionality. It uses the "Curiously Recurring Template
 Pattern (CRTP)" to interleave base functionality contained in this class with custom functionality from the derived
 class without the need for virtual dispatching.

 It is expected that the template parameter class T defines the following methods which this class will
 invoke at the appropriate times but without any virtual dispatching.

 - doParameterEvent
 - doMIDIEvent
 - doRenderFrames
 - doRenderingStateChanged

 */
template <typename ValueType>
class EventProcessor {
public:

  /**
   Construct new instance.
   */
  EventProcessor() noexcept : derived_{static_cast<ValueType&>(*this)}, buffers_{}, facets_{} {}

  /**
   Set the bypass mode.

   @param bypass if true disable filter processing and just copy samples from input to output
   */
  void setBypass(bool bypass) noexcept { bypassed_ = bypass; }

  /// @returns true if effect is bypassed
  bool isBypassed() const noexcept { return bypassed_; }

  /**
   Set the rendering state of the host.

   @param rendering if true the host is "transport" is moving and we are expected to render samples.
   */
  void setRendering(bool rendering) noexcept {
    if (rendering != rendering_) {
      rendering_ = rendering;
      derived_.doRenderingStateChanged(rendering);
    }
  }

  /// @returns true if actively rendering samples
  bool isRendering() const noexcept { return rendering_; }

  /**
   Update kernel and buffers to support the given format.

   @param busCount the number of busses being used in the audio processing flow
   @param format the sample format to expect
   @param maxFramesToRender the maximum number of frames to expect on input
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) noexcept {
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

  /**
   Rendering has stopped. Free up any resources it used.
   */
  void deallocateRenderResources() noexcept {
    for (auto& entry : facets_) {
      if (entry.isLinked()) entry.unlink();
    }

    for (auto& entry : buffers_) {
      entry.release();
    }

    setRendering(false);
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
    if (frameCount > outputBusBuffer.capacity()) {
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    // Setup the rendering destination to properly use the internal buffer or the buffer attached to `output`.
    facets_[outputBusIndex].assignBufferList(output, outputBusBuffer.mutableAudioBufferList());
    facets_[outputBusIndex].setFrameCount(frameCount);

    if (pullInputBlock) {

      // Pull input samples from upstream. Use same output buffer to perform in-place rendering.
      BufferFacet& input{inputFacet()};
      input.assignBufferList(output, outputBusBuffer.mutableAudioBufferList());
      input.setFrameCount(frameCount);

      AudioUnitRenderActionFlags actionFlags = 0;
      auto status = input.pullInput(&actionFlags, timestamp, frameCount, outputBusNumber, pullInputBlock);
      if (status != noErr) {
        return status;
      }
    } else {

      // Clear the output buffer before use when there is no input data. Important if we are in bypass mode.
      UInt32 byteSize = frameCount * sizeof(AUValue);
      for (UInt32 index = 0; index < output->mNumberBuffers; ++index) {
        auto& buf{output->mBuffers[index]};
        memset(buf.mData, 0, byteSize);
      }
    }

    render(outputBusNumber, timestamp, frameCount, realtimeEventListHead);
    return noErr;
  }

protected:

  /**
   Obtain a `busBuffer` for the given bus.

   @param bus the bus to whose buffers will be pointed to
   @returns BusBuffers instance
   */
  BusBuffers busBuffers(size_t bus) noexcept { return facets_[bus].busBuffers(); }

private:

  BufferFacet& inputFacet() noexcept { assert(!facets_.empty()); return facets_.back(); }

  void render(NSInteger outputBusNumber, AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount,
              AURenderEvent const* events) noexcept {
    auto zero = AUEventSampleTime(0);
    auto now = AUEventSampleTime(timestamp->mSampleTime);
    auto framesRemaining = frameCount;

    while (framesRemaining > 0) {

      // Short-circuit if there are no more events to interleave
      if (events == nullptr) {
        renderFrames(outputBusNumber, framesRemaining, frameCount - framesRemaining);
        return;
      }

      // Render the frames for the times between now and the time of the first event.
      auto framesThisSegment = AUAudioFrameCount(std::max(events->head.eventSampleTime - now, zero));
      if (framesThisSegment > 0) {
        renderFrames(outputBusNumber, framesThisSegment, frameCount - framesRemaining);
        framesRemaining -= framesThisSegment;
        now += AUEventSampleTime(framesThisSegment);
      }

      // Process the events for the current time
      events = processEventsUntil(now, events);
    }
  }

  void unlinkBuffers() noexcept {
    for (auto& entry : facets_) {
      if (entry.isLinked()) entry.unlink();
    }
  }

  AURenderEvent const* processEventsUntil(AUEventSampleTime now, AURenderEvent const* event) noexcept {
    // See http://devnotes.kymatica.com/auv3_parameters.html for some nice details and advice about parameter event
    // processing.
    while (event != nullptr && event->head.eventSampleTime <= now) {
      switch (event->head.eventType) {
        case AURenderEventParameter:
        case AURenderEventParameterRamp:
          derived_.setParameterFromEvent(*reinterpret_cast<const AUParameterEvent*>(event));
          break;
        case AURenderEventMIDI: derived_.doMIDIEvent(event->MIDI); break;
        default: break;
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
    if (isBypassed()) {
      // If we have input samples from an upstream node, either use the sample buffers directly or copy samples over
      // to the output buffer. Otherwise, we have already zero'd out the output buffer, so we are done.
      if (input.isLinked()) {
        input.copyInto(facets_[outputBusIndex], processedFrameCount, frameCount);
      }
      return;
    }

    // Pass off to the kernel to render the desired number of samples.
    auto& output{facets_[outputBusIndex]};
    derived_.doRendering(outputBusNumber, input.busBuffers(), output.busBuffers(), frameCount);
  }

  ValueType& derived_;
  std::vector<SampleBuffer> buffers_;
  std::vector<BufferFacet> facets_;
  bool bypassed_ = false;
  bool rendering_ = false;
};

} // end namespace DSPHeaders
