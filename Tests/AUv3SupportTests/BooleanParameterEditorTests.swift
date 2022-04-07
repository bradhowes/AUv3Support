import CoreAudioKit
import XCTest
@testable import AUv3Support

fileprivate class MockControl: NSObject, BooleanControl, AUParameterValueProvider {
  static let log = Shared.logger("foo", "bar")
  let log = MockControl.log
  var expectation: XCTestExpectation?
  var value: AUValue = 0.0
  var booleanState: Bool = false {
    didSet {
      print("MockControl.isOn didSet - \(booleanState)")
      expectation?.fulfill()
    }
  }
}

final class BooleanParameterEditorTests: XCTestCase {

  private var param: AUParameter!
  private var tree: AUParameterTree!
  private var control: MockControl!
  private var editor: BooleanParameterEditor!

  override func setUpWithError() throws {
    param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1001, min: 0.0, max: 1.0, unit: .boolean,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    control = MockControl()
    tree = AUParameterTree.createTree(withChildren: [param])
    tree.implementorValueProvider = { parameter in
      if parameter.address == 1001 {
        return self.control.value
      }
      return 0.0
    }

    tree.implementorValueObserver = { parameter, value in
      if parameter.address == 1001 {
        self.control.value = value
      }
    }

    editor = BooleanParameterEditor(parameter: param, booleanControl: control)
  }

  override func tearDownWithError() throws {
    param = nil
    tree = nil
    control = nil
    editor = nil
  }

  func testEditorParameterChanged() throws {
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(control.booleanState, false)
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    param.setValue(1.0, originator: nil)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.booleanState, true)
  }

  func testEditorSetEditedValue() throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    XCTAssertEqual(control.booleanState, false)
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    editor.setValue(1.0)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.booleanState, true)
    XCTAssertEqual(control.value, 1.0)
  }

  func testControlChanged() throws {
    let expectation = self.expectation(description: "control changed state via control change")
    XCTAssertEqual(control.booleanState, false)
    XCTAssertEqual(control.value, 0.0)
    control.expectation = expectation
    let otherControl = MockControl()
    otherControl.value = 1.0
    editor.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(control.value, 1.0)
  }
}
