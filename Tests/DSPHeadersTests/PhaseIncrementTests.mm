// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/LFO.hpp"

using namespace DSPHeaders;

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

@interface PhaseIncrementTests : XCTestCase
@property float epsilon;
@end

@implementation PhaseIncrementTests

- (void)setUp {
  _epsilon = 0.0001;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  AUValue sampleRate{4.0};
  Parameters::Float freq{1, 1.0};
  PhaseIncrement<AUValue> phi{freq, sampleRate};
  SamplesEqual(phi.value(), 0.25);
}

- (void)testRamping {
  AUValue sampleRate{4.0};
  Parameters::Float freq{1, 1.0};

  PhaseIncrement<AUValue> phi{freq, sampleRate};
  SamplesEqual(phi.value(), 0.25);

  freq.setImmediate(2.0, 2);
  SamplesEqual(phi.value(), 0.375);
  freq.checkForValueChange(2);
  SamplesEqual(phi.value(), 0.5);
  freq.checkForValueChange(2);
  SamplesEqual(phi.value(), 0.5);
}

@end
