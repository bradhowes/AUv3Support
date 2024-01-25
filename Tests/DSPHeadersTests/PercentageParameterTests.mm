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
  auto param1 = PercentageParameter();
  XCTAssertEqual(param1.getSafe(), 0.0);

  auto param2 = PercentageParameter(100.0);
  XCTAssertEqualWithAccuracy(param2.getUnsafe(), 100.0, epsilon);
}

- (void)testRepresentation {
  auto param = PercentageParameter(50.0);
  XCTAssertEqual(param.getSafe(), 0.5);
  XCTAssertEqual(param.frameValue(), 0.5);

  param.setSafe(25.0, 0);
  XCTAssertEqual(param.getUnsafe(), 25.0);
  XCTAssertEqual(param.getSafe(), 0.25);
  XCTAssertEqual(param.frameValue(), 0.25);

  XCTAssertEqualWithAccuracy(param.frameValue(), 0.25, epsilon);
}

@end
