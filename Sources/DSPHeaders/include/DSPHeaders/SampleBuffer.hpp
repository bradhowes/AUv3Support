// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <string>

#import <os/log.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BufferFacet.hpp"

namespace DSPHeaders {

/**
 Maintains a buffer of PCM samples which can be used to save samples from an upstream node. Internally uses an
 `AVAudioPCMBuffer` to deal with the audio format of the upstream node. It also uses `BufferFacet` to present the
 buffers as a collection of AUValue pointers (std::vector<AUValue*>) to make it easier for working with the buffers
 and index accounting.
 */
struct SampleBuffer {

  SampleBuffer(std::string loggingSubsystem) : log_{os_log_create(loggingSubsystem.c_str(), "SampleBuffer")}
  {}

  /**
   Set the format of the buffer to use.
   
   @param format the format of the samples
   @param maxFrames the maximum number of frames to be found in the upstream output
   */
  void allocate(AVAudioFormat* format, AUAudioFrameCount maxFrames)
  {
    os_log_info(log_, "allocate - maxFrames: %d", maxFrames);
    maxFramesToRender_ = maxFrames;
    buffer_ = [[AVAudioPCMBuffer alloc] initWithPCMFormat: format frameCapacity: maxFrames];
    mutableAudioBufferList_ = buffer_.mutableAudioBufferList;
  }
  
  /**
   Forget any allocated buffer.
   */
  void release()
  {
    os_log_info(log_, "release - %p", buffer_);

    if (buffer_ == nullptr) {
      os_log_error(log_, "buffer_ == nullptr");
      throw std::runtime_error("buffer_ == nullptr");
    }

    buffer_ = nullptr;
    mutableAudioBufferList_ = nullptr;
  }
  
  /**
   Obtain samples from an upstream node. Output is stored in internal buffer.
   
   @param actionFlags render flags from the host
   @param timestamp the current transport time of the samples
   @param frameCount the number of frames to process
   @param inputBusNumber the bus to pull from
   @param pullInputBlock the function to call to do the pulling
   */
  AUAudioUnitStatus pullInput(AudioUnitRenderActionFlags* actionFlags, AudioTimeStamp const* timestamp,
                              AVAudioFrameCount frameCount, NSInteger inputBusNumber,
                              AURenderPullInputBlock pullInputBlock)
  {
    os_log_debug(log_, "pullInput - %llu", timestamp->mHostTime);
    if (pullInputBlock == nullptr) {
      os_log_error(log_, "pullInputBlock == nullptr");
      return kAudioUnitErr_NoConnection;
    }

    setFrameCount(frameCount);
    auto status = pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, mutableAudioBufferList_);
    os_log_debug(log_, "pullInput done - %d", status);
    return status;
  }

  /**
   Update the buffer to reflect that it will hold frameCount frames.
   
   @param frameCount the number of frames to expect to place in the buffer
   */
  void setFrameCount(AVAudioFrameCount frameCount)
  {
    os_log_debug(log_, "setFrameCount - %d", frameCount);
    if (frameCount > maxFramesToRender_) {
      os_log_error(log_, "frameCount > maxFramesToRender");
      throw std::runtime_error("frameCount > maxFramesToRender");
    }

    if (mutableAudioBufferList_ == nullptr) {
      os_log_error(log_, "mutableAudioBufferList_ == nullptr");
      throw std::runtime_error("mutableAudioBufferList_ == nullptr");
    }

    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (UInt32 channel = 0; channel < mutableAudioBufferList_->mNumberBuffers; ++channel) {
      mutableAudioBufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /// Obtain the maximum size of the input buffer
  AUAudioFrameCount capacity() const { return maxFramesToRender_; }

  /// Obtain a mutable version of the internal AudioBufferList.
  AudioBufferList* mutableAudioBufferList() const { return mutableAudioBufferList_; }

  /// Obtain the number of channels in the buffer
  size_t channelCount() const {
    return mutableAudioBufferList_ != nullptr ? mutableAudioBufferList_->mNumberBuffers : 0;
  }

private:
  os_log_t log_;
  AUAudioFrameCount maxFramesToRender_;
  AVAudioPCMBuffer* buffer_{nullptr};
  AudioBufferList* mutableAudioBufferList_{nullptr};
};

} // end namespace DSPHeaders
