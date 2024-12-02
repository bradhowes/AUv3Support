// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/Integral.hpp"

using namespace DSPHeaders::Parameters;

@interface IntegralParameterTests : XCTestCase

@end

@implementation IntegralParameterTests {
  float epsilon;
};

- (void)tearDown {
}

- (void)testInit {
  XCTAssertEqual(Integral(1).getImmediate(), 0.0);
  XCTAssertEqual(Integral(2, 0.0).getImmediate(), 0.0);
  XCTAssertEqual(Integral(3, 0.25).getImmediate(), 0.0);
  XCTAssertEqual(Integral(4, 0.5).getImmediate(), 1.0);
  XCTAssertEqual(Integral(5, 0.9).getImmediate(), 1.0);
  XCTAssertEqual(Integral(6, 1.0).getImmediate(), 1.0);
  XCTAssertEqual(Integral(7, -0.25).getImmediate(), 0.0);
  XCTAssertEqual(Integral(8, -0.5).getImmediate(), -1.0);

  enum class Foo { bar = 0 };
  auto param3 = Integral(Foo::bar, 123);
  XCTAssertEqual(param3.getImmediate(), 123);
}

- (void)testSetting {
  auto param = Integral(1);

  param.setImmediate(-1.0, 0);
  XCTAssertEqual(param.getImmediate(), -1.0);

  param.setImmediate(1.0, 0);
  XCTAssertEqual(param.getImmediate(), 1.0);

  param.setImmediate(0.1, 0);
  XCTAssertEqual(param.getImmediate(), 0.0);

  param.setImmediate(1.9, 0);
  XCTAssertEqual(param.getImmediate(), 2.0);
}

@end
