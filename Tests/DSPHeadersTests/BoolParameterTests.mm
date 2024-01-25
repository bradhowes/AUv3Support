// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/BoolParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface BoolParameterTests : XCTestCase

@end

@implementation BoolParameterTests {
  float epsilon;
};

- (void)setUp {
  epsilon = 1.0e-8;
}

- (void)tearDown {
}

- (void)testInit {
  auto param1 = BoolParameter();
  XCTAssertEqual(param1.getSafe(), 0.0);
  XCTAssertEqual(param1.getUnsafe(), 0.0);
  XCTAssertFalse(param1);

  auto param2 = BoolParameter(true);
  XCTAssertEqual(param2.getSafe(), 1.0);
  XCTAssertEqual(param2.getUnsafe(), 1.0);
  XCTAssertTrue(param2);
}

- (void)testSetting {
  auto param = BoolParameter();

  param.setUnsafe(-1.0);
  XCTAssertEqual(param.getSafe(), 0.0);
  XCTAssertFalse(param);
  XCTAssertEqual(param.getUnsafe(), 1.0);

  param.setSafe(123.0);
  XCTAssertEqual(param.getSafe(), 1.0);
  XCTAssertTrue(param);
  XCTAssertEqual(param.getUnsafe(), 1.0);

  param.setSafe(0.1);
  XCTAssertEqual(param.getSafe(), 1.0);
  XCTAssertTrue(param);

  param.setSafe(0.0);
  XCTAssertEqual(param.getSafe(), 0.0);
  XCTAssertFalse(param);
}

@end
