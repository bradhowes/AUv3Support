// Copyright © 2021-2025 Brad Howes. All rights reserved.

#pragma once

#import <cassert>
#import <cmath>

#import "DSP.hpp"
#import "DSPHeaders/Parameters/Float.hpp"

namespace DSPHeaders {

/**
 Source of an LFO phase increment, the amount of change to apply to the LFO at each render
 frame. If an LFO is running at 10 Hz and the sample rate is 44,100 then the phase increment
 would be 10 / 44,100 -- after 1 second of audio rendered, the LFO would have cycled 10 times.

 The phase increment is controlled via a runtime parameter that holds the frequency of the LFO.
 */
template <typename ValueType = AUValue>
class PhaseIncrement {
public:

  /**
   Create a new instance. For each frame of the render, the LFO changes by frequency / sampleRate which is
   usually fixed, but when the frequency parameter changes, it will be ramped so that it changes over N
   frames. We support that by performing a slightly more expensive 'live' calculation while ramping is in
   effect.

   @param frequency the parameter that holds the frequency of the LFO. For each frame of a render, the LFO
   changes
   */
  PhaseIncrement(Parameters::Float& frequency, ValueType sampleRate) noexcept
  : frequency_{frequency}, sampleRate_{sampleRate} {}

  /**
   Update to a new sample rate.

   @param sampleRate the new value to use
   */
  void setSampleRate(ValueType sampleRate) noexcept {
    sampleRate_ = sampleRate;
    cachedFrequency_ = 0.0;
  }

  /// @returns the current phase increment value
  ValueType value() noexcept {
    auto frequency = frequency_.frameValue();
    return frequency == cachedFrequency_ ? increment_ : updatedIncrement(frequency);
  }

private:

  ValueType updatedIncrement(ValueType frequency) noexcept {
    cachedFrequency_ = frequency;
    return increment_ = frequency / sampleRate_;
  }

  Parameters::Float& frequency_;
  ValueType sampleRate_;
  ValueType cachedFrequency_;
  ValueType increment_;
};

} // end namespace DSPHeaders
