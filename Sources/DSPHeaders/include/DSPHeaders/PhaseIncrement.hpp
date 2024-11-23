// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <cassert>
#import <cmath>

#import "DSP.hpp"
#import "DSPHeaders/Parameters/Float.hpp"

namespace DSPHeaders {

/**
 Source of an LFO phase increment.
 */
template <typename ValueType = AUValue>
class PhaseIncrement {
public:

  /**
   Create a new instance. For each frame of the render, the LFO changes by frequency / sampleRate which is
   usually fixed, but when the frequency parameter changes, it will be ramped so that it changes over N
   frames. We support that by performing a slightly more expensive 'live' calculation while ramping is ini
   effect.

   @param frequency the parameter that holds the frequency of the LFO. For each frame of a render, the LFO
   changes
   */
  PhaseIncrement(Parameters::Float& frequency, ValueType sampleRate) noexcept
  : inverseSampleRate_{ValueType(1.0) / sampleRate}, frequency_ {frequency} {}

  /**
   Update to a new sample rate.

   @param sampleRate the new value to use
   */
  void setSampleRate(ValueType sampleRate) noexcept { inverseSampleRate_ = ValueType(1.0) /  sampleRate; }

  /**
   Obtain the current phase increment value
   */
  ValueType value() noexcept {
    auto frameValue = frequency_.frameValue();
    return frameValue == lastFrameValue_ ? fixedIncrement_ : liveValue(frameValue);
  }

private:

  ValueType liveValue(AUValue frameValue) noexcept {
    auto increment = frameValue * inverseSampleRate_;
    lastFrameValue_ = frameValue;
    fixedIncrement_ = increment;
    return increment;
  }

  ValueType inverseSampleRate_;
  Parameters::Float& frequency_;
  ValueType lastFrameValue_{};
  ValueType fixedIncrement_{};
};

} // end namespace DSPHeaders
