#if os(macOS)

import XCTest
@testable import AUv3Support
@testable import AUv3Support_macOS
import AVFoundation

class MockAppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet weak var playMenuItem: NSMenuItem!
  @IBOutlet weak var bypassMenuItem: NSMenuItem!
  @IBOutlet weak var presetsMenu: NSMenu!
}

class MockWindowController: NSWindowController {
  @IBOutlet weak var playButton: NSToolbarItem!
  @IBOutlet weak var bypassButton: NSToolbarItem!
  @IBOutlet weak var presetSButton: NSToolbarItem!
}

class MockViewController: NSViewController {
  @IBOutlet weak var containerView: NSView!
  @IBOutlet weak var loadingText: NSTextField!
}

@MainActor
private final class Context {
  let componentName = "ComponentName"
  let componentDescription = AudioComponentDescription(componentType: .init("dely"),
                                                       componentSubType: .init("samp"),
                                                       componentManufacturer: .init("appl"),
                                                       componentFlags: 0,
                                                       componentFlagsMask: 0)
  let sampleLoop: SampleLoop = .sample1
  let playButton: NSButton = .init(title: "Play", target: nil, action: nil)
  let bypassButton: NSButton = .init(title: "Bypass", target: nil, action: nil)

  let playMenuItem = NSMenuItem(title: "Play", action: nil, keyEquivalent: "")
  let bypassMenuItem = NSMenuItem(title: "Bypass", action: nil, keyEquivalent: "")

  var presetsButton: NSPopUpButton!
  var appMenu: NSMenu!

  var viewController: MockViewController!
  var containerView: NSView!
  var config: HostViewConfig!

  init() {
    viewController = .init()
    containerView = .init()

    appMenu = makeAppMenu()
    presetsButton = .init()
    presetsButton.menu = makeButtonMenu()
    config = makeConfig()
  }

  func makeAppMenu() -> NSMenu {
    let menu = NSMenu()
    let userItem = menu.addItem(withTitle: "User", action: nil, keyEquivalent: "")
    userItem.submenu = NSMenu()
    let factoryItem = menu.addItem(withTitle: "Factory", action: nil, keyEquivalent: "")
    factoryItem.submenu = NSMenu()
    return menu
  }

  func makeButtonMenu() -> NSMenu {
    let menu = NSMenu()
    menu.addItem(withTitle: "Hi", action: nil, keyEquivalent: "")
    let userItem = menu.addItem(withTitle: "User", action: nil, keyEquivalent: "")
    userItem.submenu = NSMenu()
    let factoryItem = menu.addItem(withTitle: "Factory", action: nil, keyEquivalent: "")
    factoryItem.submenu = NSMenu()
    return menu
  }

  func makeConfig(alwaysShowNotice: Bool = false,
                  defaults: UserDefaults = .standard) -> HostViewConfig {
    return .init(componentName: componentName,
                 componentDescription: componentDescription, sampleLoop: sampleLoop,
                 playButton: playButton, bypassButton: bypassButton, presetsButton: presetsButton,
                 playMenuItem: playMenuItem, bypassMenuItem: bypassMenuItem, presetsMenu: appMenu,
                 viewController: viewController, containerView: containerView,
                 alwaysShowNotice: alwaysShowNotice, defaults: defaults)
  }
}

class HostViewManagerTests: XCTestCase {

  @MainActor
  func testShowInstructionsOnce() {
    let ctx = Context()
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    let config = ctx.makeConfig(defaults: defaults)
    let hvm = HostViewManager(config: config)
    XCTAssertTrue(hvm.showInstructions)
    XCTAssertFalse(hvm.showInstructions)
  }

  @MainActor
  func testShowInstructionsWhenVersionChanges() {
    let ctx = Context()
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    defaults.set("v1.2.3", forKey: HostViewManager.showedInitialAlertKey)
    do {
      let config = ctx.makeConfig(defaults: defaults)
      let hvm = HostViewManager(config: config)
      XCTAssertTrue(hvm.showInstructions)
    }
    do {
      let config = ctx.makeConfig(defaults: defaults)
      let hvm = HostViewManager(config: config)
      XCTAssertFalse(hvm.showInstructions)
    }
  }

  @MainActor
  func testAlwaysShowInstructions() {
    let ctx = Context()
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    defaults.set("v1.2.3", forKey: HostViewManager.showedInitialAlertKey)
    do {
      let config = ctx.makeConfig(alwaysShowNotice: true, defaults: defaults)
      let hvm = HostViewManager(config: config)
      XCTAssertTrue(hvm.showInstructions)
      XCTAssertTrue(hvm.showInstructions)
    }
    do {
      let config = ctx.makeConfig(alwaysShowNotice: false, defaults: defaults)
      let hvm = HostViewManager(config: config)
      XCTAssertFalse(hvm.showInstructions)
    }
  }

  @MainActor
  func testInit() {
    let ctx = Context()
    let hvm: HostViewManager = .init(config: ctx.config)
    XCTAssertNil(hvm.delegate)
  }

  @MainActor
  func testShowInitialPromptOnlyOnce() {
    let ctx = Context()
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!

    var showedPrompt = false
    let prompter: HostViewManager.InstructionPrompter = {(viewController: NSViewController, prompt: String,
                                                          closure: @escaping () -> Void) in
      showedPrompt = true
      DispatchQueue.main.async { closure() }
    }

    let hvm: HostViewManager = .init(config: ctx.makeConfig(defaults: defaults))
    hvm.showInitialPrompt(prompter: prompter)
    XCTAssertTrue(showedPrompt)

    // Check that prompt is not shown again
    showedPrompt = false
    hvm.showInitialPrompt(prompter: prompter)
    XCTAssertFalse(showedPrompt)
  }

  @MainActor
  func skip_testAccessAudioUnit() {
    let ctx = Context()
    class MockHostViewManagerDelegate: HostViewManagerDelegate {
      let expectation: XCTestExpectation

      init(expectation: XCTestExpectation) {
        self.expectation = expectation
      }

      func failed(error: AUv3Support.AudioUnitLoaderError) {
      }

      func connected() {
        expectation.fulfill()
      }
    }

    let expectation = XCTestExpectation()
    let delegate = MockHostViewManagerDelegate(expectation: expectation)
    let hvm: HostViewManager = .init(config: ctx.config)
    hvm.delegate = delegate

    wait(for: [expectation], timeout: 60)
  }
}

#endif
