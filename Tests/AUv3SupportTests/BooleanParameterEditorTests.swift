import CoreAudioKit
import XCTest
@testable import AUv3Support

class MockControl: NSObject, BooleanControl, AUParameterValueProvider {

  var value: AUValue { isOn ? 1.0 : 0.0 }

  var _isOn: Bool = false
  var isOn: Bool {
    get {
      print("MockControl get -", _isOn)
      return _isOn
    }
    set {
      print("MockControl set -", newValue)
      _isOn = newValue
    }
  }
}

final class BooleanParameterEditorTests: XCTestCase {

  func testEditorParameterChanged() throws {
    _ = Shared.logger("foo", "bar")

    let param = AUParameterTree.createParameter(
      withIdentifier: "One", name: "One", address: 1000, min: 0.0, max: 1.0, unit: .boolean,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil
    )

    var changes = [AUParameterAddress: AUValue]()

    let paramObserver = { (address: AUParameterAddress,  value: AUValue) in
      changes[address] = value
    }

    let paramToken = param.token(byAddingParameterObserver: paramObserver)

    let tree = AUParameterTree.createTree(withChildren: [param])
    let treeObserver = { (address: AUParameterAddress,  value: AUValue) in
      print("hi")
    }

    let treeToken = tree.token(byAddingParameterObserver: treeObserver)

    let mockControl = MockControl()
    let editor = BooleanParameterEditor(parameterObserverToken: treeToken, parameter: param,
                                        booleanControl: mockControl)
    param.setValue(1.0, originator: nil)
    editor.parameterChanged()
    XCTAssertEqual(mockControl.isOn, true)

    editor.setEditedValue(0.0)
  }
}
