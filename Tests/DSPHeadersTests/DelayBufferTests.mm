// Copyright © 2021-2024 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <iomanip>
#import <iostream>
#import <vector>

#import "DSPHeaders/DelayBuffer.hpp"

using namespace DSPHeaders;

@interface DelayBufferTests : XCTestCase
@end

@implementation DelayBufferTests

static float epsilon = 1.0E-7;

- (void)setUp {}

- (void)tearDown {}

- (void)testSizing {
  XCTAssertEqual(1, DelayBuffer<float>(-1.0).size());
  XCTAssertEqual(2, DelayBuffer<float>(1.2).size());
  XCTAssertEqual(32, DelayBuffer<float>(32.0).size());
  XCTAssertEqual(128, DelayBuffer<float>(123.4).size());
  XCTAssertEqual(1024, DelayBuffer<float>(1024.0).size());
}

- (void)testReadFromOffset{
  auto buffer = DelayBuffer<float>(4);
  XCTAssertEqual(4, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(0), 3.6, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(1), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(2), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(3), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(4), 3.6, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(5), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(6), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(7), 0.0, epsilon);

  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-1), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-2), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-3), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-4), 3.6, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-5), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-6), 1.2, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-7), 2.4, epsilon);
  XCTAssertEqualWithAccuracy(buffer.readFromOffset(-8), 3.6, epsilon);
}

- (void)testWriteWrapping {
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
  auto buffer = DelayBuffer<double>(8, DelayBuffer<double>::Interpolator::linear);
  XCTAssertEqual(8, buffer.size());
  buffer.write(1.2);
  buffer.write(2.4);
  buffer.write(3.6);
  XCTAssertEqualWithAccuracy(buffer.read(0.0), 3.60, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(0.5), 3.00, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.0), 2.40, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(2.0), 1.20, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(3.0), 0.00, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.1), 2.28, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.2), 2.16, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.5), 1.80, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.8), 1.44, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.9), 1.32, epsilon);
}

- (void)testReadCubic4thOrderInterpolated {
  auto buffer = DelayBuffer<double>(8, DelayBuffer<double>::Interpolator::cubic4thOrder);
  XCTAssertEqual(8, buffer.size());
  buffer.write(0.00);
  buffer.write(0.25);
  buffer.write(0.50);
  buffer.write(0.75);
  buffer.write(1.00);
  buffer.write(0.75);
  buffer.write(0.50);
  buffer.write(0.25);
  std::cout << std::setprecision(16) <<  buffer.read(1.9) << '\n';
  XCTAssertEqualWithAccuracy(buffer.read(0.0), 0.250, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(0.5), 0.625, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.0), 0.500, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(2.0), 0.750, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(3.0), 1.000, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.1), 0.777135768905, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.2), 0.807750061154, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.5), 0.90625, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.8), 0.981966783525, epsilon);
  XCTAssertEqualWithAccuracy(buffer.read(1.9), 0.995195654919, epsilon);
}

@end
