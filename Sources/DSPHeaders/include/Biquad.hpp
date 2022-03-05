// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <limits>
#include <os/log.h>

namespace Biquad {

/**
 Filter coefficients. The naming here follows that in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019),
 where 'a' coefficients refer to values in the numerator of the H(z) transform and 'b' coefficients are from the
 denominator:

         a0 + a1*z^-1 + a2*z^-2
 H(z) = ------------------------
         b0 + b1*z^-1 + b2*z^-2

 This is opposite of the nomenclature found in the equations from Robert Bristow-Johnson
 (http://shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html) that are the basis for FluidSynth's implementation
 of low-pass / high-pass filters, where 'a' coefficients are in the numerator and the 'b' coefficients are in the
 denominator. Both versions eliminate the standalone coefficient in the denominator (b0 above), so there are only two
 coefficients in the denominator (b1 and b2), and a0 becomes a gain factor.

 Note that in Pirkle there are 'c0' and 'd0' values that the book uses for mixing wet (c0) and dry (d0)
 values which are not found here.
 */
template <typename T>
struct Coefficients {
  using ValueType = T;

  /**
   Constructor to set all coefficients at once
   
   @param _a0 A0 coefficient
   @param _a1 A1 coefficient
   @param _a2 A2 coefficient
   @param _b1 B1 coefficient
   @param _b2 B2 coefficient
   */
  Coefficients(T _a0, T _a1, T _a2, T _b1, T _b2) : a0{_a0}, a1{_a1}, a2{_a2}, b1{_b1}, b2{_b2} {}

  Coefficients() = default;

  Coefficients(const Coefficients&) = default;

  Coefficients(Coefficients&&) = default;

  Coefficients& operator =(const Coefficients&) = default;

  Coefficients& operator =(Coefficients&&) = default;

  /**
   Set the A0 coefficient, the first coefficient in the numerator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients A0(T VV) { return Coefficients(VV, a1, a2, b1, b2); }
  /**
   Set the A1 coefficient, the second coefficient in the numerator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients A1(T VV) { return Coefficients(a0, VV, a2, b1, b2); }
  /**
   Set the A2 coefficient, the third coefficient in the numerator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients A2(T VV) { return Coefficients(a0, a1, VV, b1, b2); }
  /**
   Set the B1 coefficient, the second coefficient in the denominator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients B1(T VV) { return Coefficients(a0, a1, a2, VV, b2); }
  /**
   Set the B2 coefficient, the third coefficient in the denominator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients B2(T VV) { return Coefficients(a0, a1, a2, b1, VV); }
  
  /**
   A 1-pole low-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients<T> LPF1(T sampleRate, T frequency) {
    double theta = 2.0 * M_PI * frequency / sampleRate;
    double gamma = std::cos(theta) / (1.0 + std::sin(theta));
    return Coefficients((1.0 - gamma) / 2.0, (1.0 - gamma) / 2.0, 0.0, -gamma, 0.0);
  }
  
  /**
   A 1-pole high-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients<T> HPF1(T sampleRate, T frequency) {
    double theta = 2.0 * M_PI * frequency / sampleRate;
    double gamma = std::cos(theta) / (1.0 + std::sin(theta));
    return Coefficients((1.0 + gamma) / 2.0, (1.0 + gamma) / -2.0, 0.0, -gamma, 0.0);
  }
  
  /**
   A 2-pole low-pass coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients<T> LPF2(T sampleRate, T frequency, T resonance) {
    double theta = 2.0 * M_PI * frequency / sampleRate;
    double d = 1.0 / resonance / 2.0;
    double sinTheta = d * std::sin(theta);
    double beta = 0.5 * (1 - sinTheta) / (1 + sinTheta);
    double gamma = (0.5 + beta) * std::cos(theta);
    double alpha = (0.5 + beta - gamma) / 2.0;
    return Coefficients(alpha, 2.0 * alpha, alpha, -2.0 * gamma, 2.0 * beta);
  }
  
  /**
   A 2-pole high-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients<T> HPF2(T sampleRate, T frequency, T resonance) {
    double theta = 2.0 * M_PI * frequency / sampleRate;
    double d = 1.0 / resonance;
    double beta = 0.5 * (1 - d / 2.0 * std::sin(theta)) / (1 + d / 2.0 * std::sin(theta));
    double gamma = (0.5 + beta) * std::cos(theta);
    return Coefficients((0.5 + beta + gamma) / 2.0, -1.0 * (0.5 + beta + gamma), (0.5 + beta + gamma) / 2.0,
                        -2.0 * gamma, 2.0 * beta);
  }
  
  /**
   A 1-pole all-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients<T> APF1(T sampleRate, T frequency) {
    double tangent = std::tan(M_PI * frequency / sampleRate);
    double alpha = (tangent - 1.0) / (tangent + 1.0);
    return Coefficients(alpha, 1.0, 0.0, alpha, 0.0);
  }
  
  /**
   A 2-pole all-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients<T> APF2(T sampleRate, T frequency, T resonance) {
    double bandwidth = frequency / resonance;
    double argTan = M_PI * bandwidth / sampleRate;
    if (argTan >= 0.95 * M_PI / 2.0) argTan = 0.95 * M_PI / 2.0;
    double tangent = std::tan(argTan);
    double alpha = (tangent - 1.0) / (tangent + 1.0);
    double beta = -std::cos(2.0 * M_PI * frequency / sampleRate);
    return Coefficients(-alpha, beta * (1.0 - alpha), 1.0, beta * (1.0 - alpha), -alpha);
  }

  /**
   Obtain a collection of delta coefficient values.

   @param goal the goal coefficient collection
   @param sampleCount the number of samples to ramp over
   @return new Coefficients instance with the delta values to ramp with
   */
  Coefficients rampFactor(const Coefficients& goal, size_t sampleCount) const
  {
    double factor = 1.0 / sampleCount;
    return Coefficients((goal.a0 - a0) * factor,
                        (goal.a1 - a1) * factor,
                        (goal.a2 - a2) * factor,
                        (goal.b1 - b1) * factor,
                        (goal.b2 - b2) * factor);
  }

