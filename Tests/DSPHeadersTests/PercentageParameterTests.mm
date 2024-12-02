// Copyright © 2021-2024 Brad Howes. All rights reserved.

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
  auto param1 = Percentage(1);
  XCTAssertEqual(param1.getImmediate(), 0.0);

  auto param2 = Percentage(2, 100.0);
  XCTAssertEqualWithAccuracy(param2.getImmediate(), 100.0, epsilon);

  enum class Foo { bar = 0 };
  auto param3 = Percentage(Foo::bar, 12.5);
  XCTAssertEqual(param3.getImmediate(), 12.5);
}

- (void)testRepresentation {
  auto param = Percentage(3, 50.0);
  XCTAssertEqual(param.getImmediate(), 50.0);
  XCTAssertEqual(param.frameValue(), 0.5);

  param.setPending(25.0);
  XCTAssertEqual(param.getPending(), 25.0);
  XCTAssertEqual(param.getImmediate(), 50.0);
  XCTAssertEqual(param.frameValue(), 0.5);

  XCTAssertTrue(param.checkForPendingChange(4));
  XCTAssertEqual(param.frameValue(), 0.437500);
  XCTAssertEqual(param.frameValue(), 0.375000);

  param.setImmediate(16, 0);
  XCTAssertEqualWithAccuracy(param.frameValue(), 0.16, epsilon);
}

@end
