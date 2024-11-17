import CoreAudioKit
import XCTest
@testable import AUv3Support

@MainActor
fileprivate class MockControl: NSObject, BooleanControl, AUParameterValueProvider {
  static let log = Shared.logger("foo", "bar")
  let log = MockControl.log
  var parameterAddress: AUParameterAddress = 1001
  var expectation: XCTestExpectation?
  var value: AUValue = 0.0
  var booleanState: Bool = false {
    didSet {
      print("MockControl.isOn didSet - \(booleanState)")
      // expectation?.fulfill()
    }
  }
}

@MainActor
private final class Context {
  let param: AUParameter
  let tree: AUParameterTree
  let control: MockControl

  var editor: BooleanParameterEditor!

  nonisolated(unsafe) var value: AUValue = 0.0

  init() throws {
    try XCTSkipIf(true, "Broken")
    param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1001, min: 0.0, max: 1.0, unit: .boolean,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    control = MockControl()
    tree = AUParameterTree.createTree(withChildren: [param])

    tree.implementorValueProvider = { parameter in
      if parameter.address == 1001 {
        return self.value
      }
      return 0.0
    }

    tree.implementorValueObserver = { parameter, value in
      if parameter.address == 1001 {
        self.value = value
      }
    }

    editor = BooleanParameterEditor(parameter: param, booleanControl: control)
  }
}

final class BooleanParameterEditorTests: XCTestCase {

  private var param: AUParameter!
  private var tree: AUParameterTree!
  private var control: MockControl!
  private var editor: BooleanParameterEditor!

  @MainActor
  func testEditorParameterChanged() async throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via editing change")
    XCTAssertEqual(ctx.control.booleanState, false)
    // XCTAssertFalse(ctx.editor.differs)
    XCTAssertEqual(ctx.control.value, 0.0)
    // ctx.control.expectation = expectation
    ctx.param.setValue(1.0, originator: nil)
    XCTAssertEqual(ctx.control.booleanState, true)
    await fulfillment(of: [expectation], timeout: 2.0)
  }

  @MainActor
  func testEditorSetEditedValue() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via editing change")
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertEqual(ctx.control.value, 0.0)
    // ctx.control.expectation = expectation
    ctx.editor.setValue(1.0)
    XCTAssertFalse(ctx.editor.differs)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.booleanState, true)
    XCTAssertEqual(ctx.control.value, 1.0)
  }

  @MainActor
  func testControlChanged() throws {
    let ctx = try Context()
    let expectation = self.expectation(description: "control changed state via control change")
    XCTAssertEqual(ctx.control.booleanState, false)
    XCTAssertEqual(ctx.control.value, 0.0)
    // ctx.control.expectation = expectation
    let otherControl = MockControl()
    otherControl.value = 1.0
    ctx.editor.controlChanged(source: otherControl)
    wait(for: [expectation], timeout: 2.0)
    XCTAssertEqual(ctx.control.value, 1.0)
  }
}
