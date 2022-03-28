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

  private var param: AUParameter!
  private var tree: AUParameterTree!
  private var control: MockControl!
  private var editor: FloatParameterEditor!
  private var parameterValue: AUValue = 0.0

  override func setUpWithError() throws {
    param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1000, min: 0.0, max: 100.0, unit: .percent,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    control = MockControl()

    parameterValue = 0.0
    tree = AUParameterTree.createTree(withChildren: [param])
    tree.implementorValueProvider = { $0.address == 1000 ? self.parameterValue : 0.0 }
    tree.implementorValueObserver = { if $0.address == 1000 { self.parameterValue = $1 } }

    editor = FloatParameterEditor(parameter: param, formatter: { "\($0)" }, rangedControl: control, label: nil)
  }

  override func tearDownWithError() throws {
    param = nil
    tree = nil
    control = nil
    editor = nil
  }

  func testEditorParameterChanged() throws {
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    param.setValue(35.0, originator: nil)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 35.0)
    XCTAssertEqual(parameterValue, 35.0)
  }

  func testEditorSetEditedValue() throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    editor.setEditedValue(78.3)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 78.3)
    XCTAssertEqual(parameterValue, 78.3)
  }

  func testControlChanged() throws {
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    let otherControl = MockParam()
    otherControl.value = 15.12
    editor.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 15.12)
    XCTAssertEqual(parameterValue, 15.12)
  }
}
