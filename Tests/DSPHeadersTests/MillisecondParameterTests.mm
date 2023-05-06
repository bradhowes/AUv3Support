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
  epsilon = 1.0e-8;
}

- (void)tearDown {
}

- (void)testInit {
  auto param = MillisecondsParameter<double>();
  XCTAssertEqual(param.get(), 0.0);

  param = MillisecondsParameter(123.4);
  XCTAssertEqualWithAccuracy(param.get(), 123.4, epsilon);
}

@end
