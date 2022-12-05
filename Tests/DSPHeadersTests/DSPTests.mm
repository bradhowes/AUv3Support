// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSPHeaders/DSP.hpp"

using namespace DSPHeaders;

@interface DSPTests : XCTestCase

@end

@implementation DSPTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUnipolarModulation {
  XCTAssertEqual(DSP::unipolarModulation(-3.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(DSP::unipolarModulation(0.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(DSP::unipolarModulation(0.5, 10.0, 20.0), 15.0);
  XCTAssertEqual(DSP::unipolarModulation(1.0, 10.0, 20.0), 20.0);
  XCTAssertEqual(DSP::unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
  XCTAssertEqual(DSP::bipolarModulation(-3.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(DSP::bipolarModulation(-1.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(DSP::bipolarModulation(0.0, 10.0, 20.0), 15.0);
  XCTAssertEqual(DSP::bipolarModulation(1.0, 10.0, 20.0), 20.0);
  
  XCTAssertEqual(DSP::bipolarModulation(-1.0, -20.0, 13.0), -20.0);
  XCTAssertEqual(DSP::bipolarModulation(0.0,  -20.0, 13.0), -3.5);
  XCTAssertEqual(DSP::bipolarModulation(1.0,  -20.0, 13.0), 13.0);
}

- (void)testUnipolarToBipolar {
  XCTAssertEqual(DSP::unipolarToBipolar(0.0), -1.0);
  XCTAssertEqual(DSP::unipolarToBipolar(0.5), 0.0);
  XCTAssertEqual(DSP::unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
  XCTAssertEqual(DSP::bipolarToUnipolar(-1.0), 0.0);
  XCTAssertEqual(DSP::bipolarToUnipolar(0.0), 0.5);
  XCTAssertEqual(DSP::bipolarToUnipolar(1.0), 1.0);
}

- (void)testParabolicSineAccuracy {
  for (int index = 0; index < 36000.0; ++index) {
    auto theta = 2.0 * M_PI * index / 36000.0 - M_PI;
    auto real = std::sin(theta);
    XCTAssertEqualWithAccuracy(DSP::parabolicSine(theta), real, 0.0011);
  }
}

- (void)testInterpolationCubic4thOrderInterpolate {
  double epsilon = 1.0e-18;

  auto v = DSPHeaders::DSP::Interpolation::cubic4thOrder(0.0, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(2.0, v, epsilon);

  v = DSPHeaders::DSP::Interpolation::cubic4thOrder(0.5, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(1 * -0.0625 + 2 * 0.5625 + 3 * 0.5625 + 4 * -0.0625, v, epsilon);

  v = DSPHeaders::DSP::Interpolation::cubic4thOrder(0.99999, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(2.9990234375, v, epsilon);
}

- (void)testInterpolationLinearInterpolate {
  double epsilon = 1.0e-18;

  auto v = DSPHeaders::DSP::Interpolation::linear(0.0, 1, 2);
  XCTAssertEqualWithAccuracy(1.0, v, epsilon);

  v = DSPHeaders::DSP::Interpolation::linear(0.5, 1, 2);
  XCTAssertEqualWithAccuracy(0.5 * 1.0 + 0.5 * 2.0, v, epsilon);

  v = DSPHeaders::DSP::Interpolation::linear(0.9, 1.0, 2.0);
  XCTAssertEqualWithAccuracy((1.0 - 0.9) * 1.0 + 0.9 * 2.0, v, epsilon);
}

//- (void)testZZZ {
//  for (float modulator = -1.0; modulator <= 1.0; modulator += 0.1) {
//    auto a = DSP::unipolarModulation<float>(DSP::bipolarToUnipolar<float>(modulator), 0.0, 10.0);
//    auto b = DSP::bipolarModulation<float>(modulator, 0.0, 10.0);
//    NSLog(@"%f %f", a, b);
//  }
//}

@end
