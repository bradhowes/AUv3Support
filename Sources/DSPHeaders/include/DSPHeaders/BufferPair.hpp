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
 Pairing of L+R audio buffers that are always worked on together.
 */
class BufferPair
{
public:

  BufferPair(AUValue* left, AUValue* right) noexcept : left_(left), right_(right) {}

  bool isValid() const noexcept { return left_ != nullptr && right_ != nullptr; }

  void add(AUAudioFrameCount frame, AUValue leftSample, AUValue rightSample) noexcept
  {
    left_[frame] += leftSample;
    right_[frame] += rightSample;
  }

  /**
   Adjust the buffer pointers so that they start `frames` later. Currently, this is only uses in unit tests. There is
   not a need for this type of activity in normal AUv3 sample rendering since BufferPair instances always start at the
   right location.
   */
  void shiftOver(AUAudioFrameCount frames)
  {
    left_ += frames;
    right_ += frames;
  }

private:
  AUValue* left_;
  AUValue* right_;
};

} // end namespace
