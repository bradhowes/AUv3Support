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

 */
template <typename T> class EventProcessor {
public:

  /**
   Construct new instance.

   @param log the log identifier to use for our logging statements
   */
  EventProcessor(std::string subsystem) :
  derived_{static_cast<T&>(*this)}, loggingSubsystem_{subsystem}, log_{os_log_create(subsystem.c_str(), "Kernel")},
  buffers_{}, facets_{}
  {}

  /**
   Set the bypass mode.

   @param bypass if true disable filter processing and just copy samples from input to output
   */
  void setBypass(bool bypass) {
    os_log_info(log_, "setBypass: %d", bypass);
    bypassed_ = bypass;
  }

  /**
   Get current bypass mode
   */
  bool isBypassed() { return bypassed_; }

  /**
   Update kernel and buffers to support the given format.

   @param format the sample format to expect
   @param maxFramesToRender the maximum number of frames to expect on input
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) {
    os_log_info(log_, "setRenderingFormat - busCount: %ld", (long)busCount);

    while (buffers_.size() < size_t(busCount)) {
      buffers_.emplace_back(loggingSubsystem_);
      facets_.emplace_back(loggingSubsystem_);
    }

    // Setup sample buffers to have the right format and capacity
    for (auto& entry : buffers_) {
      entry.allocate(format, maxFramesToRender);
    }

    // Setup facets to have the right channel count so we do not allocate while rendering
    for (auto& entry : facets_) {
      entry.setChannelCount([format channelCount]);
    }
  }

  /**
   Rendering has stopped. Free up any resources it used.
   */
  void renderingStopped() {
    os_log_info(log_, "renderingStopped");
    unlinkBuffers();
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
                                     AURenderPullInputBlock pullInputBlock)
  {
    os_log_info(log_, "processAndRender - frameCount: %d bus: %ld size: %lu", frameCount, (long)outputBusNumber,
                buffers_.size());
    assert(outputBusNumber < buffers_.size());

    auto& buffer{buffers_[outputBusNumber]};
    if (frameCount > buffer.capacity()) {
      os_log_error(log_, "processAndRender - too many frames - frameCount: %d capacity: %d", frameCount,
                   buffer.capacity());
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    // This only applies for effects -- instruments do not have anything to pull.
    if (pullInputBlock) {
      os_log_info(log_, "processAndRender - pulling input");
      AudioUnitRenderActionFlags actionFlags = 0;
      auto status = buffer.pullInput(&actionFlags, timestamp, frameCount, outputBusNumber, pullInputBlock);
      if (status != noErr) {
        os_log_error(log_, "processAndRender - pullInput failed - %d", status);
        return status;
      }
    }

    // Setup the output buffers to accept samples. For in-place rendering, the `output` buffer list will have null
    // buffer points, so this will have it point to the internal buffer.
    setOutputBuffer(outputBusNumber, output, frameCount);

    // Generate samples into the output buffer.
    render(outputBusNumber, timestamp, frameCount, realtimeEventListHead);

    unlinkBuffers();

    return noErr;
  }

protected:
  os_log_t log_;


  /**
   Obtain a `busBuffer` for the given bus. Setup the buffers so that they indicate that they hold `frameCount` samples.

   @param bus the bus to whose buffers will be pointed to
   @param frameCount the number of frames that will be found in the buffers
   @returns BusBuffers instance
   */
  BusBuffers busBuffers(size_t bus, AUAudioFrameCount frameCount)
  {
    facets_[bus].setBufferList(buffers_[bus].mutableAudioBufferList());
    facets_[bus].setFrameCount(frameCount);
    return facets_[bus].busBuffers();
  }

private:

  void render(NSInteger outputBusNumber, AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount,
              AURenderEvent const* events)
  {
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

  void setOutputBuffer(NSInteger outputBusNumber, AudioBufferList* outputs, AUAudioFrameCount frameCount)
  {
    facets_[outputBusNumber].setBufferList(outputs, buffers_[outputBusNumber].mutableAudioBufferList());
    facets_[outputBusNumber].setFrameCount(frameCount);
  }

  void unlinkBuffers()
  {
    for (auto& entry : facets_) {
      entry.unlink();
    }
  }

  AURenderEvent const* processEventsUntil(AUEventSampleTime now, AURenderEvent const* event)
  {
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

  void renderFrames(NSInteger outputBusNumber, AUAudioFrameCount frameCount, AUAudioFrameCount processedFrameCount)
  {
    auto& inputs{buffers_[outputBusNumber].bufferFacet()};
    if (isBypassed()) {
      inputs.copyInto(facets_[outputBusNumber], processedFrameCount, frameCount);
      return;
    }

    auto& outputs{facets_[outputBusNumber]};
    inputs.setOffset(processedFrameCount);
    outputs.setOffset(processedFrameCount);

    derived_.doRendering(outputBusNumber, inputs.busBuffers(), outputs.busBuffers(), frameCount);
  }

  T& derived_;
  std::string loggingSubsystem_;
  std::vector<SampleBuffer> buffers_;
  std::vector<BufferFacet> facets_;
  bool bypassed_ = false;
};

} // end namespace DSPHeaders
