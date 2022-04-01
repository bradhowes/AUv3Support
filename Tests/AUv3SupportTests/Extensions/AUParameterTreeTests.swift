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
    XCTAssertEqual(ParametricValue( 0.00).value, 0.0)
    XCTAssertEqual(ParametricValue( 1.20).value, 1.0)
    XCTAssertEqual(ParametricValue( 0.50).value, 0.5)
  }

  func testParametricLog() {
    XCTAssertEqual(ParametricValue(0.00).logarithmic.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).logarithmic.value, 0.52244276, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).logarithmic.value, 0.74722177, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).logarithmic.value, 0.8924769, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).logarithmic.value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesExp() {
    XCTAssertEqual(ParametricValue(0.00).exponential.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).exponential.value, 0.08647549, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).exponential.value, 0.24025308, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).exponential.value, 0.5137126, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).exponential.value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesSquared() {
    XCTAssertEqual(ParametricValue(0.00).squared.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).squared.value, 0.0625, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).squared.value, 0.25, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).squared.value, 0.5625, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).squared.value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesCubed() {
    XCTAssertEqual(ParametricValue(0.00).cubed.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).cubed.value, 0.015625, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).cubed.value, 0.125, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).cubed.value, 0.421875, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).cubed.value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesSquareRoot() {
    XCTAssertEqual(ParametricValue(0.00).squareRoot.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).squareRoot.value, 0.5, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).squareRoot.value, 0.70710677, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).squareRoot.value, 0.8660254, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).squareRoot.value, 1.00, accuracy: .epsilon)
  }

  func testParametricScalesCubeRoot() {
    XCTAssertEqual(ParametricValue(0.00).cubeRoot.value, 0.00, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.25).cubeRoot.value, 0.62996054, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.50).cubeRoot.value, 0.7937005, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(0.75).cubeRoot.value, 0.9085603, accuracy: .epsilon)
    XCTAssertEqual(ParametricValue(1.00).cubeRoot.value, 1.00, accuracy: .epsilon)
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
    XCTAssertEqual(param.value, 10454.586, accuracy: .epsilon)
    param.setParametricValue(0.50)
    XCTAssertEqual(param.value, 14947.469, accuracy: .epsilon)
    param.setParametricValue(0.75)
    XCTAssertEqual(param.value, 17850.828, accuracy: .epsilon)
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
