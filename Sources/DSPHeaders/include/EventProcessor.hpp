// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <vector>
#import <AudioToolbox/AudioToolbox.h>

#import "InputBuffer.hpp"

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
  EventProcessor(os_log_t log) : derived_{static_cast<T&>(*this)}, log_{log} {}

  /**
   Set the bypass mode.

   @param bypass if true disable filter processing and just copy samples from input to output
   */
  void setBypass(bool bypass) { bypassed_ = bypass; }

  /**
   Get current bypass mode
   */
  bool isBypassed() { return bypassed_; }

  /**
   Begin processing with the given format and channel count.

   @param format the sample format to expect
   @param maxFramesToRender the maximum number of frames to expect on input
   */
  void startProcessing(AVAudioFormat* format, AUAudioFrameCount maxFramesToRender) {
    inputBuffer_.allocateBuffers(format, maxFramesToRender);
  }

  /**
   Stop processing. Free up any resources that were used during rendering.
   */
  void stopProcessing() { inputBuffer_.releaseBuffers(); }

  /**
   Process events and render a given number of frames. Events and rendering are interleaved if necessary so that
   event times align with samples.

   @param timestamp the timestamp of the first sample or the first event
   @param frameCount the number of frames to process
   @param inputBusNumber the bus to pull samples from
   @param output the buffer to hold the rendered samples
   @param realtimeEventListHead pointer to the first AURenderEvent (may be null)
   @param pullInputBlock the closure to call to obtain upstream samples
   */
  AUAudioUnitStatus processAndRender(const AudioTimeStamp* timestamp, UInt32 frameCount, NSInteger inputBusNumber,
                                     AudioBufferList* output, const AURenderEvent* realtimeEventListHead,
                                     AURenderPullInputBlock pullInputBlock)
  {
    AudioUnitRenderActionFlags actionFlags = 0;
    auto status = inputBuffer_.pullInput(&actionFlags, timestamp, frameCount, inputBusNumber, pullInputBlock);
    if (status != noErr) {
      os_log_with_type(log_, OS_LOG_TYPE_ERROR, "failed pullInput - %d", status);
      return status;
    }

    setOutputBuffer(output, frameCount);
    render(timestamp, frameCount, realtimeEventListHead);
    clearBuffers();

    return noErr;
  }

protected:
  os_log_t log_;

private:

  void render(AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount, AURenderEvent const* events)
  {
    auto zero = AUEventSampleTime(0);
    auto now = AUEventSampleTime(timestamp->mSampleTime);
    auto framesRemaining = frameCount;

    while (framesRemaining > 0) {

      // Short-circuit if there are no more events to interleave
      if (events == nullptr) {
        renderFrames(framesRemaining, frameCount - framesRemaining);
        return;
      }

      // Render the frames for the times between now and the time of the first event.
      auto framesThisSegment = AUAudioFrameCount(std::max(events->head.eventSampleTime - now, zero));
      if (framesThisSegment > 0) {
        renderFrames(framesThisSegment, frameCount - framesRemaining);
        framesRemaining -= framesThisSegment;
        now += AUEventSampleTime(framesThisSegment);
      }

      // Process the events for the current time
      events = processEventsUntil(now, events);
    }
  }

  void setOutputBuffer(AudioBufferList* outputs, AUAudioFrameCount frameCount)
  {
    outputs_.setBufferList(outputs, inputBuffer_.mutableAudioBufferList());
    outputs_.setFrameCount(frameCount);
  }

  void clearBuffers()
  {
    outputs_.release();
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

  void renderFrames(AUAudioFrameCount frameCount, AUAudioFrameCount processedFrameCount)
  {
    auto& inputs{inputBuffer_.bufferFacet()};

    if (isBypassed()) {
      inputs.copyInto(outputs_, processedFrameCount, frameCount);
      return;
    }

    inputs.setOffset(processedFrameCount);
    outputs_.setOffset(processedFrameCount);
    derived_.doRendering(inputs.pointers(), outputs_.pointers(), frameCount);
  }

  T& derived_;
  InputBuffer inputBuffer_;
  BufferFacet outputs_;

  bool bypassed_ = false;
};
