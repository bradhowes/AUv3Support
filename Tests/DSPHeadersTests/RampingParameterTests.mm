// Copyright © 2021, 2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/Parameters/Float.hpp"

using namespace DSPHeaders::Parameters;

@interface RampingParameterTests : XCTestCase
@end

@implementation RampingParameterTests {
  AUValue epsilon;
}

- (void)setUp {
  epsilon = 1.0e-4;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInit {
  auto param1 = Float();
  XCTAssertEqual(param1.get(), 0.0);

  auto param2 = Float(AUValue(12.34));
  XCTAssertEqualWithAccuracy(param2.get(), 12.34, 1.0e-6);
}

- (void)testRamping {
  auto param = Float();
  param.set(1.0, 4);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.50);
  XCTAssertEqual(param.frameValue(), 0.75);
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertEqual(param.get(), 1.0);
}

- (void)testReRamping {
  auto param = Float();
  param.set(1.0, 4);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.frameValue(), 0.50);
  param.set(0.0, 4);
  XCTAssertEqual(param.frameValue(), 0.375);
  XCTAssertEqual(param.frameValue(), 0.250);
  XCTAssertEqual(param.frameValue(), 0.125);
  XCTAssertEqual(param.frameValue(), 0.000);
  XCTAssertEqual(param.get(), 0.0);
}

- (void)testStopRamping {
  auto param = Float();
  param.set(1.0, 4);
  XCTAssertEqual(param.get(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.get(), 1.0);
  param.stopRamping();
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertEqual(param.get(), 1.0);
}

- (void)testAdvanceControl {
  auto param = Float();
  param.set(1.0, 4);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.frameValue(false), 0.25);
  XCTAssertEqual(param.frameValue(), 0.50);
  XCTAssertEqual(param.frameValue(false), 0.50);
  XCTAssertEqual(param.frameValue(false), 0.50);
  XCTAssertEqual(param.frameValue(true), 0.75);
}

- (void)testPending {
  auto param = Float();
  param.setPending(124.0);
  XCTAssertEqualWithAccuracy(param.getPending(), 124.0, epsilon);
  XCTAssertEqualWithAccuracy(param.get(), 0.0, epsilon);
  param.checkForChange(20);
  XCTAssertEqualWithAccuracy(param.get(), 124.0, epsilon);
  XCTAssertEqualWithAccuracy(param.frameValue(), 124.0 / 20.0, epsilon);
}

@end
