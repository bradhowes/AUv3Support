// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import <vector>

#import "DSPHeaders/BusBuffers.hpp"

namespace DSPHeaders {

/**
 Provides a simple std::vector view of an N-channel AudioBufferList.
 */
struct BufferFacet {

  BufferFacet() = default;

  /**
   Set the expected number of channels to support during rendering. The goal is to not encountered any memory
   allocations while rendering.

   @param channelCount the number of channels to expect
   */
  void setChannelCount(AUAudioChannelCount channelCount) noexcept
  {
    pointers_.reserve(channelCount);
    pointers_.resize(channelCount);
  }

  /**
   Set the underlying buffers to use to hold and report out data. There are two options:

   - bufferList has non-nullptr mData values -- use it as the source
   - bufferList has nullptr mData values && inPlaceSource != nullptr -- use the inPlaceSource mData elements

   Note that this method will throw an exception if the channel count of either `bufferList` does not match the expected
   channel count.

   @param bufferList the collection of buffers to use
   @param inPlaceSource if not nullptr, use their mData elements for storage
   */
  void setBufferList(AudioBufferList* bufferList, AudioBufferList* inPlaceSource = nullptr) {
    bufferList_ = bufferList;
    if (bufferList->mBuffers[0].mData == nullptr) {
      assert(inPlaceSource != nullptr);
      for (UInt32 channel = 0; channel < bufferList->mNumberBuffers; ++channel) {
        bufferList->mBuffers[channel].mData = inPlaceSource->mBuffers[channel].mData;
      }
    }

    size_t numBuffers = bufferList_->mNumberBuffers;
    if (numBuffers != pointers_.size()) throw std::runtime_error("mismatch channel size");
    for (UInt32 channel = 0; channel < numBuffers; ++channel) {
      pointers_[channel] = static_cast<AUValue*>(bufferList_->mBuffers[channel].mData);
    }
  }

  /**
   Set the number of frames (samples) that are in each buffer. This must be done before the underlying buffers are
   returned to Apple's audio engine that is driving the rendering.

   @param frameCount number of samples in a buffer.
   */
  void setFrameCount(AUAudioFrameCount frameCount) {
    assert(bufferList_ != nullptr);
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (UInt32 channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      bufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /**
   Set the facet to start at the given offset into the source buffers. Once done, the std::vector and AUValue
   pointers will start `offset` samples into the underlying buffer.

   @param offset number of samples to offset.
   */
  void setOffset(AUAudioFrameCount offset) {
    for (size_t channel = 0; channel < pointers_.size(); ++channel) {
      pointers_[channel] = static_cast<AUValue*>(bufferList_->mBuffers[channel].mData) + offset;
    }
  }

  /**
   Release the underlying buffers.
   */
  void unlink() {
    bufferList_ = nullptr;
    for (size_t channel = 0; channel < pointers_.size(); ++channel) {
      pointers_[channel] = nullptr;
    }
  }

  /**
   Copy contents of the buffers into the given destination, starting at the offset and copying frameCount bytes.
   Currently this is only used when an audio unit is in bypass mode.

   @param destination the buffer to copy into
   @param offset the offset to apply before writing
   @param frameCount the number of samples to write
   */
  void copyInto(BufferFacet& destination, AUAudioFrameCount offset, AUAudioFrameCount frameCount) const {
    auto outputs = destination.bufferList_;
    for (UInt32 channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      if (bufferList_->mBuffers[channel].mData == outputs->mBuffers[channel].mData) {
        // nothing to do since input buffer is being used for output buffer (in-place rendering).
        continue;
      }

      auto in = static_cast<AUValue*>(bufferList_->mBuffers[channel].mData) + offset;
      auto out = static_cast<AUValue*>(outputs->mBuffers[channel].mData) + offset;
      memcpy(out, in, frameCount * sizeof(AUValue));
    }
  }

  /// @returns the number of channels that are currently supported
  size_t channelCount() const { return pointers_.size(); }

  /// @returns a BusBuffer instance for the sample pointers.
  BusBuffers busBuffers() { return BusBuffers(pointers_); }

private:
  AudioBufferList* bufferList_{nullptr};
  std::vector<AUValue*> pointers_{};
};

} // end namespace DSPHeaders