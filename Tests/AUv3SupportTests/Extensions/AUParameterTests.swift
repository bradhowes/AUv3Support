// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

extension AUValue {
  static let epsilon: Self = 1e-6
}

class AUParameterTests: XCTestCase {
  override func setUp() {}
  override func tearDown() {}

  func testParametricValue() throws {
    XCTAssertEqual(ParametricValue(-0.25).value, 0.0)
    XCTAssertEqual(ParametricValue( 0.0).value, 0.0)
    XCTAssertEqual(ParametricValue( 1.2).value, 1.0)
    XCTAssertEqual(ParametricValue( 0.5).value, 0.5)
  }

  func testParametricScalesLinear() {
    XCTAssertEqual(ParametricScales.linear(.init(0.00)).value, 0.00)
    XCTAssertEqual(ParametricScales.linear(.init(0.25)).value, 0.25)
    XCTAssertEqual(ParametricScales.linear(.init(0.50)).value, 0.50)
    XCTAssertEqual(ParametricScales.linear(.init(0.75)).value, 0.75)
    XCTAssertEqual(ParametricScales.linear(.init(1.00)).value, 1.00)
  }

  func testParametricScalesLog() {
    XCTAssertEqual(ParametricScales.log(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.log(.init(0.25)).value, 0.52244276, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.log(.init(0.50)).value, 0.74722177, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.log(.init(0.75)).value, 0.8924769, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.log(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesExp() {
    XCTAssertEqual(ParametricScales.exp(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.exp(.init(0.25)).value, 0.08647549, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.exp(.init(0.50)).value, 0.24025308, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.exp(.init(0.75)).value, 0.5137126, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.exp(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesSquared() {
    XCTAssertEqual(ParametricScales.squared(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squared(.init(0.25)).value, 0.0625, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squared(.init(0.50)).value, 0.25, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squared(.init(0.75)).value, 0.5625, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squared(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesCubed() {
    XCTAssertEqual(ParametricScales.cubed(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubed(.init(0.25)).value, 0.015625, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubed(.init(0.50)).value, 0.125, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubed(.init(0.75)).value, 0.421875, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubed(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesSquareRoot() {
    XCTAssertEqual(ParametricScales.squareRoot(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squareRoot(.init(0.25)).value, 0.5, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squareRoot(.init(0.50)).value, 0.70710677, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squareRoot(.init(0.75)).value, 0.8660254, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.squareRoot(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesCubeRoot() {
    XCTAssertEqual(ParametricScales.cubeRoot(.init(0.00)).value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubeRoot(.init(0.25)).value, 0.62996054, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubeRoot(.init(0.50)).value, 0.7937005, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubeRoot(.init(0.75)).value, 0.9085603, accuracy: .epsilon)
    XCTAssertEqual(ParametricScales.cubeRoot(.init(1.00)).value, 1.00, accuracy: .epsilon)
  }

  func testSetParametricValueLogarithmic() {
    let param = AUParameterTree.createParameter(withIdentifier: "foo", name: "foo", address: 123,
                                                min: 12.0, max: 20_000.0,
                                                unit: .hertz, unitName: nil, flags: [.flag_DisplayLogarithmic],
                                                valueStrings: nil, dependentParameters: nil)
    param.setValue(100, originator: nil)
    XCTAssertEqual(param.value, 100.0, accuracy: .epsilon)

    param.setParametricValue(0.0)
    XCTAssertEqual(param.value, param.minValue, accuracy: .epsilon)
    param.setParametricValue(0.25)
    XCTAssertEqual(param.value, 1740.4722, accuracy: .epsilon)
    param.setParametricValue(0.50)
    XCTAssertEqual(param.value, 4814.1787, accuracy: .epsilon)
    param.setParametricValue(0.75)
    XCTAssertEqual(param.value, 10280.087, accuracy: .epsilon)
    param.setParametricValue(1.00)
    XCTAssertEqual(param.value, param.maxValue, accuracy: .epsilon)
  }

  func testSetParametricValueExponential() {
    let param = AUParameterTree.createParameter(withIdentifier: "foo", name: "foo", address: 123,
                                                min: 12.0, max: 20_000.0,
                                                unit: .hertz, unitName: nil, flags: [.flag_DisplayExponential],
                                                valueStrings: nil, dependentParameters: nil)
    param.setValue(100, originator: nil)
    XCTAssertEqual(param.value, 100.0, accuracy: .epsilon)

    param.setParametricValue(0.0)
    XCTAssertEqual(param.value, param.minValue, accuracy: .epsilon)
    param.setParametricValue(0.25)
    XCTAssertEqual(param.value, 1261.25, accuracy: .epsilon)
    param.setParametricValue(0.50)
    XCTAssertEqual(param.value, 5009.0, accuracy: .epsilon)
    param.setParametricValue(0.75)
    XCTAssertEqual(param.value, 11255.25, accuracy: .epsilon)
    param.setParametricValue(1.00)
    XCTAssertEqual(param.value, param.maxValue, accuracy: .epsilon)
  }

  func testSetParametricValueSquared() {
    let param = AUParameterTree.createParameter(withIdentifier: "foo", name: "foo", address: 123,
                                                min: 12.0, max: 20_000.0,
                                                unit: .hertz, unitName: nil, flags: [.flag_DisplaySquared],
                                                valueStrings: nil, dependentParameters: nil)
    param.setValue(100, originator: nil)
    XCTAssertEqual(param.value, 100.0, accuracy: .epsilon)

    param.setParametricValue(0.0)
    XCTAssertEqual(param.value, param.minValue, accuracy: .epsilon)
    param.setParametricValue(0.25)
    XCTAssertEqual(param.value, 10006.0, accuracy: .epsilon)
    param.setParametricValue(0.50)
    XCTAssertEqual(param.value, 14145.65, accuracy: .epsilon)
    param.setParametricValue(0.75)
    XCTAssertEqual(param.value, 17322.115, accuracy: .epsilon)
    param.setParametricValue(1.00)
    XCTAssertEqual(param.value, param.maxValue, accuracy: .epsilon)
  }

  func testSetParametricValueSquareRoot() {
    let param = AUParameterTree.createParameter(withIdentifier: "foo", name: "foo", address: 123,
                                                min: 12.0, max: 20_000.0,
                                                unit: .hertz, unitName: nil, flags: [.flag_DisplaySquareRoot],
                                                valueStrings: nil, dependentParameters: nil)
    param.setValue(100, originator: nil)
    XCTAssertEqual(param.value, 100.0, accuracy: .epsilon)

    param.setParametricValue(0.0)
    XCTAssertEqual(param.value, param.minValue, accuracy: .epsilon)
    param.setParametricValue(0.25)
    XCTAssertEqual(param.value, 1261.25, accuracy: .epsilon)
    param.setParametricValue(0.50)
    XCTAssertEqual(param.value, 5009.0, accuracy: .epsilon)
    param.setParametricValue(0.75)
    XCTAssertEqual(param.value, 11255.25, accuracy: .epsilon)
    param.setParametricValue(1.00)
    XCTAssertEqual(param.value, param.maxValue, accuracy: .epsilon)
  }
}
