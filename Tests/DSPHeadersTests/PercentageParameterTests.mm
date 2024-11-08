// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/Percentage.hpp"

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
  auto param1 = Percentage();
  XCTAssertEqual(param1.getImmediate(), 0.0);

  auto param2 = Percentage(100.0);
  XCTAssertEqualWithAccuracy(param2.getImmediate(), 1.0, epsilon);
}

- (void)testRepresentation {
  auto param = Percentage(50.0);
  XCTAssertEqual(param.getImmediate(), 0.5);
  XCTAssertEqual(param.frameValue(), 0.5);

  param.setPending(25.0);
  XCTAssertEqual(param.getPending(), 25.0);
  XCTAssertEqual(param.getImmediate(), 0.5);
  param.setImmediate(16, 0);
  XCTAssertEqualWithAccuracy(param.frameValue(), 0.16, epsilon);
}

@end
