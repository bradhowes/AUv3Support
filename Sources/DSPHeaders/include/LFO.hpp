// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <cmath>

#import "DSP.hpp"
#import "RampingParameter.hpp"

enum class LFOWaveform { sinusoid, triangle, sawtooth, square};

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
  LFO(T sampleRate, T frequency, LFOWaveform waveform)
  : valueGenerator_{WaveformGenerator(waveform)}, sampleRate_{sampleRate}, waveform_{waveform}
  {
    setFrequency(frequency, 0);
    reset();
  }
  
  /**
   Create a new instance.
   */
  LFO(T sampleRate, T frequency) : LFO(sampleRate, frequency, LFOWaveform::sinusoid) {}

  /**
   Create a new instance.
   */
  LFO() : LFO(44100.0, 1.0, LFOWaveform::sinusoid) {}
  
  /**
   Initialize the LFO with the given parameters.
   
   @param sampleRate number of samples per second
   @param frequency the frequency of the oscillator
   */
  void setSampleRate(T sampleRate) {

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
  void setWaveform(LFOWaveform waveform) {
    waveform_ = waveform;
    valueGenerator_ = WaveformGenerator(waveform);
  }
  
  /**
   Set the frequency of the oscillator.
   
   @param frequency the frequency to operate at
   */
  void setFrequency(T frequency, AUAudioFrameCount duration) {
    assert(sampleRate_ != 0.0);
    phaseIncrement_.set(frequency / sampleRate_, duration);
  }

  /**
   Restart from a known zero state.
   */
  void reset() {
    moduloCounter_ = phaseIncrement_.get() > 0 ? 0.0 : 1.0;
  }
  
  /**
   Obtain the current value of the oscillator.
   
   @returns current waveform value
   */
  T value() { return valueGenerator_(moduloCounter_); }
  
  /**
   Obtain the current value of the oscillator that is 90° advanced from what `value()` would return.
   
   @returns current 90° advanced waveform value
   */
  T quadPhaseValue() const { return valueGenerator_(quadPhaseCounter_); }
  
  /**
   Increment the oscillator to the next value.
   */
  void increment() {
    moduloCounter_ = incrementModuloCounter(moduloCounter_, phaseIncrement_.frameValue());
    quadPhaseCounter_ = incrementModuloCounter(moduloCounter_, 0.25);
  }

  /**
   Obtain the current frequency of the LFO.

   @return frequency in Hz
   */
  T frequency() const { return phaseIncrement_.get() * sampleRate_; }

  LFOWaveform waveform() const { return waveform_; }

private:
  using ValueGenerator = std::function<T(T)>;
  
  static ValueGenerator WaveformGenerator(LFOWaveform waveform) {
    switch (waveform) {
      case LFOWaveform::sinusoid: return sineValue;
      case LFOWaveform::sawtooth: return sawtoothValue;
      case LFOWaveform::triangle: return triangleValue;
      case LFOWaveform::square: return squareValue;
    }
  }

  static double wrappedModuloCounter(T counter, T inc) {
    if (inc > 0 && counter >= 1.0) return counter - 1.0;
    if (inc < 0 && counter <= 0.0) return counter + 1.0;
    return counter;
  }

  static T incrementModuloCounter(T counter, T inc) { return wrappedModuloCounter(counter + inc, inc); }
  static T sineValue(T counter) { return DSP::parabolicSine(M_PI - counter * 2.0 * M_PI); }
  static T sawtoothValue(T counter) { return DSP::unipolarToBipolar(counter); }
  static T triangleValue(T counter) { return DSP::unipolarToBipolar(std::abs(DSP::unipolarToBipolar(counter))); }
  static T squareValue(T counter) { return counter >= 0.5 ? 1.0 : -1.0; }

  T sampleRate_;
  std::function<T(T)> valueGenerator_;
  T moduloCounter_ = {0.0};
  T quadPhaseCounter_ = {0.25};
  RampingParameter<T> phaseIncrement_;
  LFOWaveform waveform_;
};
