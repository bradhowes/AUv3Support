// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/PercentageParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface PercentageParameterTests : XCTestCase

@end

@implementation PercentageParameterTests {
  float epsilon;
};

- (void)setUp {
  epsilon = 1.0e-8;
}

- (void)tearDown {
}

- (void)testInit {
  auto param = PercentageParameter<float>();
  XCTAssertFalse(param.isRamping());
  XCTAssertEqual(param.get(), 0.0);

  param = PercentageParameter<float>(100.0);
  XCTAssertFalse(param.isRamping());
  XCTAssertEqualWithAccuracy(param.get(), 100.0, epsilon);
}

- (void)testRepresentation {
  auto param = PercentageParameter<float>(50.0);
  XCTAssertEqual(param.get(), 50.0);
  XCTAssertEqual(param.normalized(), 0.5);

  param.set(25.0, 10);
  XCTAssertEqual(param.get(), 25.0);
  XCTAssertEqual(param.normalized(), 0.25);

  XCTAssertEqualWithAccuracy(param.frameValue(), (50.0 - 2.5) / 100.0, epsilon);
}

@end
