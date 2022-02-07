// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "../../Sources/DSPHeaders/include/LFO.hpp"

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
  LFO<float> osc(4.0, 1.0, LFOWaveform::sinusoid);
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
  LFO<float> osc(8.0, 1.0, LFOWaveform::sawtooth);
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
  LFO<float> osc(8.0, 1.0, LFOWaveform::triangle);
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
  LFO<float> osc(8.0, 1.0, LFOWaveform::sawtooth);
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

@end