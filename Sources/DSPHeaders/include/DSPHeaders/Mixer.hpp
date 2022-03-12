// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <cassert>
#include <cmath>
#include <vector>

#include "DSPHeaders/BufferPair.hpp"

namespace DSPHeaders {

class Mixer
{
public:

  /**
   Construct new mixer that consists of three output busses.

   @param dry the dry (original) output samples
   @param chorusSend the samples that will go to the first effects channel
   @param reverbSend the samples that will go to the second effects channel
   */
  Mixer(BufferPair dry, BufferPair effects1, BufferPair effects2) :
  dry_{dry}, effects1_{effects1}, effects2_{effects2}
  {
    ;
  }

  /**
   Add a sample to the output buffers.

   @param frame the frame to hold the samples
   @param left the sample for the left channel
   @param right the sample for the right channel
   @param effect1 the amount of the L+R samples to send to the first effects bus
   @param effect2 the amount of the L+R samples to send to the second effects bus
   */
  void add(AUAudioFrameCount frame, AUValue left, AUValue right, AUValue effects1, AUValue effects2) noexcept
  {
    dry_.add(frame, left, right);
    if (effects1_.isValid() && effects1 > 0.0) effects1_.add(frame, left * effects1, right * effects1);
    if (effects2_.isValid() && effects2 > 0.0) effects2_.add(frame, left * effects2, right * effects2);
  }

  /**
   Command the individual BufferPair instances to shift forward by `frames` frames.

   @param frames the number of frames to shift over
   */
  void shiftOver(AUAudioFrameCount frames)
  {
    dry_.shiftOver(frames);
    effects1_.shiftOver(frames);
    effects2_.shiftOver(frames);
  }

private:
  BufferPair dry_;
  BufferPair effects1_;
  BufferPair effects2_;
};

} // end namespace
