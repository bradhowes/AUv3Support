// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/IntegralParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface IntegralParameterTests : XCTestCase

@end

@implementation IntegralParameterTests {
  float epsilon;
};

- (void)tearDown {
}

- (void)testInit {
  XCTAssertEqual(Integral().get(), 0.0);
  XCTAssertEqual(Integral(0.0).get(), 0.0);
  XCTAssertEqual(Integral(0.25).get(), 0.0);
  XCTAssertEqual(Integral(0.5).get(), 1.0);
  XCTAssertEqual(Integral(0.9).get(), 1.0);
  XCTAssertEqual(Integral(1.0).get(), 1.0);
  XCTAssertEqual(Integral(-0.25).get(), 0.0);
  XCTAssertEqual(Integral(-0.5).get(), -1.0);
}

- (void)testSetting {
  auto param = Integral();

  param.set(-1.0, 0);
  XCTAssertEqual(param.get(), -1.0);

  param.set(1.0, 0);
  XCTAssertEqual(param.get(), 1.0);

  param.set(0.1, 0);
  XCTAssertEqual(param.get(), 0.0);

  param.set(1.9, 0);
  XCTAssertEqual(param.get(), 2.0);
}

@end
