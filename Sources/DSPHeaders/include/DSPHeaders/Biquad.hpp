// Copyright © 2021-2024 Brad Howes. All rights reserved.

#pragma once

#include <cmath>
#include <limits>
#include <utility>

#include <AVFoundation/AVFoundation.h>

namespace DSPHeaders::Biquad {

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
template <typename ValueType = AUValue>
struct Coefficients {

  /**
   Constructor to set all coefficients at once
   
   @param _a0 A0 coefficient
   @param _a1 A1 coefficient
   @param _a2 A2 coefficient
   @param _b1 B1 coefficient
   @param _b2 B2 coefficient
   */
  Coefficients(ValueType _a0, ValueType _a1, ValueType _a2, ValueType _b1, ValueType _b2) noexcept
  : a0{_a0}, a1{_a1}, a2{_a2}, b1{_b1}, b2{_b2} {}

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
  Coefficients A0(ValueType VV) noexcept { return Coefficients(VV, a1, a2, b1, b2); }
  /**
   Set the A1 coefficient, the second coefficient in the numerator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients A1(ValueType VV) noexcept { return Coefficients(a0, VV, a2, b1, b2); }
  /**
   Set the A2 coefficient, the third coefficient in the numerator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients A2(ValueType VV) noexcept { return Coefficients(a0, a1, VV, b1, b2); }
  /**
   Set the B1 coefficient, the second coefficient in the denominator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients B1(ValueType VV) noexcept { return Coefficients(a0, a1, a2, VV, b2); }
  /**
   Set the B2 coefficient, the third coefficient in the denominator
   
   @param VV the value to use
   @returns updated Coefficients collection
   */
  Coefficients B2(ValueType VV) noexcept { return Coefficients(a0, a1, a2, b1, VV); }
  
  /**
   A 1-pole low-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients LPF1(ValueType sampleRate, ValueType frequency) noexcept {
    ValueType theta = 2.0f * ValueType(M_PI) * frequency / sampleRate;
    ValueType gamma = std::cos(theta) / (1.0f + std::sin(theta));
    return Coefficients((1.0 - gamma) / 2.0f, (1.0f - gamma) / 2.0f, 0.0f, -gamma, 0.0f);
  }
  
  /**
   A 1-pole high-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients HPF1(ValueType sampleRate, ValueType frequency) noexcept {
    ValueType theta = 2.0f * ValueType(M_PI) * frequency / sampleRate;
    ValueType gamma = std::cos(theta) / (1.0f + std::sin(theta));
    return Coefficients((1.0 + gamma) / 2.0f, (1.0f + gamma) / -2.0f, 0.0f, -gamma, 0.0f);
  }
  
  /**
   A 2-pole low-pass coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients LPF2(ValueType sampleRate, ValueType frequency, ValueType resonance) noexcept {
    ValueType theta = 2.0f * ValueType(M_PI) * frequency / sampleRate;
    ValueType d = 1.0f / resonance / 2.0f;
    ValueType sinTheta = d * std::sin(theta);
    ValueType beta = 0.5f * (1.0f - sinTheta) / (1.0f + sinTheta);
    ValueType gamma = (0.5f + beta) * std::cos(theta);
    ValueType alpha = (0.5f + beta - gamma) / 2.0f;
    return Coefficients(alpha, 2.0f * alpha, alpha, -2.0f * gamma, 2.0f * beta);
  }
  
  /**
   A 2-pole high-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients HPF2(ValueType sampleRate, ValueType frequency, ValueType resonance) noexcept {
    ValueType theta = 2.0f * ValueType(M_PI) * frequency / sampleRate;
    ValueType d = 1.0f / resonance;
    ValueType beta = 0.5f * (1.0f - d / 2.0f * std::sin(theta)) / (1.0f + d / 2.0f * std::sin(theta));
    ValueType gamma = (0.5f + beta) * std::cos(theta);
    return Coefficients((0.5f + beta + gamma) / 2.0f, -1.0f * (0.5f + beta + gamma), (0.5f + beta + gamma) / 2.0f,
                        -2.0f * gamma, 2.0f * beta);
  }
  
  /**
   A 1-pole all-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @returns Coefficients collection
   */
  static Coefficients APF1(ValueType sampleRate, ValueType frequency) noexcept {
    ValueType tangent = std::tan(ValueType(M_PI) * frequency / sampleRate);
    ValueType alpha = (tangent - 1.0f) / (tangent + 1.0f);
    return Coefficients(alpha, 1.0f, 0.0f, alpha, 0.0f);
  }
  
