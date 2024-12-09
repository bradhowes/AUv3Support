import CoreAudioKit
import XCTest
@testable import AUv3Support

fileprivate class MockSliderControl: NSObject, RangedControl, AUParameterValueProvider {
  var parameterAddress: UInt64 = 1001
  var value: AUValue {
    didSet {
      print("slider changed to \(value)")
      expectation?.fulfill()
      editor?.controlChanged(source: self)
    }
  }
  var minimumValue: Float = 0.0
  var maximumValue: Float = 100.0
  var expectation: XCTestExpectation?
  weak var editor: AUParameterEditor?

  init(state: AUValue = 0.0, expectation: XCTestExpectation? = nil) {
    value = state
    self.expectation = expectation
  }
}

private struct formatter: AUParameterFormatting {
  public var unitSeparator: String { " " }
  public var suffix: String { "blah" }
  public var stringFormatForDisplayValue: String { "%.3f" }
}

@MainActor
private final class Context {
  let param: AUParameter
  let tree: AUParameterTree
  let control: MockSliderControl
  let altControl: MockSliderControl
  let editor: FloatParameterEditor
  let label: AUv3Label
  var paramValue: AUValue = 0.0
  var paramExpectation: XCTestExpectation?

  init(state: AUValue = 0.0, controlExpectation: XCTestExpectation? = nil) throws {
    param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1001, min: -80.0, max: 10.0, unit: .decibels,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable, .flag_DisplayLogarithmic], valueStrings: nil,
      dependentParameters: nil
    )

    tree = AUParameterTree.createTree(withChildren: [param])
    label = AUv3Label()
    control = MockSliderControl(state: state, expectation: controlExpectation)
    editor = FloatParameterEditor(parameter: param, formatting: formatter(), rangedControl: control, label: label)
    control.editor = editor

    altControl = MockSliderControl(state: state)
    altControl.editor = editor

    tree.implementorValueProvider = { param in
      if param.address == 1001 {
        return self.paramValue
      }
      return 0.0
    }

    tree.implementorValueObserver = { param, value in
      if param.address == 1001 {
        self.paramValue = value
        self.paramExpectation?.fulfill()
      }
    }
  }
}

final class LogFloatParameterEditorTests: XCTestCase {

  @MainActor
  func testEditorInitialization() async throws {
    let expectation = self.expectation(description: "control changed state via initialization")
    expectation.expectedFulfillmentCount = 1
    let ctx = try Context(state: 1.0, controlExpectation: expectation)
    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 8.830427)
    XCTAssertFalse(ctx.editor.differs)
    XCTAssertEqual(ctx.paramValue, 0.0)
  }

  @MainActor
  func testParamChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state via param change")
    expectation.expectedFulfillmentCount = 6
    let ctx = try Context(controlExpectation: expectation)
    XCTAssertEqual(ctx.control.value, 8.830427)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.param.setValue(10.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.param.setValue(20.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.param.setValue(30.0, originator: nil)

    await fulfillment(of: [expectation], timeout: 5.0)
    XCTAssertEqual(ctx.control.value, 9.0)
    XCTAssertEqual(ctx.paramValue, 10.0)
    XCTAssertFalse(ctx.editor.differs)
  }

  @MainActor
  func testEditorChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 4
    let ctx = try Context(controlExpectation: expectation)
    XCTAssertEqual(ctx.control.value, 8.830427)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.editor.setValue(10.0)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(0.5)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(98.123)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(12.9)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(50.0)
    try await Task.sleep(for: pause)

    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 9.0)
    XCTAssertEqual(ctx.paramValue, 10.0)
    XCTAssertFalse(ctx.editor.differs)
  }

  @MainActor
  func testControlChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state")
    expectation.expectedFulfillmentCount = 1
    let ctx = try Context()
    ctx.paramExpectation = expectation
    XCTAssertEqual(ctx.control.value, 8.830427)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.control.value = 10.0
    try await Task.sleep(for: pause)
    ctx.control.value = 20.0
    try await Task.sleep(for: pause)
    ctx.control.value = 30.0
    try await Task.sleep(for: pause)
    ctx.control.value = 40.0
    try await Task.sleep(for: pause)
    ctx.control.value = 50.0
    try await Task.sleep(for: pause)

    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.paramValue, 10)
    XCTAssertFalse(ctx.editor.differs)
  }

  @MainActor
  func testTwoControlsChangedValues() async throws {
    let expectation = self.expectation(description: "control changed state")
    expectation.expectedFulfillmentCount = 1
    let ctx = try Context()
    ctx.paramExpectation = expectation
    XCTAssertEqual(ctx.control.value, 8.830427)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.control.value = 10.0
    try await Task.sleep(for: pause)
    ctx.control.value = 20.0
    try await Task.sleep(for: pause)
    ctx.altControl.value = 30.0
    try await Task.sleep(for: pause)
    ctx.control.value = 40.0
    try await Task.sleep(for: pause)
    ctx.altControl.value = 50.0
    try await Task.sleep(for: pause)

    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.paramValue, 10)
    XCTAssertFalse(ctx.editor.differs)
  }

#if os(macOS)
  @MainActor
  func testLabelIsHiddenWAfterValueChange() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.label.text, "One")
    XCTAssertFalse(ctx.label.isHidden)
    ctx.editor.setValue(8.3)
    XCTAssertTrue(ctx.label.isHidden)
  }
#endif
}
