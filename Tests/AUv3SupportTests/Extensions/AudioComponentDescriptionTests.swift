// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

class AudioComponentDescriptionTests: XCTestCase {
  override func setUp() {}
  override func tearDown() {}

  func testDescription() {
    let acd = AudioComponentDescription(componentType: .init("aufx"), componentSubType: .init("abcd"),
                                        componentManufacturer: .init("appl"), componentFlags: 1, componentFlagsMask: 2)
    let description = acd.description
    XCTAssertEqual(description,
                   "<AudioComponentDescription type: 'aufx' subtype: 'abcd' manufacturer: 'appl' flags: 1 mask: 2>")
  }

  func testEquality() {
    let acd1 = AudioComponentDescription(componentType: .init("aufx"), componentSubType: .init("abcd"),
                                         componentManufacturer: .init("appl"), componentFlags: 1, componentFlagsMask: 2)
    let acd2 = AudioComponentDescription(componentType: .init("aufx"), componentSubType: .init("abcd"),
                                         componentManufacturer: .init("appl"), componentFlags: 1, componentFlagsMask: 2)
    XCTAssertEqual(acd1, acd2)

    XCTAssertNotEqual(AudioComponentDescription(componentType: .init("aufX"),
                                                componentSubType: .init("abcd"),
                                                componentManufacturer: .init("appl"),
                                                componentFlags: 1,
                                                componentFlagsMask: 2),
                      acd1)
    XCTAssertNotEqual(AudioComponentDescription(componentType: .init("aufx"),
                                                componentSubType: .init("abcD"),
                                                componentManufacturer: .init("appl"),
                                                componentFlags: 1,
                                                componentFlagsMask: 2),
                      acd1)
    XCTAssertNotEqual(AudioComponentDescription(componentType: .init("aufx"),
                                                componentSubType: .init("abcd"),
                                                componentManufacturer: .init("appL"),
                                                componentFlags: 1,
                                                componentFlagsMask: 2),
                      acd1)
    XCTAssertNotEqual(AudioComponentDescription(componentType: .init("aufx"),
                                                componentSubType: .init("abcd"),
                                                componentManufacturer: .init("appl"),
                                                componentFlags: 2,
                                                componentFlagsMask: 2),
                      acd1)
    XCTAssertNotEqual(AudioComponentDescription(componentType: .init("aufx"),
                                                componentSubType: .init("abcd"),
                                                componentManufacturer: .init("appl"),
                                                componentFlags: 1,
                                                componentFlagsMask: 3),
                      acd1)
  }
}
