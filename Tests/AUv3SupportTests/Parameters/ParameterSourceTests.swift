import AudioUnit
import XCTest
@testable import AUv3Support

fileprivate enum ParameterAddress: AUParameterAddress, ParameterAddressProvider {
  case foo = 1001
  case bar = 1002

  var parameterAddress: AUParameterAddress { self.rawValue }
}

fileprivate class MockParameterSource: ParameterSource {
  let factoryPresets: [AUAudioUnitPreset] = []
  let parameters: [AUParameter]
  let parameterTree: AUParameterTree

  func useFactoryPreset(_ preset: AUAudioUnitPreset) {}

  init() {
    parameters = [ParameterDefinition.defBool("foo", localized: "foo", address: ParameterAddress.foo).parameter,
                  ParameterDefinition.defBool("bar", localized: "bar", address: ParameterAddress.bar).parameter]
    parameterTree = AUParameterTree.createTree(withChildren: parameters)
  }
}

class ParameterSourceTests: XCTestCase {

  func testStoreParameters() throws {
    let ps = MockParameterSource()
    ps.parameters[0].value = 0.0
    ps.parameters[1].value = 1.0
    var dict = [String: Any]()
    ps.storeParameters(into: &dict)
    XCTAssertEqual(dict.count, 2)
  }

  func testUseUserPreset() {
    let ps = MockParameterSource()
    ps.parameters[0].value = 0.0
    ps.parameters[1].value = 1.0
    var dict = [String: Any]()
    ps.storeParameters(into: &dict)

    ps.parameters[0].value = 10.0
    ps.parameters[1].value = -10.0
    ps.useUserPreset(from: dict)

    XCTAssertEqual(ps.parameters[0].value, 0.0)
    XCTAssertEqual(ps.parameters[1].value, 1.0)
  }
}
