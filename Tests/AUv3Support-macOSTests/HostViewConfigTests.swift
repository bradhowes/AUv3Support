#if os(macOS)

import XCTest
@testable import AUv3Support_macOS
import Foundation
import AVFoundation

@MainActor
private final class Context {
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
  lazy var config = HostViewConfig(componentName: "componentName",
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
}

class HostViewConfigTests: XCTestCase {

  @MainActor
  func testInit() {
    let ctx = Context()
    let config = ctx.config

    XCTAssertEqual("componentName", config.componentName)
    XCTAssertEqual(ctx.acd, config.componentDescription)
    XCTAssertTrue(ctx.play === config.playButton)
    XCTAssertTrue(ctx.bypass === config.bypassButton)
    XCTAssertTrue(ctx.presets === config.presetsButton)
    XCTAssertTrue(ctx.playMenuItem === config.playMenuItem)
    XCTAssertTrue(ctx.bypassMenuItem === config.bypassMenuItem)
    XCTAssertTrue(ctx.presetsMenu === config.presetsMenu)
    XCTAssertTrue(ctx.viewController === config.viewController)
    XCTAssertTrue(ctx.containerView === config.containerView)
  }
}

#endif
