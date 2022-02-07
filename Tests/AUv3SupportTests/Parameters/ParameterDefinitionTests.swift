import AudioUnit
import XCTest
@testable import AUv3Support

fileprivate enum ParameterAddress: UInt64, ParameterAddressProvider {
  var parameterAddress: AUParameterAddress { rawValue }
  case one = 1234
  case two
}

final class ParameterDefinitionTests: XCTestCase {

  func testBoolDef() throws {
    let a = ParameterDefinition.defBool("foo", localized: "Le Foo", address: ParameterAddress.one)
    XCTAssertEqual(a.identifier, "foo")
    XCTAssertEqual(a.localized, "Le Foo")
    XCTAssertEqual(a.unit, .boolean)
    XCTAssertEqual(a.range.lowerBound, 0.0)
    XCTAssertEqual(a.range.upperBound, 1.0)
    XCTAssertFalse(a.ramping)
    XCTAssertFalse(a.logScale)
  }

  func testPercentDef() throws {
    let a = ParameterDefinition.defPercent("bar", localized: "La Bar", address: ParameterAddress.two)
    XCTAssertEqual(a.identifier, "bar")
    XCTAssertEqual(a.localized, "La Bar")
    XCTAssertEqual(a.unit, .percent)
    XCTAssertEqual(a.range.lowerBound, 0.0)
    XCTAssertEqual(a.range.upperBound, 100.0)
    XCTAssertTrue(a.ramping)
    XCTAssertFalse(a.logScale)
  }

  func testFloatDef() throws {
    let a = ParameterDefinition.defFloat("float", localized: "Floaty", address: ParameterAddress.one,
                                         range: 10...32, unit: .hertz, logScale: true)
    XCTAssertEqual(a.identifier, "float")
    XCTAssertEqual(a.localized, "Floaty")
    XCTAssertEqual(a.unit, .hertz)
    XCTAssertEqual(a.range.lowerBound, 10.0)
    XCTAssertEqual(a.range.upperBound, 32.0)
    XCTAssertTrue(a.ramping)
    XCTAssertTrue(a.logScale)
  }
}
