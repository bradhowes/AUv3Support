// Copyright © 2021-2025 Brad Howes. All rights reserved.

#pragma once

#import <string>

#import <os/log.h>
#import <AudioToolbox/AUAudioUnit.h>
#import <algorithm>
#import <span>
#import <vector>

#import "DSPHeaders/BusBuffers.hpp"

namespace DSPHeaders {

/**
 Provides a simple view of an N-channel `AudioBufferList` as a vector of `AUValue` pointers. This is much easier to work
 with in a kernel than an `AudioBufferList` instance. In `EventProcessor`, the `AudioBufferList` value comes from a
 `BusSampleBuffer` instance, but this is not required here.

 Supports in-place rendering where the input buffer is used for rendering and is overwritten with output samples.
 */
struct BusBufferFacet {

  /**
   Construct a new instance.
   */
  BusBufferFacet() noexcept {}

  /**
   Set the expected number of channels to support during rendering. The goal is to not encounter any memory
   allocations while rendering, so this *must* be called before rendering is started.

   @param channelCount the number of channels to expect
   */
  void setChannelCount(AUAudioChannelCount channelCount) noexcept {
    pointers_.reserve(channelCount);
    pointers_.resize(channelCount);
  }

  /**
   Set the underlying buffers to use to hold and report out data. This is to be run within a render thread and will not
   allocate any memory. There are two options:

   - bufferList has non-nullptr mData values -- use it as-is
   - bufferList has nullptr mData values && inPlaceSource != nullptr -- use the inPlaceSource mData elements

   Note that this method will throw an exception if the channel count of either `bufferList` does not match the expected
   channel count.

   @param bufferList the collection of buffers to use
   @param inPlaceSource if not nullptr, use their mData elements for storage
   */
  void assignBufferList(AudioBufferList* bufferList, AudioBufferList* inPlaceSource = nullptr) {
    bufferList_ = bufferList;
    if (bufferList->mBuffers[0].mData == nullptr) {

      // The given bufferList does not have space to use -- attempt to perform in-place rendering.
      if (inPlaceSource == nullptr) {
        throw std::runtime_error("inPlaceSource == nullptr");
      }
      for (UInt32 channel = 0; channel < bufferList->mNumberBuffers; ++channel) {
        bufferList->mBuffers[channel].mData = inPlaceSource->mBuffers[channel].mData;
      }
    }

    size_t numBuffers = bufferList_->mNumberBuffers;
    if (numBuffers != pointers_.size()) {
      throw std::runtime_error("numBuffers != pointers_.size()");
    }

    setOffset(0);
  }

  /**
   Set the facet to start at the given offset into the source buffers. Once done, the std::vector AUValue
   pointers will start `offset` samples into the underlying buffer.

   @param offset number of samples to offset.
   */
  void setOffset(AUAudioFrameCount offset) {
    validateBufferList();
    for (size_t channel = 0; channel < pointers_.size(); ++channel) {
      pointers_[channel] = getBufferPointer(channel, offset);
    }
  }

  /**
   Set the number of frames (samples) that are in each buffer. This must be done before the underlying buffers are
   returned to Apple's audio engine that is driving the rendering.

   @param frameCount number of samples in a buffer.
   */
  void setFrameCount(AUAudioFrameCount frameCount) {
    validateBufferList();
    UInt32 byteSize = frameCount * sizeof(AUValue);
    for (UInt32 channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      bufferList_->mBuffers[channel].mDataByteSize = byteSize;
    }
  }

  /// @returns true if the facet is linked to a buffer
  bool isLinked() const noexcept { return bufferList_ != nullptr; }

  /**
   Release the underlying buffers.
   */
  void unlink() {
    validateBufferList();
    bufferList_ = nullptr;
    for (size_t channel = 0; channel < pointers_.size(); ++channel) {
      pointers_[channel] = nullptr;
    }
  }

  /**
   Obtain samples from an upstream node. Output is stored in the AudioBufferList that was installed by `setBufferList`.

   @param actionFlags render flags from the host
   @param timestamp the current transport time of the samples
   @param frameCount the number of frames to process
   @param inputBusNumber the bus to pull from
   @param pullInputBlock the function to call to do the pulling
   */
  AUAudioUnitStatus pullInput(AudioUnitRenderActionFlags* actionFlags, AudioTimeStamp const* timestamp,
                              AUAudioFrameCount frameCount, NSInteger inputBusNumber,
                              AURenderPullInputBlock pullInputBlock) noexcept {
    if (pullInputBlock == nullptr) [[unlikely]] {
      return kAudioUnitErr_NoConnection;
    }

    validateBufferList();
    if (frameCount * sizeof(AUValue) > bufferList_->mBuffers[0].mDataByteSize) [[unlikely]] {
      return kAudioUnitErr_TooManyFramesToProcess;
    }

    setFrameCount(frameCount);
    return pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, bufferList_);
  }

  /**
   Copy contents of the buffers into the given destination, starting at the offset and copying frameCount bytes.
   Currently this is only used when an audio unit is in bypass mode.

   @param destination the buffer to copy into
   @param offset the offset to apply before writing
   @param frameCount the number of samples to write
   */
  void copyInto(BusBufferFacet& destination, AUAudioFrameCount offset, AUAudioFrameCount frameCount) const {
    validateBufferList();
    auto outputs = destination.bufferList_;
    for (UInt32 channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      if (bufferList_->mBuffers[channel].mData == outputs->mBuffers[channel].mData) {
        // nothing to do since input buffer is being used for output buffer (in-place rendering).
        continue;
      }
      auto in = getBufferPointer(channel, offset);
      auto out = destination.getBufferPointer(channel, offset);
      std::copy_n(in, frameCount, out);
    }
  }

  /**
   Set the sample values to zero for the next N frames. This is used when there is no upstream node to pull from.

   @param frameCount the number of frames to clear
   */
  void clear(AUAudioFrameCount frameCount) noexcept {
    for (UInt32 channel = 0; channel < bufferList_->mNumberBuffers; ++channel) {
      auto pos = getBufferPointer(channel, 0);
      std::fill(pos, pos + frameCount, AUValue(0.0));
    }
  }

  /// @returns the number of channels that are currently supported
  size_t channelCount() const noexcept { return pointers_.size(); }

  /// @returns new BusBuffers instance that refers to our collection of AUValue pointers for storing render samples.
  BusBuffers busBuffers() noexcept {
    return BusBuffers(pointers_);
  }

private:

  AUValue* getBufferPointer(size_t channel, AUAudioFrameCount offset) const noexcept {
    return static_cast<AUValue*>(bufferList_->mBuffers[channel].mData) + offset;
  }

  void validateBufferList() const {
    if (bufferList_ == nullptr) [[unlikely]] {
      throw std::runtime_error("bufferList_ == nullptr");
    }
  }

  AudioBufferList* bufferList_{nullptr};
  std::vector<AUValue*> pointers_{};
};

} // end namespace DSPHeaders
