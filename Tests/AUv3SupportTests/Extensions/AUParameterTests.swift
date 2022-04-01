// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

fileprivate class MockProvider : ParameterAddressProvider {
  var parameterAddress: AUParameterAddress = 123
}

final class AUParameterTreeTests: XCTestCase {
  var params: [AUParameter]!
  var tree: AUParameterTree!

  override func setUp() {
    params = [AUParameterTree.createParameter(withIdentifier: "First", name: "First Name", address: 123,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              flags: [.flag_IsReadable], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Second", name: "Second Name", address: 456,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_IsReadable], valueStrings: nil,
                                              dependentParameters: nil),

              AUParameterTree.createParameter(withIdentifier: "Squared", name: "Squared", address: 1,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplaySquared], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "SquareRoot", name: "SquareRoot", address: 2,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplaySquareRoot], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Cubed", name: "Cubed", address: 3,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayCubed], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "CubeRoot", name: "CubeRoot", address: 4,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayCubeRoot], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Logarithmic", name: "Logarithmic", address: 5,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayLogarithmic], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Exponential", name: "Exponential", address: 6,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayExponential], valueStrings: nil,
                                              dependentParameters: nil),
    ]
    tree = AUParameterTree.createTree(withChildren: params)
  }

  override func tearDown() {
    tree = nil
    params = nil
  }

  func testAccessByParameterAddressProvider() {
    XCTAssertEqual(tree.parameter(source: MockProvider()), params[0])
  }

  func testParameterRange() {
    XCTAssertEqual(params[0].range, 0.0...100.0)
    XCTAssertEqual(params[1].range, 10.0...200.0)
  }

  func testParametricValue() {
    XCTAssertEqual(ParametricValue(0.1).value, 0.1)
    XCTAssertEqual(ParametricValue(-0.1).value, 0.0)
    XCTAssertEqual(ParametricValue(1.0).value, 1.0)
    XCTAssertEqual(ParametricValue(1.1).value, 1.0)
  }

  func testParametricSquaredTransforms() {
    let value = ParametricValue(0.5)
    let param = params[2]
    param.setParametricValue(value)
    XCTAssertEqual(param.value, 144.35028)
    XCTAssertEqual(param.parametricValue.value, 0.5, accuracy: 1.0e-5)
  }

  func testParametricSquareRootTransforms() {
    let value = ParametricValue(0.5)
    let param = params[3]
    param.setParametricValue(value)
    XCTAssertEqual(param.value, 57.5)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricCubedTransforms() {
    let param = params[4]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 160.8031)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricCubeRootTransforms() {
    let param = params[5]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 33.75)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricLogarithmicTransforms() {
    let param = params[6]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 55.648083)
    XCTAssertEqual(param.parametricValue.value, 0.5106643)
  }

  func testParametricExponentialTransforms() {
    let param = params[7]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 151.97214)
    XCTAssertEqual(param.parametricValue.value, 0.50972825)
  }
}
