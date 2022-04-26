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
 `AVAudioPCMBuffer` to deal with specifics involving the audio format.
 */
struct SampleBuffer {

  SampleBuffer() noexcept {}

  /**
   Set the format of the buffer to use.
   
   @param format the format of the samples
   @param maxFrames the maximum number of frames to be found in the upstream output
   */
  void allocate(AVAudioFormat* format, AUAudioFrameCount maxFrames) noexcept
  {
    maxFramesToRender_ = maxFrames;
    buffer_ = [[AVAudioPCMBuffer alloc] initWithPCMFormat: format frameCapacity: maxFrames];
    mutableAudioBufferList_ = buffer_.mutableAudioBufferList;
  }
  
  /**
   Forget any allocated buffer.
   */
  void release()
  {
    if (buffer_ == nullptr) {
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
                              AURenderPullInputBlock pullInputBlock) noexcept
  {
    if (pullInputBlock == nullptr) {
      return kAudioUnitErr_NoConnection;
    }

    if (frameCount > maxFramesToRender_) {
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    setFrameCount(frameCount);
    auto status = pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, mutableAudioBufferList_);
    return status;
  }

  /**
   Update the buffer to reflect that has or will hold frameCount frames. NOTE: this value must be <= max value given in
   the `allocate` method.
   
   @param frameCount the number of frames to expect to place in the buffer
   */
  void setFrameCount(AVAudioFrameCount frameCount) noexcept
  {
    assert(frameCount <= maxFramesToRender_ && mutableAudioBufferList_ != nullptr);
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (UInt32 channel = 0; channel < mutableAudioBufferList_->mNumberBuffers; ++channel) {
      mutableAudioBufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /// Obtain the maximum size of the input buffer
  AUAudioFrameCount capacity() const noexcept { return maxFramesToRender_; }

  /// Obtain a mutable version of the internal AudioBufferList.
  AudioBufferList* mutableAudioBufferList() const noexcept { return mutableAudioBufferList_; }

  /// Obtain the number of channels in the buffer
  size_t channelCount() const noexcept {
    return mutableAudioBufferList_ != nullptr ? mutableAudioBufferList_->mNumberBuffers : 0;
  }

private:
  AUAudioFrameCount maxFramesToRender_;
  AVAudioPCMBuffer* buffer_{nullptr};
  AudioBufferList* mutableAudioBufferList_{nullptr};
};

} // end namespace DSPHeaders
