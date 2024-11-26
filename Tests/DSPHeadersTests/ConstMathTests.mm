// Copyright © 2021-2024 Brad Howes. All rights reserved.

#include <XCTest/XCTest.h>
#include <cmath>

#include "DSPHeaders/ConstMath.hpp"

using namespace DSPHeaders;

@interface ConstMathTests : XCTestCase
@end

@implementation ConstMathTests {
  double epsilon;
}

- (void)setUp {
  epsilon = 1.0e-13; // 0.0000001;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSquared {
  XCTAssertEqualWithAccuracy(3.5 * 3.5, ConstMath::squared(3.5), epsilon);
}

- (void)testNormalizeRadians {
  double theta = 1.23 + 4 * ConstMath::Constants<double>::PI;
  XCTAssertEqualWithAccuracy(1.23, ConstMath::normalizedRadians(theta), epsilon);
  theta = -ConstMath::Constants<double>::PI;
  XCTAssertEqualWithAccuracy(-theta, ConstMath::normalizedRadians(theta), epsilon);
  theta = ConstMath::Constants<double>::PI;
  XCTAssertEqualWithAccuracy(theta, ConstMath::normalizedRadians(theta), epsilon);
}

- (void)testSin {
  for (int index = -3600; index < 3600; index += 1) {
    double theta = index / 10.0 * ConstMath::Constants<double>::PI / 180.0;
    XCTAssertEqualWithAccuracy(std::sin(theta), ConstMath::sin(theta), epsilon);
  }
}

- (void)testFloor {
  XCTAssertEqual(1, ConstMath::floor(1.23));
  XCTAssertEqual(1, ConstMath::floor(1.0));
  XCTAssertEqual(0, ConstMath::floor(0.1));
  XCTAssertEqual(0, ConstMath::floor(-0.0));
  XCTAssertEqual(-1, ConstMath::floor(-0.1));
  XCTAssertEqual(-2, ConstMath::floor(-1.23));
  XCTAssertEqual(1, ConstMath::floor(1));
}

- (void)testCeil {
  XCTAssertEqual(2, ConstMath::ceil(1.23));
  XCTAssertEqual(1, ConstMath::ceil(1.0));
  XCTAssertEqual(1, ConstMath::ceil(0.1));
  XCTAssertEqual(0, ConstMath::ceil(-0.0));
  XCTAssertEqual(0, ConstMath::ceil(-0.1));
  XCTAssertEqual(-1, ConstMath::ceil(-1.23));
  XCTAssertEqual(1, ConstMath::ceil(1));
}

- (void)testAbs {
  XCTAssertEqualWithAccuracy(0.0, ConstMath::abs(0.0), epsilon);
  XCTAssertEqualWithAccuracy(1.0, ConstMath::abs(1.0), epsilon);
  XCTAssertEqualWithAccuracy(1.0, ConstMath::abs(-1.0), epsilon);
}

- (void)testIpow {
  XCTAssertEqualWithAccuracy(2.5 * 2.5 * 2.5 * 2.5, ConstMath::ipow(2.5, 4), epsilon);
  XCTAssertEqualWithAccuracy(2.5 * 2.5 * 2.5 * 2.5, ConstMath::ipow(-2.5, 4), epsilon);
  XCTAssertEqualWithAccuracy(-2.5 * 2.5 * 2.5, ConstMath::ipow(-2.5, 3), epsilon);
  XCTAssertEqualWithAccuracy(1.0, ConstMath::ipow(123, 0), epsilon);
}

- (void)testIsEven {
  XCTAssertTrue(ConstMath::is_even(0));
  XCTAssertTrue(ConstMath::is_even(2));
  XCTAssertTrue(ConstMath::is_even(-2));

  XCTAssertFalse(ConstMath::is_even(1));
  XCTAssertFalse(ConstMath::is_even(3));
  XCTAssertFalse(ConstMath::is_even(-1));
}

- (void)testExp {
  XCTAssertEqualWithAccuracy(std::exp(2.345), ConstMath::exp(2.345), epsilon);
  XCTAssertEqualWithAccuracy(std::exp(0.0), ConstMath::exp(0.0), epsilon);
  XCTAssertEqualWithAccuracy(std::exp(-1.2), ConstMath::exp(-1.2), epsilon);
}

- (void)testLog {
  XCTAssertEqualWithAccuracy(std::log(1.0e-8), ConstMath::log(1.0e-8), epsilon);
  XCTAssertEqualWithAccuracy(std::log(1.0), ConstMath::log(1.0), epsilon);
  XCTAssertEqualWithAccuracy(std::log(1.23), ConstMath::log(1.23), epsilon);
  XCTAssertEqualWithAccuracy(std::log(9.876), ConstMath::log(9.876), epsilon);
}

- (void)testLog10 {
  XCTAssertEqualWithAccuracy(std::log10(1.0e-8), ConstMath::log10(1.0e-8), epsilon);
  XCTAssertEqualWithAccuracy(std::log10(1.0), ConstMath::log10(1.0), epsilon);
  XCTAssertEqualWithAccuracy(std::log10(1.23), ConstMath::log10(1.23), epsilon);
  XCTAssertEqualWithAccuracy(std::log10(9.876), ConstMath::log10(9.876), epsilon);
}

- (void)testPow {
  XCTAssertEqualWithAccuracy(std::pow(2.3, 4.5), ConstMath::pow(2.3, 4.5), epsilon);
  XCTAssertEqualWithAccuracy(std::pow(ConstMath::Constants<double>::PI, ConstMath::Constants<double>::e),
                             ConstMath::pow(ConstMath::Constants<double>::PI, ConstMath::Constants<double>::e),
                             epsilon);
}

@end
