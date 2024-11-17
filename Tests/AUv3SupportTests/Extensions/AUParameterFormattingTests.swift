// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

private struct formatter: AUParameterFormatting, ParameterAddressProvider {
  var suffix: String { return " abc" }
  var parameterAddress: AUParameterAddress { 123 }
}

private struct Context {
  let paramDef = ParameterDefinition.defPercent("def", localized: "def", address: formatter())
  lazy var param = paramDef.parameter
}

extension AUParameter {
  public var suffix: String { makeFormattingSuffix(from: unitName) }
}

class AUParameterFormattingTests: XCTestCase {

  override func setUp() {}
  override func tearDown() {}

  func testMakeFormattingSuffix() {
    XCTAssertEqual(formatter().makeFormattingSuffix(from: ""), "")
    XCTAssertEqual(formatter().makeFormattingSuffix(from: "foo"), " foo")
  }

  func testDisplayValueFormatter() throws {
    XCTAssertEqual(formatter().displayValueFormatter(1.2345), "1.23 abc")
  }

  func testEditingValueFormatter() throws {
    XCTAssertEqual(formatter().editingValueFormatter(1.2345), "1.235")
  }

  func testParamFormatting() throws {
    let paramDef = ParameterDefinition.defPercent("def", localized: "def", address: formatter())
    let param = paramDef.parameter
    param.value = 3.14159
    XCTAssertEqual(param.displayValueFormatter(param.value), "3.14 %")
    XCTAssertEqual(param.editingValueFormatter(param.value), "3.142")
  }
}

extension AUParameter: AUParameterFormatting {}
