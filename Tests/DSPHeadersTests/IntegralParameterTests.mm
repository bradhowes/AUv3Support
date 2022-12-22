// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/IntegralParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface IntegralParameterTests : XCTestCase

@end

@implementation IntegralParameterTests {
  float epsilon;
};

- (void)tearDown {
}

- (void)testInit {
  XCTAssertEqual(IntegralParameter().get(), 0.0);
  XCTAssertEqual(IntegralParameter(0.0).get(), 0.0);
  XCTAssertEqual(IntegralParameter(0.25).get(), 0.0);
  XCTAssertEqual(IntegralParameter(0.5).get(), 1.0);
  XCTAssertEqual(IntegralParameter(0.9).get(), 1.0);
  XCTAssertEqual(IntegralParameter(1.0).get(), 1.0);
  XCTAssertEqual(IntegralParameter(-0.25).get(), 0.0);
  XCTAssertEqual(IntegralParameter(-0.5).get(), -1.0);
}

- (void)testSetting {
  auto param = IntegralParameter();

  param.set(-1.0);
  XCTAssertEqual(param.get(), -1.0);

  param.set(1.0);
  XCTAssertEqual(param.get(), 1.0);

  param.set(0.1);
  XCTAssertEqual(param.get(), 0.0);

  param.set(1.9);
  XCTAssertEqual(param.get(), 2.0);
}

@end
