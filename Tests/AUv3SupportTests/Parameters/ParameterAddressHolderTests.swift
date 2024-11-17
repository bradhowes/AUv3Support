import AudioUnit
import XCTest
@testable import AUv3Support

fileprivate enum ParameterAddress: UInt64 {
  var parameterAddress: AUParameterAddress { rawValue }
  case one = 1234
  case two
}

fileprivate extension ParameterAddressHolder {
  func setParameterAddress(_ address: ParameterAddress?) { parameterAddress = address?.rawValue ?? 0 }
}

fileprivate class SomeObject: NSObject, ParameterAddressHolder {
  var parameterAddress: UInt64 = 0
}

final class ParameterAddressHolderTests: XCTestCase {

  @MainActor
  func testAPI() throws {
    let a = SomeObject()
    XCTAssertEqual(a.parameterAddress, 0)

    a.setParameterAddress(ParameterAddress.one)
    XCTAssertEqual(a.parameterAddress, ParameterAddress.one.rawValue)

    a.setParameterAddress(ParameterAddress(rawValue: 99))
    XCTAssertEqual(a.parameterAddress, 0)
  }
}
