import AudioUnit
import XCTest
@testable import AUv3Support

fileprivate enum ParameterAddress: UInt64, ParameterAddressProvider {
  var parameterAddress: AUParameterAddress { rawValue }
  case one = 1234
  case two
}

@MainActor
fileprivate class Blob: NSObject, ParameterAddressHolder {
  var parameterAddress: AUParameterAddress = 0
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
    let param = a.parameter
    XCTAssertFalse(param.flags.contains(.flag_CanRamp))
    XCTAssertTrue(param.flags.contains(.flag_IsReadable))
    XCTAssertTrue(param.flags.contains(.flag_IsWritable))
    XCTAssertFalse(param.flags.contains(.flag_DisplayLogarithmic))
  }

  @MainActor
  func testParameterAddressHolder() throws {
    let blob = Blob()
    blob.setParameterAddress(ParameterAddress.one)
    XCTAssertEqual(blob.parameterAddress, 1234)
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

    let b = ParameterDefinition.defPercent("bar", localized: "La Bar", address: ParameterAddress.two, minValue: 10.0)
    XCTAssertEqual(b.range.lowerBound, 10.0)
    XCTAssertEqual(b.range.upperBound, 100.0)

    let c = ParameterDefinition.defPercent("bar", localized: "La Bar", address: ParameterAddress.two, maxValue: 50.0)
    XCTAssertEqual(c.range.lowerBound, 0.0)
    XCTAssertEqual(c.range.upperBound, 50.0)

    let d = ParameterDefinition.defPercent("bar", localized: "La Bar", address: ParameterAddress.two, minValue: 23.0,
                                           maxValue: 92.5)
    XCTAssertEqual(d.range.lowerBound, 23.0)
    XCTAssertEqual(d.range.upperBound, 92.5)
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

    let param = a.parameter
    XCTAssertTrue(param.flags.contains(.flag_CanRamp))
    XCTAssertTrue(param.flags.contains(.flag_IsReadable))
    XCTAssertTrue(param.flags.contains(.flag_IsWritable))
    XCTAssertTrue(param.flags.contains(.flag_DisplayLogarithmic))
  }
}
