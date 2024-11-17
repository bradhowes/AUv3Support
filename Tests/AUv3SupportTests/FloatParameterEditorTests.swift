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

private struct formatter: AUParameterFormatting {
  public var unitSeparator: String { " " }
  public var suffix: String { "blah" }
  public var stringFormatForDisplayValue: String { "%.3f" }
}

@MainActor
private final class Context {
  let param1: AUParameter
  let param2: AUParameter
  let tree: AUParameterTree
  let control: MockControl!
  let editor1: FloatParameterEditor!
  let editor2: FloatParameterEditor!
  let label1: Label!
  var parameterValue1: AUValue = 0.0
  var parameterValue2: AUValue = 0.0

  init() throws {
    try XCTSkipIf(true, "Broken")
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

    label1 = Label()
    control = MockControl()
    parameterValue1 = 0.0
    parameterValue2 = 0.0

    tree = AUParameterTree.createTree(withChildren: [param1, param2])
    editor1 = FloatParameterEditor(parameter: param1, formatting: formatter(), rangedControl: control, label: label1)
    editor2 = FloatParameterEditor(parameter: param2, formatting: formatter(), rangedControl: control, label: nil)

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
  }
}

final class FloatParameterEditorTests: XCTestCase {

  @MainActor
  func testEditor1ParameterChanged() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    XCTAssertFalse(ctx.editor1.differs)
    ctx.param1.setValue(35.0, originator: nil)
    XCTAssertTrue(ctx.editor1.differs)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 35.0)
    XCTAssertEqual(ctx.parameterValue1, 35.0)
  }

  @MainActor
  func testEditor2ParameterChanged() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via param change")
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    XCTAssertFalse(ctx.editor2.differs)
    ctx.param2.setValue(35.0, originator: nil)
    XCTAssertTrue(ctx.editor2.differs)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 7.49065)
    XCTAssertEqual(ctx.parameterValue2, 35.0)
  }

  @MainActor
  func testEditor1SetEditedValue() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    ctx.editor1.setValue(78.3)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 78.3)
    XCTAssertEqual(ctx.parameterValue1, 78.3)
  }

  @MainActor
  func testEditor2SetEditedValue() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    ctx.editor2.setValue(78.3)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 8.647865)
    XCTAssertEqual(ctx.parameterValue2, 78.3)
  }

  @MainActor
  func testControl1Changed() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    let otherControl = MockParam()
    otherControl.value = 15.12
    ctx.editor1.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 15.12)
    XCTAssertEqual(ctx.parameterValue1, 15.12)
  }

  @MainActor
  func testControl2Changed() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 1
    XCTAssertEqual(ctx.control.value, 0.0)
    ctx.control.expectation = expectation
    let otherControl = MockParam()
    otherControl.value = 8.647865
    ctx.editor2.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 8.647865)
    XCTAssertEqual(ctx.parameterValue2, 78.30002)
  }

#if os(macOS)
  @MainActor
  func testLabelIsHiddenWAfterValueChange() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.label1.text, "One")
    XCTAssertFalse(ctx.label1.isHidden)
    ctx.editor1.setValue(8.3)
    XCTAssertTrue(ctx.label1.isHidden)
  }
#endif
}
