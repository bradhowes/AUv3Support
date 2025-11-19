// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/LFO.hpp"

using namespace DSPHeaders;

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

@interface LFOTests : XCTestCase
@property float epsilon;
@end

@implementation LFOTests

- (void)setUp {
  _epsilon = 0.0001;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSinusoidSamples {
  AUValue sampleRate{4.0};
  Parameters::Float freq{1, 1.0};
  LFO<AUValue> osc(freq, sampleRate, LFOWaveform::sinusoid);
  XCTAssertEqual(LFOWaveform::sinusoid, osc.waveform());

  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
}

- (void)testSawtoothSamples {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 8.0, LFOWaveform::sawtooth);
  XCTAssertEqual(LFOWaveform::sawtooth, osc.waveform());

  SamplesEqual(osc.value(), -1.00);
  osc.increment();
  SamplesEqual(osc.value(), -0.75);
  osc.increment();
  SamplesEqual(osc.value(), -0.50);
  osc.increment();
  SamplesEqual(osc.value(), -0.25);
  osc.increment();
  SamplesEqual(osc.value(),  0.00);
  osc.increment();
  SamplesEqual(osc.value(),  0.25);
  osc.increment();
  SamplesEqual(osc.value(),  0.50);
  osc.increment();
  SamplesEqual(osc.value(),  0.75);
  osc.increment();
  SamplesEqual(osc.value(), -1.00);
}

- (void)testTriangleSamples {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 8.0, LFOWaveform::triangle);
  XCTAssertEqual(LFOWaveform::triangle, osc.waveform());

  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.5);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(), -0.5);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(), -0.5);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.5);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
}

- (void)testQuadPhaseSamples {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 8.0, LFOWaveform::sawtooth);
  XCTAssertEqual(LFOWaveform::sawtooth, osc.waveform());

  SamplesEqual(osc.value(), -1.00);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(), -0.250);
  SamplesEqual(osc.quadPhaseValue(), -0.250);
  SamplesEqual(osc.value(), -0.75);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(),  0.00);
  SamplesEqual(osc.value(), -0.50);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(),  0.25);
  SamplesEqual(osc.value(), -0.25);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(),  0.50);
  SamplesEqual(osc.value(),  0.00);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(),  0.75);
  SamplesEqual(osc.value(),  0.25);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(), -1.00);
  SamplesEqual(osc.value(),  0.50);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(), -0.75);
  SamplesEqual(osc.value(),  0.75);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(), -0.50);
  SamplesEqual(osc.value(), -1.00);
  osc.increment();
  SamplesEqual(osc.quadPhaseValue(), -0.25);
}

- (void)testSquareSamples {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 8.0, LFOWaveform::square);
  XCTAssertEqual(LFOWaveform::square, osc.waveform());

  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(), -1.0);
}

- (void)testInContainer {
  std::vector<LFO<float>> lfos;
  // lfos.emplace_back(44100.0, 12.0, LFOWaveform::sinusoid);
}

- (void)testSetSinePhase {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 4.0, LFOWaveform::sinusoid);
  SamplesEqual(osc.value(),  0.0);
  osc.setPhase(0.25);
  SamplesEqual(osc.value(),  1.0);
  osc.setPhase(0.50);
  SamplesEqual(osc.value(),  0.0);
  osc.setPhase(0.75);
  SamplesEqual(osc.value(), -1.0);
}

- (void)testSetSawtoothPhase {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 4.0, LFOWaveform::sawtooth);
  SamplesEqual(osc.value(), -1.0);
  osc.setPhase(0.25);
  SamplesEqual(osc.value(), -0.5);
  osc.setPhase(0.50);
  SamplesEqual(osc.value(),  0.0);
  osc.setPhase(0.75);
  SamplesEqual(osc.value(),  0.5);
}

- (void)testSetTrianglePhase {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 4.0, LFOWaveform::triangle);
  SamplesEqual(osc.value(),  1.0);
  osc.setPhase(0.25);
  SamplesEqual(osc.value(),  0.0);
  osc.setPhase(0.50);
  SamplesEqual(osc.value(), -1.0);
  osc.setPhase(0.75);
  SamplesEqual(osc.value(),  0.0);
}

- (void)testSetSquarePhase {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 4.0, LFOWaveform::square);
  SamplesEqual(osc.value(), -1.0);
  osc.setPhase(0.25);
  SamplesEqual(osc.value(), -1.0);
  osc.setPhase(0.50);
  SamplesEqual(osc.value(),  1.0);
  osc.setPhase(0.75);
  SamplesEqual(osc.value(),  1.0);
}

- (void)testSaveRestorePhase {
  Parameters::Float freq{1, 1.0};
  LFO<float> osc(freq, 16.0, LFOWaveform::triangle);
  SamplesEqual(osc.value(),  1.0);
  osc.increment();
  SamplesEqual(osc.value(),  0.75);
  auto saved = osc.phase();
  osc.increment();
  SamplesEqual(osc.value(),  0.50);
  osc.setPhase(saved);
  SamplesEqual(osc.value(),  0.75);
  osc.increment();
  SamplesEqual(osc.value(),  0.50);
  osc.setPhase(saved + 1.0);
  SamplesEqual(osc.value(),  0.75);
  osc.increment();
  SamplesEqual(osc.value(),  0.50);
}

- (void)testFrequencyChangeRamping {
  AUValue sampleRate{16.0};
  Parameters::Float freq{1, 1.0};
  LFO<AUValue> osc(freq, sampleRate, LFOWaveform::sinusoid);
  XCTAssertEqual(LFOWaveform::sinusoid, osc.waveform());

  SamplesEqual(osc.value(), 0.0);
  osc.increment();
  SamplesEqual(osc.value(), 0.382683);
  osc.increment();
  SamplesEqual(osc.value(), 0.707107);
  osc.increment();
  SamplesEqual(osc.value(), 0.923889);
  osc.increment();
  SamplesEqual(osc.value(), 1.000000);
  osc.increment();
  SamplesEqual(osc.value(), 0.923880);
  osc.increment();
  SamplesEqual(osc.value(), 0.707107);
  osc.increment();
  SamplesEqual(osc.value(), 0.382683);
  osc.increment();
  SamplesEqual(osc.value(),  0.0);
  freq.setImmediate(2.0, 4);
  osc.increment();
  SamplesEqual(osc.value(), -0.471397);
  osc.increment();
  SamplesEqual(osc.value(), -0.831470);
  osc.increment();
  SamplesEqual(osc.value(), -0.995185);
  osc.increment();
  SamplesEqual(osc.value(), -0.923880);
  osc.increment();
  SamplesEqual(osc.value(), -0.634393);
  osc.increment();
  SamplesEqual(osc.value(), -0.195090);
}


@end
