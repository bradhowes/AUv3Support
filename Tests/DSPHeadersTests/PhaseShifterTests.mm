// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "Pirkle/fxobjects.h"
#import "DSPHeaders/LFO.hpp"
#import "DSPHeaders/PhaseShifter.hpp"

using namespace DSPHeaders;

@interface PhaseShifterTests : XCTestCase
@property float epsilon;
@end

@implementation PhaseShifterTests

- (void)setUp {
  _epsilon = 1.0e-5;
  self.continueAfterFailure = false;
}

- (void)tearDown {
}

// Compare the output from Will Pirkle's implementation and our own to make sure we have not messed anything up. The
// test data consists of a simple sin wave.

- (void)testPhaseShifters {
  double sampleRate = 44100.0;
  AUValue lfoFrequency = 0.2;
  Pirkle::PhaseShifter phaseShifterOld;
  phaseShifterOld.reset(sampleRate);

  auto params = phaseShifterOld.getParameters();
  params.intensity_Pct = 100.0;
  params.lfoDepth_Pct = 100.0;
  params.lfoRate_Hz = lfoFrequency;
  params.quadPhaseLFO = false;
  phaseShifterOld.setParameters(params);

  Parameters::Float freq{1, lfoFrequency};
  LFO<double> lfo(freq, sampleRate, LFOWaveform::triangle);
  PhaseShifter<double> phaseShifterNew{PhaseShifter<double>::ideal, sampleRate, 1.0, 1};

  // Generate a 440 Hz (A4) note:
  // - 44100.0 samples/s divided by 440 ~= 100 samples / cycle
  // - Do for 100 cycles or 10_000 samples or ~ 1/4 second of audio to compare

  for (int cycle = 0; cycle < 100; ++cycle) {
    for (int sample = 0; sample < 100; ++sample) {
      double input = std::sin(sample / 100.0 * M_PI * 2.0);
      double output1 = phaseShifterOld.processAudioSample(input);
      double modulator = lfo.value();
      lfo.increment();
      double output2 = phaseShifterNew.process(modulator, input);
      XCTAssertEqualWithAccuracy(output1, output2, _epsilon);
    }
  }
}

- (void)testPhaseShifterThroughput {
  [self measureMetrics: XCTestCase.defaultPerformanceMetrics automaticallyStartMeasuring:false forBlock:^{
    double sampleRate = 44100.0;

    Parameters::Float freq{1, 0.2};
    LFO<double> lfo(freq, sampleRate, LFOWaveform::triangle);
    PhaseShifter<double> phaseShifterNew{PhaseShifter<double>::ideal, sampleRate, 1.0, 1};

    // Generate a 440 Hz (A4) note:
    // - 44100.0 samples/s divided by 440 ~= 100 samples / cycle
    // - Do for 100 cycles or 10_000 samples or ~ 1/4 second of audio to compare
    [self startMeasuring];
    for (int cycle = 0; cycle < 100 * 4; ++cycle) {
      for (int sample = 0; sample < 100; ++sample) {
        double input = std::sin(sample / 100.0 * M_PI * 2.0);
        double modulator = lfo.value();
        lfo.increment();
        double output = phaseShifterNew.process(modulator, input);
      }
    }
    [self stopMeasuring];
  }];
}

@end
