// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "DSPHeaders/DelayBuffer.hpp"

using namespace DSPHeaders;

@interface DelayBufferTests : XCTestCase

@end

@implementation DelayBufferTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSizing {
  XCTAssertEqual(1, DelayBuffer<float>(-1.0).size());
  XCTAssertEqual(2, DelayBuffer<float>(1.2).size());
  XCTAssertEqual(128, DelayBuffer<float>(123.4).size());
  XCTAssertEqual(1024, DelayBuffer<float>(1024.0).size());
}

- (void)testReadFromOffset{
  auto buffer = DelayBuffer<float>(8);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(1), 2.4, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(2), 1.2, 0.001);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(3), 0.0, 0.001);
}

- (void)testWrapping {
  double epsilon = 1.0e-14;
  auto buffer = DelayBuffer<double>(4, DelayBuffer<double>::Interpolator::linear);
  XCTAssertEqual(4, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  buffer.write(4.8);
  buffer.write(5.0);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(0), 5.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(1), 4.8, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(2), 3.6, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(3), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(4), 5.0, epsilon);
}

- (void)testReadLinearInterpolated {
  double epsilon = 1.0e-14;
  auto buffer = DelayBuffer<double>(8, DelayBuffer<double>::Interpolator::linear);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.read(1.0), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(2.0), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(3.0), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.1), 2.28, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.2), 2.16, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.5), 1.80, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.8), 1.44, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.9), 1.32, epsilon);
}

- (void)testReadCubic4thOrderInterpolated {
  double epsilon = 1.0e-14;
  auto buffer = DelayBuffer<double>(8, DelayBuffer<double>::Interpolator::cubic4thOrder);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.read(1.0), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(2.0), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(3.0), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.1), 2.28046875, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.2), 2.1609375, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.5), 1.80, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.8), 1.440234375, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.9), 1.320703125, epsilon);
}

@end
