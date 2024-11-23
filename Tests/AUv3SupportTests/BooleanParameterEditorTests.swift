import CoreAudioKit
import XCTest
@testable import AUv3Support

@MainActor
fileprivate class MockToggleControl: NSObject, BooleanControl, AUParameterValueProvider {
  var value: AUValue { booleanState ? 1.0 : 0.0 }
  var parameterAddress: AUParameterAddress = 1001
  var editor: AUParameterEditor?

  let expectation: XCTestExpectation?

  var booleanState: Bool {
    didSet {
      expectation?.fulfill()
      editor?.controlChanged(source: self)
    }
  }

  init(state: Bool, expectation: XCTestExpectation? = nil) {
    booleanState = state
    self.expectation = expectation
  }
}

@MainActor
private final class Context {
  let param: AUParameter
  let tree: AUParameterTree
  let control: MockToggleControl
  let editor: BooleanParameterEditor
  var paramValue: AUValue = 0.0

  init(state: Bool, expectation: XCTestExpectation? = nil) throws {
    param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1001, min: 0.0, max: 1.0, unit: .boolean,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    tree = AUParameterTree.createTree(withChildren: [param])
    control = MockToggleControl(state: state, expectation: expectation)
    editor = BooleanParameterEditor(parameter: param, booleanControl: control)
    control.editor = editor

    tree.implementorValueProvider = { parameter in
      if parameter.address == 1001 {
        return self.paramValue
      }
      return 0.0
    }

    tree.implementorValueObserver = { parameter, value in
      if parameter.address == 1001 {
        self.paramValue = value
      }
    }
  }
}

final class BooleanParameterEditorTests: XCTestCase {

  @MainActor
  func testEditorInitialization() async throws {
    let expectation = self.expectation(description: "control changed state via initialization")
    expectation.expectedFulfillmentCount = 1
    let ctx = try Context(state: true, expectation: expectation)
    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertFalse(ctx.editor.differs)
    XCTAssertEqual(ctx.paramValue, 0.0)
  }

  @MainActor
  func testParamChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state via param change")
    expectation.expectedFulfillmentCount = 3
    let ctx = try Context(state: false, expectation: expectation)
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.param.setValue(1.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.param.setValue(0.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.param.setValue(1.0, originator: nil)

    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.booleanState, true)
    XCTAssertEqual(ctx.paramValue, 1.0)
    XCTAssertFalse(ctx.editor.differs)
  }

  @MainActor
  func testEditorChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state via editing change")
    expectation.expectedFulfillmentCount = 3
    let ctx = try Context(state: false, expectation: expectation)
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertEqual(ctx.paramValue, 0.0)

    let pause: Duration = .milliseconds(200)
    ctx.editor.setValue(1.0)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(0.8)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(0.0)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(0.6)
    try await Task.sleep(for: pause)
    ctx.editor.setValue(1.0)
    try await Task.sleep(for: pause)

    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.booleanState, true)
    XCTAssertEqual(ctx.paramValue, 1.0)
    XCTAssertFalse(ctx.editor.differs)
  }

  @MainActor
  func testControlChangedValue() async throws {
    let expectation = self.expectation(description: "control changed state via control change")
    expectation.expectedFulfillmentCount = 2
    let ctx = try Context(state: true, expectation: expectation)
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertEqual(ctx.paramValue, 0.0)
    ctx.control.booleanState = true
    await fulfillment(of: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.paramValue, 1.0)
  }
}