  /**
   Add delta values from a `rampFactor` to update the coefficients.

   @param change the delta to apply to the current coefficients.
   */
  void operator +=(const Coefficients& change)
  {
    a0 += change.a0;
    a1 += change.a1;
    a2 += change.a2;
    b1 += change.b1;
    b2 += change.b2;
  }

  T a0; /// A0 coefficient in numerator
  T a1; /// A1 coefficient in numerator
  T a2; /// A2 coefficient in numerator
  T b1; /// B1 coefficient in denominator
  T b2; /// B2 coefficient in denominator
  
  inline static os_log_t log_{os_log_create("DSP.Biquad", "Coefficients")};
};

/**
 Mutable filter state.
 */
template <typename T>
struct State {
  using ValueType = T;

  T x_z1;
  T x_z2;
  T y_z1;
  T y_z2;
};

/// Namespace for the various transforms that can be used to calculate values from a biquad graph. The differences and
/// diagrams of the graphs are documented in Pirkle (2019) referenced above, as well as at
/// https://en.wikipedia.org/wiki/Digital_biquad_filter . In short, there are two direct forms and two transposed
/// versions. The `Canonical` version here is the direct form #2.
namespace Transform {

/**
 Base class for all Transform classes.
 */
template <typename T>
struct Base {
  using ValueType = T;

