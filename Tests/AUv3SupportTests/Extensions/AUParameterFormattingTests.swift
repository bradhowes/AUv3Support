// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

private struct formatter: AUParameterFormatting, ParameterAddressProvider {
  var suffix: String { return " abc" }
  var parameterAddress: AUParameterAddress { 123 }
}

private let paramDef = ParameterDefinition.defPercent("def", localized: "def", address: formatter())
private let param = paramDef.parameter

class AUParameterFormattingTests: XCTestCase {

  override func setUp() {}
  override func tearDown() {}

  func testDisplayValueFormatter() throws {
    XCTAssertEqual(formatter().displayValueFormatter(1.2345), "1.235 abc")
  }

  func testEditingValueFormatter() throws {
    XCTAssertEqual(formatter().editingValueFormatter(1.2345), "1.23")
  }

  func testParamFormatting() throws {
    param.value = 3.14159
    XCTAssertEqual(param.displayValueFormatter(param.value), "3.142 %")
    XCTAssertEqual(param.editingValueFormatter(param.value), "3.14")
  }
}
