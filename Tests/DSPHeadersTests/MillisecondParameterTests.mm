// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/MillisecondsParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface MillisecondsParameterTests : XCTestCase

@end

@implementation MillisecondsParameterTests {
  float epsilon;
};

- (void)setUp {
  epsilon = 1.0e-5;
}

- (void)tearDown {
}

- (void)testInit {
  auto param1 = MillisecondsParameter();
  XCTAssertEqual(param1.getSafe(), 0.0);

  auto param2 = MillisecondsParameter(123.4);
  XCTAssertEqualWithAccuracy(param2.getSafe(), 123.4, epsilon);
}

@end
