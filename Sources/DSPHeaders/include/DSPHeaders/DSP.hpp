// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <array>
#import <algorithm>
#import <cmath>

namespace DSPHeaders::DSP {

/**
 Translate value in range [0, +1] into one in range [-1, +1]
 
 @param modulator the value to translate
 @returns value in range [-1, +1]
 */
template <typename T> auto unipolarToBipolar(T modulator) noexcept { return 2.0 * modulator - 1.0; }

/**
 Translate value in range [-1, +1] into one in range [0, +1]
 
 @param modulator the value to translate
 @returns value in range [0, +1]
 */
template <typename T> auto bipolarToUnipolar(T modulator) noexcept { return 0.5 * modulator + 0.5; }

/**
 Perform linear translation from a value in range [0.0, 1.0] into one in [minValue, maxValue].
 
 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is 0
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> auto unipolarModulation(T modulator, T minValue, T maxValue) noexcept {
  return std::clamp<T>(modulator, 0.0, 1.0) * (maxValue - minValue) + minValue;
}

/**
 Perform linear translation from a value in range [-1.0, 1.0] into one in [minValue, maxValue]
 
 @param modulator the value to translate
 @param minValue the lowest value to return when modulator is -1
 @param maxValue the highest value to return when modulator is +1
 @returns value in range [minValue, maxValue]
 */
template <typename T> auto bipolarModulation(T modulator, T minValue, T maxValue) noexcept {
  auto mid = (maxValue - minValue) * 0.5;
  return std::clamp<T>(modulator, -1.0, 1.0) * mid + mid + minValue;
}

/**
 Estimate sin() value from a radian angle between -PI and PI.
 Derived from code in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019)
 As can be seen in the unit test `testParabolicSineAccuracy`, the worst-case deviation from
 std::sin is ~0.0011.
 
 @param angle value between -PI and PI
 @returns approximate sin value
 */
template <typename T> auto parabolicSine(T angle) noexcept {
  const T B = 4.0 / M_PI;
  const T C = -4.0 / (M_PI * M_PI);
  const T P = 0.225;
  T y = B * angle + C * angle * std::abs(angle);
  return P * (y * std::abs(y) - y) + y;
}

namespace Interpolation {

/**
 Interpolate a value from two values.

 @param partial indication of affinity for one of the two values. Values [0-0.5) favor x0, while values (0.5-1.0)
 favor x1. A value of 0.5 equally favors both.
 @param x0 first value to use
 @param x1 second value to use
 */
inline constexpr double linear(double partial, double x0, double x1) noexcept { return partial * (x1 - x0) + x0; }

/**
 Types and configuration for the cubic 4th order interpolator.
 */
struct Cubic4thOrder {
  static constexpr size_t TableSize = 1024;
  using WeightsEntry = std::array<double, 4>;
  static std::array<WeightsEntry, TableSize> weights_;
};

/**
 Interpolate a value from four values.

 @param partial location between the second value and the third. By definition it should always be < 1.0
 @param x0 first value to use
 @param x1 second value to use
 @param x2 third value to use
 @param x3 fourth value to use
 */
inline static double cubic4thOrder(double partial, double x0, double x1, double x2, double x3) noexcept {
  // Partial is expected to be < 1.0 so with truncation index should always be in range [0, 1)
  size_t index = size_t(partial * Cubic4thOrder::TableSize);
  assert(index < Cubic4thOrder::TableSize);
  const auto& w{Cubic4thOrder::weights_[index]};
  return x0 * w[0] + x1 * w[1] + x2 * w[2] + x3 * w[3];
}

} // Interpolation namespace

} // end namespace DSPHeaders::DSP