  /**
   A 2-pole all-pass filter coefficients generator.
   
   @param sampleRate the sample rate being used
   @param frequency the cutoff frequency of the filter
   @param resonance the filter resonance parameter (Q)
   @returns Coefficients collection
   */
  static Coefficients APF2(ValueType sampleRate, ValueType frequency, ValueType resonance) noexcept {
    ValueType bandwidth = frequency / resonance;
    ValueType argTan = ValueType(M_PI) * bandwidth / sampleRate;
    if (argTan >= 0.95f * ValueType(M_PI) / 2.0f) argTan = 0.95f * ValueType(M_PI) / 2.0f;
    ValueType tangent = std::tan(argTan);
    ValueType alpha = (tangent - 1.0f) / (tangent + 1.0f);
    ValueType beta = -std::cos(2.0f * ValueType(M_PI) * frequency / sampleRate);
    return Coefficients(-alpha, beta * (1.0f - alpha), 1.0f, beta * (1.0f - alpha), -alpha);
  }

  /**
   Obtain a collection of delta coefficient values that can be used to ramp a change in filter coefficients.

   @param goal the goal coefficient collection
   @param sampleCount the number of samples to ramp over
   @return new Coefficients instance with the delta values to ramp with
   */
  Coefficients rampFactor(const Coefficients& goal, size_t sampleCount) const noexcept
  {
    ValueType factor = 1.0f / sampleCount;
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
  void operator +=(const Coefficients& change) noexcept
  {
    a0 += change.a0;
    a1 += change.a1;
    a2 += change.a2;
    b1 += change.b1;
    b2 += change.b2;
  }

  ValueType a0; /// A0 coefficient in numerator
  ValueType a1; /// A1 coefficient in numerator
  ValueType a2; /// A2 coefficient in numerator
  ValueType b1; /// B1 coefficient in denominator
  ValueType b2; /// B2 coefficient in denominator
};

/**
 Mutable filter state.
 */
template <typename ValueType = AUValue>
struct State {
  ValueType x_z1;
  ValueType x_z2;
  ValueType y_z1;
  ValueType y_z2;
};

/// Namespace for the various transforms that can be used to calculate values from a biquad graph. The differences and
/// diagrams of the graphs are documented in Pirkle (2019) referenced above, as well as at
/// https://en.wikipedia.org/wiki/Digital_biquad_filter . In short, there are two direct forms and two transposed
/// versions. The `Canonical` version here is the direct form #2.
namespace Transform {

/**
 Base class for all Transform classes.
 */
template <typename ValueType = AUValue>
struct Base {

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
  static ValueType forceMinToZero(ValueType value) noexcept {
    static constexpr ValueType noiseFloor = 2.0e-10f;
    return (value > 0.0f && value <= noiseFloor) || (value < 0.0f && -value <= noiseFloor) ? 0.0f : value;
  }
};

/**
 Transform for the 'direct' biquad structure.
 */
template <typename ValueType = AUValue>
struct Direct : public Base<ValueType> {

  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static ValueType transform(ValueType input, State<ValueType>& state,
                             const Coefficients<ValueType>& coefficients) noexcept {
    ValueType output = coefficients.a0 * input + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 -
    coefficients.b1 * state.y_z1 - coefficients.b2 * state.y_z2;
    output = Base<ValueType>::forceMinToZero(output);
    state.x_z2 = state.x_z1;
    state.x_z1 = input;
    state.y_z2 = state.y_z1;
    state.y_z1 = output;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns state convolved with coefficients
   */
  static ValueType storageComponent(const State<ValueType>& state,
                                    const Coefficients<ValueType>& coefficients) noexcept {
    return coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2 - coefficients.b1 * state.y_z1 -
    coefficients.b2 * state.y_z2;
  }
};

/// Transform for the 'canonical' biquad structure (min state)
template <typename ValueType = AUValue>
struct Canonical : Base<ValueType> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static ValueType transform(ValueType input, State<ValueType>& state,
                             const Coefficients<ValueType>& coefficients) noexcept {
    ValueType theta = input - coefficients.b1 * state.x_z1 - coefficients.b2 * state.x_z2;
    ValueType output = coefficients.a0 * theta + coefficients.a1 * state.x_z1 + coefficients.a2 * state.x_z2;
    output = Base<ValueType>::forceMinToZero(output);
    state.x_z2 = state.x_z1;
    state.x_z1 = theta;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @returns always 0.0
   */
  static ValueType storageComponent(const State<ValueType>&, const Coefficients<ValueType>&) noexcept { return 0.0; }
};

/// Transform for the transposed 'direct' biquad structure
template <typename ValueType = AUValue>
struct DirectTranspose : Base<ValueType> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static ValueType transform(ValueType input, State<ValueType>& state,
                             const Coefficients<ValueType>& coefficients) noexcept {
    ValueType theta = input + state.y_z1;
    ValueType output = coefficients.a0 * theta + state.x_z1;
    output = Base<ValueType>::forceMinToZero(output);
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
  static ValueType storageComponent(const State<ValueType>&, const Coefficients<ValueType>&) noexcept { return 0.0; }
};

/// Transform for the transposed 'canonical' biquad structure (min state)
template <typename ValueType = AUValue>
struct CanonicalTranspose : Base<ValueType> {
  
