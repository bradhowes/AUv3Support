// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <cmath>
#include <vector>

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

namespace DSPHeaders {

/**
 Grouping of audio buffers that are always worked on together as a bus.
 */
class BusBuffers
{
public:

  explicit BusBuffers(const std::vector<AUValue*>& buffers) : buffers_{buffers} {}

  bool isValid() const noexcept { return !buffers_.empty(); }
  bool isMono() const noexcept { return buffers_.size() == 1; }
  bool isStereo() const noexcept { return buffers_.size() > 1; }

  void addMono(AUAudioFrameCount frame, AUValue monoSample) noexcept
  {
    assert(isMono());
    buffers_[0][frame] += monoSample;
  }

  void addStereo(AUAudioFrameCount frame, AUValue leftSample, AUValue rightSample) noexcept
  {
    assert(isStereo());
    buffers_[0][frame] += leftSample;
    buffers_[1][frame] += rightSample;
  }

  void addAll(AUAudioFrameCount frame, AUValue sample) noexcept
  {
    for (auto& buffer : buffers_) {
      buffer[frame] += sample;
    }
  }

  void addAlternating(AUAudioFrameCount frame, AUValue evenSample, AUValue oddSample) noexcept
  {
    size_t size{buffers_.size()};
    for (size_t index = 0; index < size; ++index) {
      buffers_[index][frame] = (index % 2) ? oddSample : evenSample;
    }
  }

  /**
   Adjust the buffer pointers so that they start `frames` later. Currently, this is only uses in unit tests. There is
   not a need for this type of activity in normal AUv3 sample rendering since BufferPair instances always start at the
   right location.
   */
  void shiftOver(AUAudioFrameCount frames)
  {
    for (auto& buffer : buffers_ ) {
      buffer += frames;
    }
  }

private:
  std::vector<AUValue*> buffers_;
};

} // end namespace
