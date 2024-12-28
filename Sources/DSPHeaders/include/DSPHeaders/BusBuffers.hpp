// Copyright © 2022-2024 Brad Howes. All rights reserved.

#pragma once

#import <cassert>
#import <cmath>
#import <span>
#import <vector>

#import <AudioToolbox/AudioToolbox.h>

namespace DSPHeaders {

/**
 Grouping of audio buffers that are always worked on together as a bus. Most of the time, a bus will have 1 (mono) or
 two (stereo) channels of audio. There are methods specific to mono and stereo as well as general-purpose methods for
 treating them all the same or as alternating variations like stereo but as even (0/L) and odd (1/R) pairs.

 Note that this class only holds a refernce to the collection that is used. The collection must not go out of scope
 while an instance of this class exists. In `EventProcessor` it is only used to pass the sample pointers to the
 kernel for rendering.
 */
class BusBuffers {
public:

  /**
   Construct a new instance using the given collection of AUValue pointers.

   @param buffers the AUValue pointers to use
   */
  explicit BusBuffers(std::vector<AUValue*>& buffers) noexcept : buffers_{buffers} {}

  BusBuffers() = delete;

  BusBuffers(const BusBuffers& other) = default;

  BusBuffers(BusBuffers&& other) = default;

  BusBuffers& operator =(BusBuffers&&) = delete;

  BusBuffers& operator =(const BusBuffers&) = delete;

  /// @returns true if the buffer collection is usable
  bool isValid() const noexcept { return !buffers_.empty(); }

  /// @returns true if the buffer collection is mono (1 channel)
  bool isMono() const noexcept { return buffers_.size() == 1; }

  /// @returns true if the buffer collection is stereo (2 channel)
  bool isStereo() const noexcept { return buffers_.size() > 1; }

  /**
   Add a sample to the existing frame of a mono collection.

   @param frame the frame to update
   @param monoSample the sample to update with
   */
  void addMono(AUAudioFrameCount frame, AUValue monoSample) noexcept {
    assert(isMono());
    buffers_[0][frame] += monoSample;
  }

  /**
   Add a sample to the existing frame of a stereo collection.

   @param frame the frame to update
   @param leftSample the sample to update the left channel with
   @param rightSample the sample to update the right channel with
   */
  void addStereo(AUAudioFrameCount frame, AUValue leftSample, AUValue rightSample) noexcept {
    assert(isStereo());
    buffers_[0][frame] += leftSample;
    buffers_[1][frame] += rightSample;
  }

  /**
   Add a sample to the existing frame of all buffers in the collection.

   @param frame the frame to update
   @param sample the value to update with
   */
  void addAll(AUAudioFrameCount frame, AUValue sample) noexcept {
    for (auto& buffer : buffers_) {
      buffer[frame] += sample;
    }
  }

  /**
   Add a sample to the existing frame of all buffers in the collection, using one sample for "even" channels and another
   for "odd" channels.

   @param frame the frame to update
   @param evenSample the sample to update even (0 (L), 2, 4...) channels with
   @param oddSample the sample to update odd (1 (R), 3, 5....) channels with
   */
  void addAlternating(AUAudioFrameCount frame, AUValue evenSample, AUValue oddSample) noexcept {
    size_t size{buffers_.size()};
    for (size_t index = 0; index < size; ++index) {
      buffers_[index][frame] += (index % 2) ? oddSample : evenSample;
    }
  }

  /**
   Obtain the sample pointer for the given channel index.

   @param index the index of the channel to get
   @returns the sample pointer at the given channel index
   */
  AUValue* operator[](size_t index) const noexcept { return buffers_[index]; }

  /**
   Obtain the modifiable sample pointer for the given channel index.

   @param index the index of the channel to get
   @returns reference to the sample pointer at the given channel index
   */
  AUValue*& operator[](size_t index) noexcept { return buffers_[index]; }

  /**
   Adjust the buffer pointers so that they start `frames` later. Currently, this is only used in unit tests. There is
   not a need for this type of activity in normal AUv3 sample rendering since BufferPair instances always start at the
   right location.

   @param frames the amount to shift
   */
  void shiftOver(AUAudioFrameCount frames) noexcept {
    for (auto& buffer : buffers_ ) {
      buffer += frames;
    }
  }

  /// @returns number of channel buffers
  size_t size() const noexcept { return buffers_.size(); }

  /// @returns pointer to first AUValue pointer (first channel in bundle)
  AUValue* const* data() const noexcept { return buffers_.data(); }

  /// @returns pointer to first AUValue pointer (first channel in bundle)
  AUValue** data() noexcept { return buffers_.data(); }

private:
  std::vector<AUValue*>& buffers_;
};

} // end namespace