  /**
   Transform a value
   
   @param input the input value to transform
   @param state the filter state work with
   @param coefficients the filter coefficients to use
   @returns transformed value
   */
  static ValueType transform(ValueType input, State<ValueType>& state,
                             const Coefficients<ValueType>& coefficients) noexcept {
    ValueType output = Base<ValueType>::forceMinToZero(coefficients.a0 * input + state.x_z1);
    state.x_z1 = coefficients.a1 * input - coefficients.b1 * output + state.x_z2;
    state.x_z2 = coefficients.a2 * input - coefficients.b2 * output;
    return output;
  }
  
  /**
   Obtain a numeric representation of the internal storage state
   
   @param state the filter state work with
   @returns the Z1 state value
   */
  static ValueType storageComponent(const State<ValueType>& state, const Coefficients<ValueType>&) noexcept {
    return state.x_z1;
  }
};

} // namespace Transform

/**
 Generic biquad filter setup. Only knows how to reset its internal state and to transform (filter)
 values.
 */
template <typename Transformer, typename ValueType = AUValue>
class Filter {
public:
  using CoefficientsType = Coefficients<ValueType>;
  using StateType = State<ValueType>;

  Filter() = default;

  /**
   Create a new filter using the given biquad coefficients.

   @param coefficients the filter coefficients to use
   */
  explicit Filter(const CoefficientsType& coefficients) noexcept : state_{}, ramper_{coefficients} {}

  /**
   Create a new filter using the given biquad coefficients.

   @param coefficients the filter coefficients to use
   */
  explicit Filter(CoefficientsType&& coefficients) noexcept : state_{}, ramper_{coefficients} {}

  /**
   Use a new set of biquad coefficients.

   @param coefficients the new filter coefficients to use
   @param rampDurationInSamples gradually apply change over this number of samples
   */
  void setCoefficients(const CoefficientsType& coefficients, size_t rampDurationInSamples = 0) noexcept
  {
    ramper_.start(coefficients, rampDurationInSamples);
  }

  /**
   Use a new set of biquad coefficients.

   @param coefficients the new filter coefficients to use
   @param rampDurationInSamples gradually apply change over this number of samples
   */
  void setCoefficients(CoefficientsType&& coefficients, size_t rampDurationInSamples = 0) noexcept
  {
    ramper_.start(coefficients, rampDurationInSamples);
  }
  
