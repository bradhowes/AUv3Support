#if os(macOS)

import XCTest
@testable import AUv3Support_macOS
import Foundation
import AVFoundation

class HostViewConfigTests: XCTestCase {

  func testInit() {
    let acd: AudioComponentDescription = .init(componentType: .init("abcd"), componentSubType: .init("efgh"),
                                               componentManufacturer: .init("ijkl"), componentFlags: 0,
                                               componentFlagsMask: 0)
    let play: NSButton = .init()
    let bypass: NSButton = .init()
    let presets: NSPopUpButton = .init()
    let playMenuItem: NSMenuItem = .init()
    let bypassMenuItem: NSMenuItem = .init()
    let presetsMenu: NSMenu = .init()
    let viewController: NSViewController = .init()
    let containerView: NSView = .init()
    let config = HostViewConfig(componentName: "componentName",
                                componentVersion: "v1.2.3",
                                componentDescription: acd,
                                sampleLoop: .sample1,
                                playButton: play,
                                bypassButton: bypass,
                                presetsButton: presets,
                                playMenuItem: playMenuItem,
                                bypassMenuItem: bypassMenuItem,
                                presetsMenu: presetsMenu,
                                viewController: viewController,
                                containerView: containerView)
    XCTAssertEqual("componentName", config.componentName)
    XCTAssertEqual("v1.2.3", config.componentVersion)
    XCTAssertEqual(acd, config.componentDescription)
    XCTAssertTrue(play === config.playButton)
    XCTAssertTrue(bypass === config.bypassButton)
    XCTAssertTrue(presets === config.presetsButton)
    XCTAssertTrue(playMenuItem === config.playMenuItem)
    XCTAssertTrue(bypassMenuItem === config.bypassMenuItem)
    XCTAssertTrue(presetsMenu === config.presetsMenu)
    XCTAssertTrue(viewController === config.viewController)
    XCTAssertTrue(containerView === config.containerView)
  }
}

#endif
