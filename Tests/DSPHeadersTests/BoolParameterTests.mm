// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/Bool.hpp"

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
  auto param1 = Bool();
  XCTAssertEqual(param1.getImmediate(), 0.0);
  XCTAssertEqual(param1.getPending(), 0.0);
  XCTAssertFalse(param1);

  auto param2 = Bool(true);
  XCTAssertEqual(param2.getImmediate(), 1.0);
  XCTAssertEqual(param2.getPending(), 1.0);
  XCTAssertTrue(param2);
}

- (void)testSetting {
  auto param = Bool();

  param.setPending(-1.0);
  XCTAssertEqual(param.getImmediate(), 0.0);
  XCTAssertFalse(param);
  XCTAssertEqual(param.getPending(), 0.0);

  param.setImmediate(123.0, 0);
  XCTAssertEqual(param.getImmediate(), 1.0);
  XCTAssertTrue(param);
  XCTAssertEqual(param.getPending(), 1.0);

  param.setImmediate(0.1, 0);
  XCTAssertEqual(param.getImmediate(), 0.0);
  XCTAssertFalse(param);

  param.setImmediate(0.6, 0);
  XCTAssertEqual(param.getImmediate(), 1.0);
  XCTAssertTrue(param);

  param.setImmediate(-0.1, 0);
  XCTAssertEqual(param.getImmediate(), 0.0);
  XCTAssertFalse(param);

  param.setImmediate(-0.6, 0);
  XCTAssertEqual(param.getImmediate(), 0.0);
  XCTAssertFalse(param);

  param.setImmediate(0.0, 0);
  XCTAssertEqual(param.getImmediate(), 0.0);
  XCTAssertFalse(param);
}

@end
