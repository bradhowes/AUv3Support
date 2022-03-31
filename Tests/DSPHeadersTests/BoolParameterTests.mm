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
  auto param = BoolParameter();
  XCTAssertEqual(param.get(), 0.0);
  XCTAssertFalse(param);

  param = BoolParameter(true);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);
}

- (void)testSetting {
  auto param = BoolParameter();

  param.set(-1.0);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);

  param.set(1123.0);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);

  param.set(0.1);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);

  param.set(0.0);
  XCTAssertEqual(param.get(), 0.0);
  XCTAssertFalse(param);
}

@end
