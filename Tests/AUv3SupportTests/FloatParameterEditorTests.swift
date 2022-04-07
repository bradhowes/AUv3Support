import CoreAudioKit
import XCTest
@testable import AUv3Support

fileprivate class MockParam: AUParameterValueProvider {
  var value: AUValue = 0.0
}

fileprivate class MockControl: NSObject, RangedControl {
  static let log = Shared.logger("foo", "bar")
  let log = MockControl.log
  var parameterAddress: UInt64 = 0
  var value: AUValue = 0.0 {
    didSet {
      expectation?.fulfill()
    }
  }
  var minimumValue: Float = 0.0
  var maximumValue: Float = 100.0
  var expectation: XCTestExpectation?
}

final class FloatParameterEditorTests: XCTestCase {

  private var param1: AUParameter!
  private var param2: AUParameter!
  private var tree: AUParameterTree!
  private var control: MockControl!
  private var editor1: FloatParameterEditor!
  private var editor2: FloatParameterEditor!
  private var parameterValue1: AUValue = 0.0
  private var parameterValue2: AUValue = 0.0

  override func setUpWithError() throws {
    param1 = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1001, min: 0.0, max: 100.0, unit: .percent,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    param2 = AUParameterTree.createParameter(
      withIdentifier: "Two", name: "Two", address: 1002, min: 0.0, max: 100.0, unit: .percent,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable, .flag_DisplayLogarithmic], valueStrings: nil,
      dependentParameters: nil
    )

    control = MockControl()
    parameterValue1 = 0.0
    parameterValue2 = 0.0

    tree = AUParameterTree.createTree(withChildren: [param1, param2])
    tree.implementorValueProvider = { param in
      switch param.address {
      case 1001: return self.parameterValue1
      case 1002: return self.parameterValue2
      default: return 0.0
      }
    }

    tree.implementorValueObserver = { param, value in
      switch param.address {
      case 1001: self.parameterValue1 = value
      case 1002: self.parameterValue2 = value
      default: break
      }
    }

    editor1 = FloatParameterEditor(parameter: param1, formatter: { "\($0)" }, rangedControl: control, label: nil)
    editor2 = FloatParameterEditor(parameter: param2, formatter: { "\($0)" }, rangedControl: control, label: nil)
  }

  override func tearDownWithError() throws {
    param1 = nil
    param2 = nil
    tree = nil
    control = nil
    editor1 = nil
    editor2 = nil
  }

  func testEditor1ParameterChanged() throws {
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    param1.setValue(35.0, originator: nil)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 35.0)
    XCTAssertEqual(parameterValue1, 35.0)
  }

  func testEditor2ParameterChanged() throws {
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    param2.setValue(35.0, originator: nil)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 7.49065)
    XCTAssertEqual(parameterValue2, 35.0)
  }

  func testEditor1SetEditedValue() throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    editor1.setValue(78.3)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 78.3)
    XCTAssertEqual(parameterValue1, 78.3)
  }

  func testEditor2SetEditedValue() throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    editor2.setValue(78.3)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 8.647865)
    XCTAssertEqual(parameterValue2, 78.3)
  }

  func testControl1Changed() throws {
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    let otherControl = MockParam()
    otherControl.value = 15.12
    editor1.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 15.12)
    XCTAssertEqual(parameterValue1, 15.12)
  }

  func testControl2Changed() throws {
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    let otherControl = MockParam()
    otherControl.value = 8.647865
    editor2.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 8.647865)
    XCTAssertEqual(parameterValue2, 78.30002)
  }
}
