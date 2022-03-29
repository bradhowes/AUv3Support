// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <algorithm>
#import <array>

#import "Biquad.hpp"
#import "DSP.hpp"

namespace DSPHeaders {

/**
 Generates a phase-shift audio effect as described in "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019).
 The shifter is made up of 6 all-pass filters with different, overlapping frequency bands. The operation of the filter
 follows that of Pirkle's documentation and code, but below is a more modern C++ take on it.
 
 There should be one instance of a PhaseShifter per one channel of audio, with all instances sharing the same LFO that
 modulates their frequency bands.
 */
template <typename T>
class PhaseShifter {
public:
  using AllPassFilter = Biquad::CanonicalTranspose<T>;
  
  /// Definition of a frequency band with min and max values
  struct Band {
    T frequencyMin;
    T frequencyMax;
  };

  inline static constexpr size_t BandCount = 6;

  /// Definition of a collection of frequency bands
  using FrequencyBands = std::array<Band, BandCount>;
  
  /// Collection of frequency bands based on Pirkle's ideal.
  inline static FrequencyBands ideal{
    16.0, 1600.0,
    33.0, 3300.0,
    48.0, 4800.0,
    98.0, 9800.0,
    160.0, 16000.0,
    260.0, 20480.0
  };
  
  /// Collection of frequency bands based on National Semiconductor paper and Pirkle's interpretation.
  inline static FrequencyBands nationalSemiconductor{
    32.0, 1500.0,
    68.0, 3400.0,
    96.0, 4800.0,
    212.0, 10000.0,
    320.0, 16000.0,
    636.0, 20480.0
  };
  
  /**
   Construct new phase-shift operator.
   
   @param bands the frequency bands to operate over
   @param sampleRate the sample rate to work with
   @param intensity a "gain" value that is applied to final filter value
   @param samplesPerFilterUpdate number of sample values to emit before updating the filter parameters
   */
  PhaseShifter(const FrequencyBands& bands, T sampleRate, T intensity, int samplesPerFilterUpdate = 10) noexcept
  : bands_(bands), sampleRate_{sampleRate}, intensity_{intensity}, samplesPerFilterUpdate_{samplesPerFilterUpdate}
  {
    updateCoefficients(0.0);
  }
  
  /**
   Set the intensity (gain) value.
   
   @param intensity new value to use
   */
  void setIntensity(double intensity) noexcept { intensity_ = intensity; }
  
  /**
   Reset the audio processor.
   */
  void reset() noexcept {
    sampleCounter_ = 0;
    for (auto& filter : filters_) {
      filter.reset();
    }
  }
  
  /**
   Generate a new audio sample
   
   @param modulation the modulation amount to apply to the filter coefficients
   @param input the audio input signal to inject into the filters
   @returns filtered audio output
   */
  T process(T modulation, T input) noexcept {
    
    // With samplersPerFilterUpdate_ == 1, this replicates the phaser processing described in
    // "Designing Audio Effect Plugins in C++" by Will C. Pirkle (2019).
    //
    if (sampleCounter_++ >= samplesPerFilterUpdate_) {
      updateCoefficients(modulation);
      sampleCounter_ = 1;
    }
    
    // Calculate gamma values from the individual filters.
    for (auto index = 1; index <= filters_.size(); ++index) {
      gammas_[index] = filters_[filters_.size() - index].gainValue() * gammas_[index - 1];
    }
    
    // Calculate weighted state sum of past values to mix with input
    T weightedSum = 0.0;
    for (auto index = 0; index < filters_.size(); ++index) {
      weightedSum += gammas_[filters_.size() - index - 1] * filters_[index].storageComponent();
    }
    
    // Finally, apply the filters in series
    T output = (input + intensity_ * weightedSum) / (1.0 + intensity_ * gammas_.back());
    for (auto& filter : filters_) {
      output = filter.transform(output);
    }
    
    return output;
  }
  
private:
  
  void updateCoefficients(T modulation) noexcept {
    assert(filters_.size() == bands_.size());
    for (auto index = 0; index < filters_.size(); ++index) {
      auto const& band = bands_[index];
      double frequency = DSP::bipolarModulation(modulation, band.frequencyMin, band.frequencyMax);
      filters_[index].setCoefficients(Biquad::Coefficients<T>::APF1(sampleRate_, frequency));
    }
  }
  
  const FrequencyBands& bands_;
  T sampleRate_;
  T intensity_;
  int samplesPerFilterUpdate_;
  int sampleCounter_{0};
  std::array<AllPassFilter, BandCount> filters_{};
  std::array<T, BandCount + 1> gammas_{1.0};
  
  os_log_t log_ = os_log_create("AUv3Support", "PhaseShifter");
};

} // end namespace DSPHeaders
