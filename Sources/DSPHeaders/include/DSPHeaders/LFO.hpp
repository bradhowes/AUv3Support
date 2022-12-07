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
template <typename T>
class LFO {
public:

  /**
   Create a new instance.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   @param waveform the waveform to emit
   */
  LFO(T sampleRate, T frequency, LFOWaveform waveform) noexcept
  : valueGenerator_{WaveformGenerator(waveform)}, sampleRate_{sampleRate}
  {
    setFrequency(frequency, 0);
    reset();
  }

  /**
   Create a new instance.

   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   */
  LFO(T sampleRate, T frequency) noexcept : LFO(sampleRate, frequency, LFOWaveform::sinusoid) {}

  /// Create a new instance.
  LFO() noexcept : LFO(44100.0, 1.0, LFOWaveform::sinusoid) {}

  /**
   Set the sample rate to use.
   
   @param sampleRate number of samples per second
   */
  void setSampleRate(T sampleRate) noexcept {

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
  void setWaveform(LFOWaveform waveform) noexcept { valueGenerator_ = WaveformGenerator(waveform); }

  /**
   Set the frequency of the oscillator.
   
   @param frequency the frequency to operate at
   @param rampingDuration number of samples to ramp over
   */
  void setFrequency(T frequency, AUAudioFrameCount rampingDuration) noexcept {
    assert(sampleRate_ != 0.0);
    phaseIncrement_.set(frequency / sampleRate_, rampingDuration);
  }

  /// Restart from a known zero state.
  void reset() noexcept { moduloCounter_ = phaseIncrement_.get() > 0 ? 0.0 : 1.0; }
  
  /// @returns current value of the oscillator
  T value() noexcept { return valueGenerator_(moduloCounter_); }
  
  /// @returns current value of the oscillator that is 90° ahead of what `value()` returns
  T quadPhaseValue() const noexcept { return valueGenerator_(quadPhaseCounter_); }

  /// @returns current value of the oscillator that is 90° behind what `value()` returns
  T negativeQuadPhaseValue() const noexcept {
    return valueGenerator_(wrappedModuloCounter(quadPhaseCounter_ - 5.0, phaseIncrement_));
  }

  /**
   Increment the oscillator to the next value.
   */
  void increment() noexcept {
    moduloCounter_ = incrementModuloCounter(moduloCounter_, phaseIncrement_.frameValue());
    quadPhaseCounter_ = incrementModuloCounter(moduloCounter_, 0.25);
  }

   /// @returns current frequency in Hz
  T frequency() const noexcept { return phaseIncrement_.get() * sampleRate_; }

  /// @returns the current waveform in effect for the LFO
  LFOWaveform waveform() const noexcept {
    if (valueGenerator_ == sineValue) return LFOWaveform::sinusoid;
    if (valueGenerator_ == sawtoothValue) return LFOWaveform::sawtooth;
    if (valueGenerator_ == triangleValue) return LFOWaveform::triangle;
    if (valueGenerator_ == squareValue) return LFOWaveform::square;
    assert(false);
  }

  /**
   Stop any ramping that is active for the LFO frequency.
   */
  void stopRamping() noexcept { phaseIncrement_.stopRamping(); }

private:
  using ValueGenerator = T (*)(T);
  
  static ValueGenerator WaveformGenerator(LFOWaveform waveform) noexcept {
    switch (waveform) {
      case LFOWaveform::sinusoid: return sineValue;
      case LFOWaveform::sawtooth: return sawtoothValue;
      case LFOWaveform::triangle: return triangleValue;
      case LFOWaveform::square: return squareValue;
    }
    assert(false);
  }

  static T wrappedModuloCounter(T counter, T inc) noexcept {
    if (inc > 0 && counter >= 1.0) return counter - 1.0;
    if (inc < 0 && counter <= 0.0) return counter + 1.0;
    return counter;
  }

  static T incrementModuloCounter(T counter, T inc) noexcept { return wrappedModuloCounter(counter + inc, inc); }

  static T sineValue(T counter) noexcept { return DSP::parabolicSine(M_PI - counter * 2.0 * M_PI); }
  static T sawtoothValue(T counter) noexcept { return DSP::unipolarToBipolar(counter); }
  static T triangleValue(T counter) noexcept {
    return DSP::unipolarToBipolar(std::abs(DSP::unipolarToBipolar(counter)));
  }
  static T squareValue(T counter) noexcept { return counter >= 0.5 ? 1.0 : -1.0; }

  T sampleRate_;
  ValueGenerator valueGenerator_;
  T moduloCounter_ = {0.0};
  T quadPhaseCounter_ = {0.25};
  Parameters::RampingParameter<T> phaseIncrement_;
};

} // end namespace DSPHeaders
