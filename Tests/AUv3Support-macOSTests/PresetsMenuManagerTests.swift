#if os(macOS)

import XCTest
import AudioUnit
@testable import AUv3Support_macOS
@testable import AUv3Support

fileprivate class MockAudioUnit: NSObject, AUAudioUnitPresetsFacade {

  let supportsUserPresets: Bool = true

  static let log = Shared.logger("SubSystem", "Category")
  private let log = MockAudioUnit.log

  enum Action: Equatable {
    case new
    case update
    case rename
    case delete
  }

  struct Change: Equatable {
    let action: Action
    let preset: AUAudioUnitPreset

    init(action: Action, preset: AUAudioUnitPreset) {
      self.action = action
      self.preset = preset
    }
  }

  var factoryPresets: [AUAudioUnitPreset]? = [.init(number: 0, name: "Zero"),
                                              .init(number: 1, name: "One")
  ]
  var userPresets: [AUAudioUnitPreset] = [.init(number: -9, name: "The User 1"),
                                          .init(number: -4, name: "A User 2"),
                                          .init(number: -3, name: "Blah User 3")
  ]

  var currentPreset: AUAudioUnitPreset? = nil

  func saveUserPreset(_ preset: AUAudioUnitPreset) throws {
    if let found = userPresets.firstIndex(where: { $0.number == preset.number }) {
      userPresets[found] = preset
      changes.append(.init(action: .update, preset: preset))
    } else {
      userPresets.append(preset)
      changes.append(.init(action: .new, preset: preset))
    }
  }

  func deleteUserPreset(_ preset: AUAudioUnitPreset) throws {
    userPresets.removeAll { $0.number == preset.number }
    changes.append(.init(action: .delete, preset: preset))
  }

  var changes: [Change] = []
}

class MockPresetsMenuManagerSupport: PresetsMenuManagerSupport {
  var askForNameName: String = "Zaphod"
  var askForNameArgs: (String, String, String)?
  var confirmActionContinue: Bool = true
  var confirmActionArgs: (String, String)?

  func askForName(title: String, placeholder: String, activity: String, closure: @escaping (String) -> Void) {
    askForNameArgs = (title, placeholder, activity)
    closure(askForNameName)
  }

  func confirmAction(title: String, message: String, confirmed: @escaping () -> Void) {
    confirmActionArgs = (title, message)
    if confirmActionContinue {
      confirmed()
    }
  }
}

@MainActor
private final class Context {
  fileprivate var audioUnit: MockAudioUnit!
  var pmm: PresetsMenuManager!
  var upm: UserPresetsManager!
  var button: NSPopUpButton!
  var appMenu: NSMenu!
  var support: MockPresetsMenuManagerSupport!

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

  init() {
    audioUnit = MockAudioUnit()
    button = .init()
    support = .init()
    appMenu = makeAppMenu()
    button.menu = makeButtonMenu()

    upm = UserPresetsManager(for: audioUnit)
    pmm = PresetsMenuManager(button: button, appMenu: appMenu, userPresetsManager: upm, support: support)
    pmm.build()
  }
}

class PresetsMenuManagerTests: XCTestCase {

