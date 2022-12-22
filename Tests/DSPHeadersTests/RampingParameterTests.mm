// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/RampingParameter.hpp"

using namespace DSPHeaders::Parameters;

@interface RampingParameterTests : XCTestCase

@end

@implementation RampingParameterTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  auto param = RampingParameter();
  XCTAssertFalse(param.isRamping());
  XCTAssertEqual(param.get(), 0.0);

  param = RampingParameter(AUValue(12.34));
  XCTAssertFalse(param.isRamping());
  XCTAssertEqualWithAccuracy(param.get(), 12.34, 1.0e-6);
}

- (void)testRamping {
  auto param = RampingParameter();
  param.set(1.0, 4);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 0.50);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 0.75);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertFalse(param.isRamping());
  XCTAssertEqual(param.get(), 1.0);
}

- (void)testReRamping {
  auto param = RampingParameter();
  param.set(1.0, 4);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.frameValue(), 0.50);
  param.set(0.0, 4);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 0.375);
  XCTAssertEqual(param.frameValue(), 0.250);
  XCTAssertEqual(param.frameValue(), 0.125);
  XCTAssertEqual(param.frameValue(), 0.000);
  XCTAssertFalse(param.isRamping());
  XCTAssertEqual(param.get(), 0.0);
}

- (void)testStopRamping {
  auto param = RampingParameter();
  param.set(1.0, 4);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertTrue(param.isRamping());
  param.stopRamping();
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertFalse(param.isRamping());
  XCTAssertEqual(param.get(), 1.0);
}

- (void)testAdvanceControl {
  auto param = RampingParameter();
  param.set(1.0, 4);
  XCTAssertTrue(param.isRamping());
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.frameValue(false), 0.25);
  XCTAssertEqual(param.frameValue(), 0.50);
  XCTAssertEqual(param.frameValue(false), 0.50);
  XCTAssertEqual(param.frameValue(false), 0.50);
  XCTAssertEqual(param.frameValue(true), 0.75);
}

@end
