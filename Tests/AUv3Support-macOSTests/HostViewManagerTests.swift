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

class HostViewManagerTests: XCTestCase {
  let componentName = "ComponentName"
  let componentDescription = AudioComponentDescription(componentType: .init("dely"),
                                                       componentSubType: .init("samp"),
                                                       componentManufacturer: .init("appl"),
                                                       componentFlags: 0,
                                                       componentFlagsMask: 0)
  let sampleLoop: AudioUnitLoader.SampleLoop = .sample1
  let playButton: NSButton = .init(title: "Play", target: nil, action: nil)
  let bypassButton: NSButton = .init(title: "Bypass", target: nil, action: nil)

  let playMenuItem = NSMenuItem(title: "Play", action: nil, keyEquivalent: "")
  let bypassMenuItem = NSMenuItem(title: "Bypass", action: nil, keyEquivalent: "")

  var presetsButton: NSPopUpButton!
  var appMenu: NSMenu!

  var viewController: MockViewController!
  var containerView: NSView!
  var config: HostViewConfig!

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

  override func setUp() {
    // let bundle = Bundle(for: AUv3Support_macOS.HostViewManager.self)
    // let storyboard = Storyboard(name: "HostView", bundle: bundle)
    // let windowController = NSWindowController(windowNibName: "HostView")
    // windowController.loadWindow()
    // viewController = windowController.contentViewController

    viewController = .init()
    containerView = .init()

    appMenu = makeAppMenu()
    presetsButton = .init()
    presetsButton.menu = makeButtonMenu()
    config = .init(componentName: componentName, componentVersion: "v1.2.3",
                   componentDescription: componentDescription, sampleLoop: sampleLoop,
                   playButton: playButton, bypassButton: bypassButton, presetsButton: presetsButton,
                   playMenuItem: playMenuItem, bypassMenuItem: bypassMenuItem, presetsMenu: appMenu,
                   viewController: viewController, containerView: containerView)
  }

  func testShowInstructions() {
    let hvm: HostViewManager = .init(config: config)
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertTrue(hvm.showInstructions)
    XCTAssertFalse(hvm.showInstructions)

    HostViewManager.alwaysShowInstructions = true
    XCTAssertTrue(hvm.showInstructions)
    userDefaults.removeObject(forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertTrue(hvm.showInstructions)
  }

  func testInit() {
    let hvm: HostViewManager = .init(config: config)
    XCTAssertNil(hvm.delegate)
  }

  func testShowInitialPromptOnlyOnce() {
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: HostViewManager.showedInitialAlertKey)

    var showedPrompt = false
    let prompter: HostViewManager.InstructionPrompter = {(viewController: NSViewController, prompt: String,
                                                          closure: @escaping () -> Void) in
      showedPrompt = true
      DispatchQueue.main.async { closure() }
    }

    let hvm: HostViewManager = .init(config: config)
    hvm.showInitialPrompt(prompter: prompter)
    XCTAssertTrue(showedPrompt)

    // Check that prompt is not shown again
    showedPrompt = false
    hvm.showInitialPrompt(prompter: prompter)
    XCTAssertFalse(showedPrompt)

    // Check that alwaysShowInstructions causes them to be shown
    HostViewManager.alwaysShowInstructions = true
    hvm.showInitialPrompt(prompter: prompter)
    XCTAssertTrue(showedPrompt)
  }

  func skip_testAccessAudioUnit() {
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
    let hvm: HostViewManager = .init(config: config)
    hvm.delegate = delegate

    wait(for: [expectation], timeout: 60)
  }
}

#endif
