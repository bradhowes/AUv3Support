// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

private struct formatter: AUParameterFormatting {
  public var unitSeparator: String { " " }
  public var suffix: String { "blah" }
  public var stringFormatForDisplayValue: String { "%.3f" }
}

class AUParameterFormattingTests: XCTestCase {

  override func setUp() {}
  override func tearDown() {}

  func testDisplayValueFormatter() throws {
    XCTAssertEqual(formatter().displayValueFormatter(1.2345), "1.235 blah")
  }

  func testEditingValueFormatter() throws {
    XCTAssertEqual(formatter().editingValueFormatter(1.2345), "1.23")
  }

}
