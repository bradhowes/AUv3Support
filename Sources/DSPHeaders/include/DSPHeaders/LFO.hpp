// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <cmath>

#import "DSP.hpp"
#import "DSPHeaders/RampingParameter.hpp"

enum class LFOWaveform { sinusoid, triangle, sawtooth, square};

namespace DSPHeaders {

/**
 Implementation of a low-frequency oscillator. Can generate:
 
 - sinusoid
 - triangle
 - sawtooth
 
 The output is bipolar ([-1.0, 1.0]). Use DSP::bipolarToUnipolar to generate values in [0.0, 1.0].

 Loosely based on code found in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019).
 */
template <typename ValueType = AUValue>
class LFO {
public:

  /**
   Create a new instance.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   @param waveform the waveform to emit
   */
  LFO(ValueType sampleRate, ValueType frequency, LFOWaveform waveform) noexcept
  : valueGenerator_{WaveformGenerator(waveform)}, waveform_{waveform}, sampleRate_{sampleRate} {
    setFrequency(frequency, 0);
    reset();
  }

  /**
   Create a new instance.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   */
  LFO(ValueType sampleRate, ValueType frequency) noexcept : LFO(sampleRate, frequency, LFOWaveform::sinusoid) {}

  /// Create a new instance.
  LFO() noexcept : LFO(44100.0, 1.0, LFOWaveform::sinusoid) {}

  /**
   Set the sample rate to use.
   
   @param sampleRate number of samples per second
   */
  void setSampleRate(ValueType sampleRate) noexcept {

    // We don't keep around the LFO frequency. It can be recalculated but that depends on existing sampleRate_ value.
    // Save the current frequency value and then reapply it after changing sampleRate_.
    auto tmp = frequency();
    sampleRate_ = sampleRate;
    setFrequency(tmp, 0);
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
   Set the frequency of the oscillator.
   
   @param frequency the frequency to operate at
   @param rampingDuration number of samples to ramp over
   */
  void setFrequency(ValueType frequency, AUAudioFrameCount rampingDuration) noexcept {
    assert(sampleRate_ != 0.0 && frequency >= 0.0 && rampingDuration >= 0);
    phaseIncrement_.set(frequency / sampleRate_, rampingDuration);
  }

  /**
   Set the phase of the oscillator. By default, the oscillator will start at 0.0.

   @param phase the normalized phase to start at (0-1.0)
   */
  void setPhase(ValueType phase) noexcept {
    assert(phase >= 0.0);
    while (phase >= 1.0) phase -= 1.0;
    moduloCounter_ = phase;
  }

  ValueType phase() const noexcept { return moduloCounter_; }

  /// Restart from a known zero state.
  void reset() noexcept { moduloCounter_ = 0.0; }

  /// @returns current value of the oscillator
  ValueType value() noexcept { return valueGenerator_(moduloCounter_); }

  /// @returns current value of the oscillator that is 90° ahead of what `value()` returns
  ValueType quadPhaseValue() const noexcept {
    return valueGenerator_(wrappedModuloCounter(moduloCounter_ + 0.25));
  }

  /// @returns current value of the oscillator that is 90° behind what `value()` returns
  ValueType negativeQuadPhaseValue() const noexcept {
    return valueGenerator_(wrappedModuloCounter(moduloCounter_ + 0.75));
  }

  /**
   Increment the oscillator to the next value.
   */
  void increment() noexcept {
    moduloCounter_ = wrappedModuloCounter(moduloCounter_ + phaseIncrement_.frameValue());
  }

   /// @returns current frequency in Hz
  ValueType frequency() const noexcept { return phaseIncrement_.get() * sampleRate_; }

  /// @returns the current waveform in effect for the LFO
  LFOWaveform waveform() const noexcept { return waveform_; }

  /**
   Stop any ramping that is active for the LFO frequency.
   */
  void stopRamping() noexcept { phaseIncrement_.stopRamping(); }

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
  ValueType moduloCounter_ = {0.0};
  Parameters::RampingParameter<ValueType> phaseIncrement_;
};

} // end namespace DSPHeaders