  /**
   If value is smaller than a noise floor value, force it to be zero. 16-bit audio provides ~96dB dynamic range where
   the least-significant bit adds ~1.0e-5 change in amplitude. So, we cannot really do anything with values below this.
   Similarly, 24-bit audio provides 144dB dynamic range and the least-significant bit gives ~6.0e-8 change in amplitude
   or 1.0e-7. Finally, 32-bit audio provides ~192dB dynamic range with a corresponding ~1.0e-10 resolution. We will use
   that for our cutoff here, multiplied by 2 because audio samples range between -1 and 1 instead of 0 to 1, so there is
   half the resolution. All of these values are well above the std::numeric_limits<float>::min() value of 1.17549e-38.

   @param value the value to inspect
   @returns value or 0.0
   */
  static ValueType forceMinToZero(ValueType value) {
    static constexpr ValueType noiseFloor = 2.0e-10;
    return (value > 0.0 && value <= noiseFloor) || (value < 0.0 && -value <= noiseFloor) ? 0.0 : value;
  }
};

/**
 Transform for the 'direct' biquad structure.
 */
template <typename T>
struct Direct : public Base<T> {

  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static T transform(T input, State<T>& state, const Coefficients<T>& coefficients) {
    T output = coefficients.a0 * input + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 -
    coefficients.b1 * state.y_z1 - coefficients.b2 * state.y_z2;
    output = Base<T>::forceMinToZero(output);
    state.x_z2 = state.x_z1;
    state.x_z1 = input;
    state.y_z2 = state.y_z1;
    state.y_z1 = output;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @returns state convolved with coefficients
   */
  static T storageComponent(const State<T>& state, const Coefficients<T>& coefficients) {
    return coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 - coefficients.b1 * state.y_z1 -
    coefficients.b2 * state.y_z2;
  }
};

/// Transform for the 'canonical' biquad structure (min state)
template <typename T>
struct Canonical : Base<T> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static T transform(T input, State<T>& state, const Coefficients<T>& coefficients) {
    T theta = input - coefficients.b1 * state.x_z1 - coefficients.b2 * state.x_z2;
    T output = coefficients.a0 * theta + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2;
    output = Base<T>::forceMinToZero(output);
    state.x_z2 = state.x_z1;
    state.x_z1 = theta;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @returns always 0.0
   */
  static T storageComponent(const State<T>& state, const Coefficients<T>& coefficients) { return 0.0; }
};

/// Transform for the transposed 'direct' biquad structure
template <typename T>
struct DirectTranspose : Base<T> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static T transform(T input, State<T>& state, const Coefficients<T>& coefficients) {
    T theta = input + state.y_z1;
    T output = coefficients.a0 * theta + state.x_z1;
    output = Base<T>::forceMinToZero(output);
    state.y_z1 = state.y_z2 - coefficients.b1 * theta;
    state.y_z2 = -coefficients.b2 * theta;
    state.x_z1 = state.x_z2 + coefficients.a1 * theta;
    state.x_z2 = coefficients.a2 * theta;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @returns always 0.0
   */
  static T storageComponent(const State<T>& state, const Coefficients<T>& coefficients) { return 0.0; }
};

/// Transform for the transposed 'canonical' biquad structure (min state)
template <typename T>
struct CanonicalTranspose : Base<T> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static T transform(T input, State<T>& state, const Coefficients<T>& coefficients) {
    T output = Base<T>::forceMinToZero(coefficients.a0 * input + state.x_z1);
    state.x_z1 = coefficients.a1 * input - coefficients.b1 * output + state.x_z2;
    state.x_z2 = coefficients.a2 * input - coefficients.b2 * output;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @returns the Z1 state value
   */
  static T storageComponent(const State<T>& state, const Coefficients<T>& coefficients) { return state.x_z1; }
};

} // namespace Transform

/**
 Generic biquad filter setup. Only knows how to reset its internal state and to transform (filter)
 values.
 */
template <typename T, typename Transformer>
class Filter {
public:
  using ValueType = T;
  using CoefficientsType = Coefficients<T>;
  using StateType = State<T>;
  
  /**
   Create a new filter using the given biquad coefficients.

   @param coefficients the filter coefficients to use
   */
  explicit Filter(const CoefficientsType& coefficients) : coefficients_{coefficients}, state_{} {}

  /**
   Create a new filter using the given biquad coefficients.

   @param coefficients the filter coefficients to use
   */
  explicit Filter(CoefficientsType&& coefficients) : coefficients_{coefficients}, state_{} {}

  Filter() = default;
  
  /**
   Use a new set of biquad coefficients.
   */
  void setCoefficients(const CoefficientsType& coefficients) { coefficients_ = coefficients; }

