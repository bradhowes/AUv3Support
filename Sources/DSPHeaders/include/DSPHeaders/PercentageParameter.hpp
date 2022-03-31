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
  explicit PercentageParameter(T value) noexcept : super(normalize(value)) {}
  ~PercentageParameter() = default;

  /**
   Set the new parameter value. If the given duration is not zero, then transition to the new value over that number of
   frames or calls to `frameValue`.

   @param target the value in range [0-100] to use for the parameter
   @param duration the number of frames to transition over
   */
  void set(T value, AUAudioFrameCount frameCount) noexcept { super::set(normalize(value), frameCount); }

  /// @returns the current parameter value in range [0-100]
  T get() const noexcept { return super::get() * 100.0; }

  /// @returns the current parameter value in range [0-1]
  T normalized() const noexcept { return super::get(); }

private:
  inline static constexpr T normalize(T value) noexcept { return std::clamp(value / 100.0, 0.0, 1.0); }
};

} // end namespace DSPHeaders::Parameters
