// Copyright © 2021-2024, 2024 Brad Howes. All rights reserved.

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
  auto param1 = Float(1);
  XCTAssertEqual(param1.getImmediate(), 0.0);
  XCTAssertEqual(param1.address(), 1);
  auto param2 = Float(2, AUValue(12.34));
  XCTAssertEqualWithAccuracy(param2.getImmediate(), 12.34, 1.0e-6);
  XCTAssertEqual(param2.address(), 2);
}

- (void)testRamping {
  auto param = Float(2);
  AUAudioFrameCount rampDuration{4};
  param.setImmediate(1.0, rampDuration);
  XCTAssertEqual(param.getImmediate(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.getImmediate(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.5);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 0.75);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 1.0);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertEqual(param.getImmediate(), 1.0);
}

- (void)testReRamping {
  auto param = Float(3);
  AUAudioFrameCount rampDuration{4};
  param.setImmediate(1.0, rampDuration);
  XCTAssertEqual(param.frameValue(), 0.25);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 0.50);
  param.setImmediate(0.0, 4);
  XCTAssertEqual(param.frameValue(), 0.375);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 0.250);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 0.125);
  param.checkForValueChange(rampDuration);
  XCTAssertEqual(param.frameValue(), 0.000);
  XCTAssertEqual(param.getImmediate(), 0.0);
}

- (void)testStopRamping {
  auto param = Float(4);
  AUAudioFrameCount rampDuration{4};
  param.setImmediate(1.0, rampDuration);
  XCTAssertEqual(param.getImmediate(), 1.0);
  XCTAssertEqual(param.frameValue(), 0.25);
  XCTAssertEqual(param.getImmediate(), 1.0);
  param.stopRamping();
  XCTAssertEqual(param.frameValue(), 1.0);
  XCTAssertEqual(param.getImmediate(), 1.0);
}

- (void)testPending {
  auto param = Float(6);
  AUAudioFrameCount rampDuration{4};
  param.setPending(124.0);
  XCTAssertEqualWithAccuracy(param.getPending(), 124.0, epsilon);
  XCTAssertEqualWithAccuracy(param.getImmediate(), 124.0, epsilon);
  XCTAssertFalse(param.isRamping());
  param.checkForValueChange(rampDuration);
  XCTAssertEqualWithAccuracy(param.getImmediate(), 124.0, epsilon);
  XCTAssertEqualWithAccuracy(param.getPending(), 124.0, epsilon);
  XCTAssertEqualWithAccuracy(param.frameValue(), 31.0, epsilon);
  XCTAssertTrue(param.isRamping());
  param.checkForValueChange(rampDuration);
  XCTAssertEqualWithAccuracy(param.frameValue(), 62.0, epsilon);
  XCTAssertTrue(param.isRamping());
  param.checkForValueChange(rampDuration);
  XCTAssertEqualWithAccuracy(param.frameValue(), 93, epsilon);
  XCTAssertTrue(param.isRamping());
  param.checkForValueChange(rampDuration);
  XCTAssertEqualWithAccuracy(param.frameValue(), 124.0, epsilon);
  XCTAssertFalse(param.isRamping());
}

@end
