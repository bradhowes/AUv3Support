// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

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
  
  /**
   Set the format of the buffer to use.
   
   @param format the format of the samples
   @param maxFrames the maximum number of frames to be found in the upstream output
   */
  void allocate(AVAudioFormat* format, AUAudioFrameCount maxFrames)
  {
    maxFramesToRender_ = maxFrames;
    buffer_ = [[AVAudioPCMBuffer alloc] initWithPCMFormat: format frameCapacity: maxFrames];
    mutableAudioBufferList_ = buffer_.mutableAudioBufferList;
    facet_.setChannelCount([format channelCount]);
    facet_.setBufferList(mutableAudioBufferList_);
  }
  
  /**
   Forget any allocated buffer.
   */
  void release()
  {
    buffer_ = nullptr;
    mutableAudioBufferList_ = nullptr;
    facet_.unlink();
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
    if (pullInputBlock == nullptr) return kAudioUnitErr_NoConnection;
    setFrameCount(frameCount);
    return pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, mutableAudioBufferList_);
  }

  /**
   Update the buffer to reflect that it will hold frameCount frames.
   
   @param frameCount the number of frames to expect to place in the buffer
   */
  void setFrameCount(AVAudioFrameCount frameCount)
  {
    assert(frameCount <= maxFramesToRender_);
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (UInt32 channel = 0; channel < mutableAudioBufferList_->mNumberBuffers; ++channel) {
      mutableAudioBufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /// Obtain the maximum size of the input buffer
  AUAudioFrameCount capacity() const { return maxFramesToRender_; }

  /// Obtain a mutable version of the internal AudioBufferList.
  AudioBufferList* mutableAudioBufferList() const { return mutableAudioBufferList_; }

  /// Obtain a C++ vector facet using the internal buffer.
  BufferFacet& bufferFacet() { return facet_; }

  /// Obtain the number of channels in the buffer
  size_t channelCount() const { return buffer_ != nullptr ? facet_.channelCount() : 0; }

private:
  AUAudioFrameCount maxFramesToRender_;
  AVAudioPCMBuffer* buffer_{nullptr};
  AudioBufferList* mutableAudioBufferList_{nullptr};
  BufferFacet facet_{};
};

} // end namespace DSPHeaders
