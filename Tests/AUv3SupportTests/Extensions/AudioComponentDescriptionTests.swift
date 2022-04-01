// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

class AudioComponentDescriptionTests: XCTestCase {
  override func setUp() {}
  override func tearDown() {}

  func testDescription() {
    let acd = AudioComponentDescription(componentType: FourCharCode("aufx"), componentSubType: FourCharCode("abcd"), componentManufacturer: FourCharCode("appl"), componentFlags: 1, componentFlagsMask: 2)
    let description = acd.description
    XCTAssertEqual(description,
                   "<AudioComponentDescription type: 'aufx' subtype: 'abcd' manufacturer: 'appl' flags: 1 mask: 2>")
  }
}