  @MainActor
  func testBuild() {
    let ctx = Context()

    XCTAssertEqual(ctx.appMenu.items.count, 2)
    XCTAssertEqual(ctx.appMenu.items[0].title, "User")
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items.count, 8)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[.new].title, "New")
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[.save].title, "Save")
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[.rename].title, "Rename")
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[.delete].title, "Delete")
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.delete].isEnabled)
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[4].isSeparatorItem)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[5].title, "A User 2")
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[5].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[6].title, "Blah User 3")
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[6].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[7].title, "The User 1")
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[7].isEnabled)

    XCTAssertEqual(ctx.appMenu.items[1].title, "Factory")
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items.count, 2)
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[0].title, "Zero")
    XCTAssertTrue(ctx.appMenu.items[1].submenu!.items[0].isEnabled)
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[1].title, "One")
    XCTAssertTrue(ctx.appMenu.items[1].submenu!.items[1].isEnabled)

    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items.count, 8)
    XCTAssertEqual(ctx.button.menu!.items[2].submenu!.items.count, 2)
  }

  @MainActor
  func testSelectUserPreset() {
    let ctx = Context()

    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[5].state, .off)
    ctx.pmm.handlePresetMenuSelection(ctx.appMenu.items[0].submenu!.items[5])
    XCTAssertEqual(ctx.appMenu.items[0].submenu!.items[5].state, .on)

    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items[5].state, .off)
    ctx.pmm.selectActive()
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items[5].state, .on)

    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.delete].isEnabled)
  }

  @MainActor
  func testSelectFactoryPreset() {
    let ctx = Context()

    // Select first factory preset
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[0].state, .off)
    ctx.pmm.handlePresetMenuSelection(ctx.appMenu.items[1].submenu!.items[0])
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[0].state, .on)

    XCTAssertEqual(ctx.button.menu!.items[2].submenu!.items[0].state, .off)
    ctx.pmm.selectActive()
    XCTAssertEqual(ctx.button.menu!.items[2].submenu!.items[0].state, .on)

    // Select second factory preset
    ctx.pmm.handlePresetMenuSelection(ctx.appMenu.items[1].submenu!.items[1])
    ctx.pmm.selectActive()

    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[0].state, .off)
    XCTAssertEqual(ctx.appMenu.items[1].submenu!.items[1].state, .on)
    XCTAssertEqual(ctx.button.menu!.items[2].submenu!.items[0].state, .off)
    XCTAssertEqual(ctx.button.menu!.items[2].submenu!.items[1].state, .on)

    XCTAssertTrue(ctx.appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertFalse(ctx.appMenu.items[0].submenu!.items[.delete].isEnabled)
  }

  @MainActor
  func testNewPreset() {
    let ctx = Context()

    ctx.pmm.createPreset(ctx.appMenu.items[0].submenu!.items[.new])
    ctx.pmm.build()
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items.count, 9)
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items[8].title, "Zaphod")
    XCTAssertEqual(ctx.audioUnit.changes.count, 1)
    XCTAssertEqual(ctx.audioUnit.changes[0].action, .new)
    XCTAssertEqual(ctx.audioUnit.changes[0].preset.name, "Zaphod")
    XCTAssertEqual(ctx.audioUnit.changes[0].preset.number, -1)
  }

  @MainActor
  func testUpdatePreset() {
    let ctx = Context()

    ctx.pmm.createPreset(ctx.appMenu.items[0].submenu!.items[.new])
    ctx.pmm.build()
    ctx.pmm.updatePreset(ctx.appMenu.items[0].submenu!.items[.save])
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items.count, 9)
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items[8].title, "Zaphod")
    XCTAssertEqual(ctx.audioUnit.changes.count, 2)
    XCTAssertEqual(ctx.audioUnit.changes[1].action, .update)
    XCTAssertEqual(ctx.audioUnit.changes[1].preset.name, "Zaphod")
    XCTAssertEqual(ctx.audioUnit.changes[1].preset.number, -1)
  }

  @MainActor
  func testDeletePreset() {
    let ctx = Context()

    ctx.pmm.createPreset(ctx.appMenu.items[0].submenu!.items[.new])
    ctx.pmm.build()
    ctx.pmm.deletePreset(ctx.appMenu.items[0].submenu!.items[.delete])
    ctx.pmm.build()
    XCTAssertEqual(ctx.button.menu!.items[1].submenu!.items.count, 8)
    XCTAssertEqual(ctx.audioUnit.changes.count, 2)
    XCTAssertEqual(ctx.audioUnit.changes[1].action, .delete)
    XCTAssertEqual(ctx.audioUnit.changes[1].preset.name, "Zaphod")
    XCTAssertEqual(ctx.audioUnit.changes[1].preset.number, -1)
  }

}

#endif
