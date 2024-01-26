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
  XCTAssertEqual(param1.get(), 0.0);
  XCTAssertEqual(param1.getPending(), 0.0);
  XCTAssertFalse(param1);

  auto param2 = BoolParameter(true);
  XCTAssertEqual(param2.get(), 1.0);
  XCTAssertEqual(param2.getPending(), 1.0);
  XCTAssertTrue(param2);
}

- (void)testSetting {
  auto param = BoolParameter();

  param.setPending(-1.0);
  XCTAssertEqual(param.get(), 0.0);
  XCTAssertFalse(param);
  XCTAssertEqual(param.getPending(), 1.0);

  param.set(123.0, 0);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);
  XCTAssertEqual(param.getPending(), 1.0);

  param.set(0.1, 0);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param);

  param.set(0.0, 0);
  XCTAssertEqual(param.get(), 0.0);
  XCTAssertFalse(param);
}

@end