  /**
   Use a new set of biquad coefficients.
   */
  void setCoefficients(CoefficientsType&& coefficients) { coefficients_ = coefficients; }
  
  /**
   Reset internal state.
   */
  void reset() { state_ = StateType(); }

  /**
   Apply the filter to a given value.
   */
  ValueType transform(ValueType input) { return Transformer::transform(input, state_, coefficients_); }
  
  /**
   Obtain the `gain` value from the coefficients.
   */
  ValueType gainValue() const { return coefficients_.a0; }
  
  /**
   Obtain a calculated state value. This used in some of Pirkle's signal processing algorithms.
   */
  ValueType storageComponent() const { return Transformer::storageComponent(state_, coefficients_); }

private:

  /**
   Obtain writable reference to current coefficients. Only used by RampingAdapter
   */
  CoefficientsType& coefficients() { return coefficients_; }

  CoefficientsType coefficients_;
  StateType state_;

  template <typename FilterType> friend class RampingAdapter;

  os_log_t log_{os_log_create("DSP.Biquad", "Filter")};
};

template <typename T>
using Direct = Filter<T, Transform::Direct<T>>;

template <typename T>
using DirectTranspose = Filter<T, Transform::DirectTranspose<T>>;

template <typename T>
using Canonical = Filter<T, Transform::Canonical<T>>;

template <typename T>
using CanonicalTranspose = Filter<T, Transform::CanonicalTranspose<T>>;

/**
 Adapter for a Biquad filter that changes it over time (samples) rather than abruptly and possibly with audio artifacts.
 */
template <typename FilterType>
class RampingAdapter {
public:
  using CoefficientsType = typename FilterType::CoefficientsType;
  using ValueType = typename CoefficientsType::ValueType;

  /**
   Create a ramped version of a filter.

   @param filter the filter to ramp
   @param sampleCount the sample count to ramp over when `setCoefficients` is invoked.
   */
  RampingAdapter(const FilterType& filter, size_t sampleCount) : filter_{filter}, sampleCount_{sampleCount}
  {
    assert(sampleCount > 0);
  }

  /**
   Create a ramped version of a filter.

   @param filter the filter to ramp
   @param sampleCount the sample count to ramp over when `setCoefficients` is invoked.
   */
  RampingAdapter(FilterType&& filter, size_t sampleCount) : filter_{std::move(filter)}, sampleCount_{sampleCount}
  {
    assert(sampleCount > 0);
  }

  /**
   Set new coefficients for the filter, ramping to them over time.

   @param coefficients new coefficients to use
   */
  void setCoefficients(const CoefficientsType& coefficients)
  {
    rampRemaining_ = sampleCount_;
    goal_ = coefficients;
    change_ = filter_.coefficients_.rampFactor(goal_, sampleCount_);
  }

  /**
   Set new coefficients for the filter, ramping to them over time.

   @param coefficients new coefficients to use
   */
  void setCoefficients(CoefficientsType&& coefficients)
  {
    rampRemaining_ = sampleCount_;
    goal_ = std::forward(coefficients);
    change_ = filter_.coefficients().rampFactor(goal_, sampleCount_);
  }

  /**
   Apply the filter to a given value. Accounts for any ramping that is in effect.

   @param input the sample to filter
   @returns filtered sample
   */
  ValueType transform(ValueType input)
  {
    if (rampRemaining_ > 0) {
      --rampRemaining_;
      if (rampRemaining_ == 0) {
        filter_.setCoefficients(goal_);
      } else {
        filter_.coefficients_ += change_;
      }
    }
    return filter_.transform(input);
  }

  /**
   Reset internal state.
   */
  void reset() { filter_.reset(); }

  /**
   Obtain the `gain` value from the coefficients.
   */
  ValueType gainValue() const { return filter_.gainValue(); }

  /**
   Obtain a calculated state value. This used in some of Pirkle's signal processing algorithms.
   */
  ValueType storageComponent() const { return filter_.storageComponent(); }

private:
  FilterType filter_;
  size_t sampleCount_;
  size_t rampRemaining_{0};
  CoefficientsType change_{};
  CoefficientsType goal_{};
};

} // namespace Biquad