  /**
   Reset internal state.
   */
  void reset() noexcept
  {
    state_ = StateType();
    ramper_.reset();
  }

  /**
   Apply the filter to a given value.

   @param input the value to filter
   @returns trasformed value
   */
  ValueType transform(ValueType input) noexcept
  {
    return Transformer::transform(input, state_, ramper_.coefficients());
  }
  
  /**
   Obtain the `gain` value from the coefficients.
   */
  ValueType gainValue() const noexcept { return ramper_.coefficients().a0; }
  
  /**
   Obtain a calculated state value. This used in some of Pirkle's signal processing algorithms.
   */
  ValueType storageComponent() const noexcept { return Transformer::storageComponent(state_, ramper_.coefficients()); }

private:

  /**
   Adapter for a Biquad filter that changes it over time (samples) rather than abruptly and possibly with audio
   artifacts.
   */
  struct Ramper {

    Ramper() = default;

    Ramper(const CoefficientsType& coefficients) noexcept : coefficients_{coefficients} {}

    Ramper(CoefficientsType&& coefficients) noexcept : coefficients_{std::move(coefficients)} {}

    /**
     Set new coefficients for the filter, ramping to them over time.

     @param coefficients new coefficients to use
     @param rampingDuration how many samples to take to change from old value to new one
     */
    void start(const CoefficientsType& coefficients, size_t rampingDuration) noexcept
    {
      if (rampingDuration) {
        rampRemaining_ = rampingDuration;
        goal_ = coefficients;
        change_ = coefficients_.rampFactor(goal_, rampingDuration);
      } else {
        coefficients_ = coefficients;
      }
    }

    void setupRamp(const CoefficientsType& coefficients, size_t rampingDuration) noexcept {
      goal_ = coefficients;
      rampRemaining_ = rampingDuration;
      change_ = coefficients_.rampFactor(goal_, rampingDuration);
    }

    /**
     Set new coefficients for the filter, ramping to them over time.

     @param coefficients new coefficients to use
     @param rampingDuration how many samples to take to change from old value to new one
     */
    void start(CoefficientsType&& coefficients, size_t rampingDuration) noexcept
    {
      if (rampingDuration) {
        setupRamp(std::forward(coefficients), rampingDuration);
      } else {
        coefficients_ = std::move(coefficients);
      }
    }

    void setupRamp(CoefficientsType&& coefficients, size_t rampingDuration) noexcept {
      goal_ = std::move(coefficients);
      rampRemaining_ = rampingDuration;
      change_ = coefficients_.rampFactor(goal_, rampingDuration);
    }

    void reset() noexcept
    {
      if (rampRemaining_) {
        rampRemaining_ = 0;
        coefficients_ = goal_;
      }
    }

    /**
     Obtain the filter coefficients to use, updating if ramping is in progress.

     @returns filter coefficients
     */
    const CoefficientsType& coefficients() noexcept
    {
      switch (rampRemaining_) {
        case 0:
          break;
        case 1:
          rampRemaining_ = 0;
          coefficients_ = goal_;
          break;
        default:
          rampRemaining_ -= 1;
          coefficients_ += change_;
          break;
      }
      return coefficients_;
    }

  private:
    size_t rampRemaining_{};
    CoefficientsType coefficients_{};
    CoefficientsType change_{};
    CoefficientsType goal_{};
  };

  /**
   Obtain writable reference to current coefficients. Only used by RampingAdapter
   */
  CoefficientsType& coefficients() noexcept { return ramper_.coefficients(); }

  StateType state_;
  mutable Ramper ramper_;
};

template <typename ValueType = AUValue>
using Direct = Filter<Transform::Direct<ValueType>, ValueType>;

template <typename ValueType = AUValue>
using DirectTranspose = Filter<Transform::DirectTranspose<ValueType>, ValueType>;

template <typename ValueType = AUValue>
using Canonical = Filter<Transform::Canonical<ValueType>, ValueType>;

template <typename ValueType = AUValue>
using CanonicalTranspose = Filter<Transform::CanonicalTranspose<ValueType>, ValueType>;

} // namespace DSPHeaders::Biquad
