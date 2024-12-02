// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/Milliseconds.hpp"

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
  auto param1 = Milliseconds(1);
  XCTAssertEqual(param1.getImmediate(), 0.0);

  auto param2 = Milliseconds(2, 123.4);
  XCTAssertEqualWithAccuracy(param2.getImmediate(), 123.4, epsilon);

  enum class Foo { bar = 0 };
  auto param3 = Milliseconds(Foo::bar, 123.5);
  XCTAssertEqual(param3.getImmediate(), 123.5);
}

@end
