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
  XCTAssertEqual(IntegralParameter().getSafe(), 0.0);
  XCTAssertEqual(IntegralParameter(0.0).getSafe(), 0.0);
  XCTAssertEqual(IntegralParameter(0.25).getSafe(), 0.0);
  XCTAssertEqual(IntegralParameter(0.5).getSafe(), 1.0);
  XCTAssertEqual(IntegralParameter(0.9).getSafe(), 1.0);
  XCTAssertEqual(IntegralParameter(1.0).getSafe(), 1.0);
  XCTAssertEqual(IntegralParameter(-0.25).getSafe(), 0.0);
  XCTAssertEqual(IntegralParameter(-0.5).getSafe(), -1.0);
}

- (void)testSetting {
  auto param = IntegralParameter();

  param.setSafe(-1.0, 0);
  XCTAssertEqual(param.getSafe(), -1.0);

  param.setSafe(1.0, 0);
  XCTAssertEqual(param.getSafe(), 1.0);

  param.setSafe(0.1, 0);
  XCTAssertEqual(param.getSafe(), 0.0);

  param.setSafe(1.9, 0);
  XCTAssertEqual(param.getSafe(), 2.0);
}

@end
