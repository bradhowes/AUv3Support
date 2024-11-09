// Copyright © 2021 Brad Howes. All rights reserved.

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
  XCTAssertEqual(Integral().getImmediate(), 0.0);
  XCTAssertEqual(Integral(0.0).getImmediate(), 0.0);
  XCTAssertEqual(Integral(0.25).getImmediate(), 0.0);
  XCTAssertEqual(Integral(0.5).getImmediate(), 1.0);
  XCTAssertEqual(Integral(0.9).getImmediate(), 1.0);
  XCTAssertEqual(Integral(1.0).getImmediate(), 1.0);
  XCTAssertEqual(Integral(-0.25).getImmediate(), 0.0);
  XCTAssertEqual(Integral(-0.5).getImmediate(), -1.0);
}

- (void)testSetting {
  auto param = Integral();

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
