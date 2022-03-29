// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#import "RampingParameter.hpp"

namespace DSPHeaders::Parameters {

/**
 Manage a value that represents a percentage. External values are [0-100] while internally it holds [0-1].
 */
template <typename T>
class PercentageParameter : public RampingParameter<T> {
public:
  using super = RampingParameter<T>;

  PercentageParameter() = default;
  explicit PercentageParameter(T value) noexcept : super(value) {}
  ~PercentageParameter() = default;

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the value in range [0-100] to use for the parameter
   @param duration the number of frames to transition over
   */
  void set(T value, AUAudioFrameCount frameCount) noexcept { super::set(value / 100.0, frameCount); }

  /**
   Obtain the current parameter value as a value in range [0-100]. Note that if ramping is in effect, this returns the
   final value at the end of ramping. One must use `frameValue` to obtain the value during ramping.

   @return the current parameter value in range [0-100]
   */
  T get() const noexcept { return super::get() * 100.0; }
};

} // end namespace DSPHeaders::Parameters
