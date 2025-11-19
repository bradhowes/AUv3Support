// Copyright © 2021-2025 Brad Howes. All rights reserved.

#pragma once

#import <cassert>
#import <cmath>

#import "DSP.hpp"
#import "DSPHeaders/Parameters/Float.hpp"
#import "DSPHeaders/PhaseIncrement.hpp"

enum class LFOWaveform { sinusoid, triangle, sawtooth, square};

namespace DSPHeaders {

/**
 Implementation of a low-frequency oscillator. Can generate:
 
 - sinusoid
 - triangle
 - sawtooth
 
 The output is bipolar ([-1.0, 1.0]). Use DSP::bipolarToUnipolar to generate values in [0.0, 1.0].

 Loosely based on code found in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019).

 The LFO operates at a frequency which is controlled by an AU parameter setting that can be adjusted in
 real-time. The LFO provides a facade for controlling this value, but internally, the value that is
 being managed is the phase increment that governs how the signal changes at each sample.
 */
template <typename ValueType = AUValue>
class LFO {
public:

  /**
   Create a new instance.

   @param frequency the frequency of the oscillator
   @param sampleRate number of samples per second
   @param waveform the waveform to emit
   */
  LFO(Parameters::Float& frequency, ValueType sampleRate, LFOWaveform waveform) noexcept
  : valueGenerator_{WaveformGenerator(waveform)}, waveform_{waveform}, sampleRate_{sampleRate},
  phaseIncrement_ {frequency, sampleRate} {
    reset();
  }

  /**
   Create a new instance.

   @param frequency the frequency of the oscillator
   @param sampleRate number of samples per second
   */
  LFO(Parameters::Float& frequency, ValueType sampleRate) noexcept
  : LFO(frequency, sampleRate, LFOWaveform::sinusoid) {}

  /** Create a new instance.

   @param frequency the frequency of the oscillator
   */
  LFO(Parameters::Float& frequency) noexcept : LFO(frequency, 44100.0, LFOWaveform::sinusoid) {}

  /**
   Set the sample rate to use.
   
   @param sampleRate number of samples per second
   */
  void setSampleRate(ValueType sampleRate) noexcept {
    phaseIncrement_.setSampleRate(sampleRate);
  }

  /**
   Set the waveform to use
   
   @param waveform the waveform to emit
   */
  void setWaveform(LFOWaveform waveform) noexcept {
    waveform_ = waveform;
    valueGenerator_ = WaveformGenerator(waveform);
  }

  /**
   Set the phase of the oscillator. By default, the oscillator will start at 0.0.

   @param phase the normalized phase to start at (0-1.0)
   */
  void setPhase(ValueType phase) noexcept {
    while (phase >= 1.0) phase -= 1.0;
    phase_ = phase;
  }

  /// @returns current internal normalized phase value
  ValueType phase() const noexcept { return phase_; }

  /// Restart from a known zero state.
  void reset() noexcept { phase_ = 0.0; }

  /// @returns current value of the oscillator
  ValueType value() const noexcept { return valueGenerator_(phase_); }

  /// @returns current value of the oscillator that is 90° ahead of what `value()` returns
  ValueType quadPhaseValue() const noexcept { return valueGenerator_(wrappedModuloCounter(phase_ + 0.25)); }

  /// @returns current value of the oscillator that is 90° behind what `value()` returns
  ValueType negativeQuadPhaseValue() const noexcept { return valueGenerator_(wrappedModuloCounter(phase_ + 0.75)); }

  /**
   Increment the oscillator to the next value.
   */
  void increment() noexcept {
    phase_ = wrappedModuloCounter(phase_ + phaseIncrement_.value());
  }

  /// @returns the current waveform in effect for the LFO
  LFOWaveform waveform() const noexcept { return waveform_; }

private:
  using ValueGenerator = ValueType (*)(ValueType);

  static ValueGenerator WaveformGenerator(LFOWaveform waveform) noexcept {
    switch (waveform) {
      case LFOWaveform::sinusoid: return sineValue;
      case LFOWaveform::sawtooth: return sawtoothValue;
      case LFOWaveform::triangle: return triangleValue;
      case LFOWaveform::square: return squareValue;
    }
    assert(false);
  }

  static ValueType wrappedModuloCounter(ValueType counter) noexcept {
    return (counter >= 1.0) ? counter - 1.0 : counter;
  }

  static ValueType sineValue(ValueType counter) noexcept { return std::sin(M_PI - counter * 2.0 * M_PI); }
  static ValueType sawtoothValue(ValueType counter) noexcept { return DSP::unipolarToBipolar(counter); }
  static ValueType triangleValue(ValueType counter) noexcept {
    return DSP::unipolarToBipolar(std::abs(DSP::unipolarToBipolar(counter)));
  }
  static ValueType squareValue(ValueType counter) noexcept { return counter >= 0.5 ? 1.0 : -1.0; }

  ValueType sampleRate_;
  LFOWaveform waveform_;
  ValueGenerator valueGenerator_;
  ValueType phase_ = {0.0};
  PhaseIncrement<ValueType> phaseIncrement_;
};

} // end namespace DSPHeaders
