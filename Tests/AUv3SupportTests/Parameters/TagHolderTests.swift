import AudioUnit
import XCTest
@testable import AUv3Support

fileprivate enum ParameterAddress: UInt64 {
  var parameterAddress: AUParameterAddress { rawValue }
  case one = 1234
  case two
}

fileprivate extension TagHolder {
  func setParameterAddress(_ address: ParameterAddress) { tag = Int(address.rawValue) }
  var parameterAddress: ParameterAddress? { tag >= 0 ? ParameterAddress(rawValue: UInt64(tag)) : nil }
}

fileprivate class SomeObject: NSObject, TagHolder {
  var tag: Int = 0
}

final class TagHolderTests: XCTestCase {

  func testAPI() throws {
    let a = SomeObject()
    XCTAssertEqual(a.tag, 0)

    a.setParameterAddress(ParameterAddress.one)
    XCTAssertEqual(a.parameterAddress, ParameterAddress.one)

    a.tag = -1
    XCTAssertNil(a.parameterAddress)

    a.tag = 99
    XCTAssertNil(a.parameterAddress)
  }
}
