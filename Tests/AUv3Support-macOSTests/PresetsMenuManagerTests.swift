#if os(macOS)

import XCTest
import AudioUnit
@testable import AUv3Support_macOS
@testable import AUv3Support

fileprivate class MockAudioUnit: NSObject, AUAudioUnitPresetsFacade {
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

class PresetsMenuManagerTests: XCTestCase {
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

  override func setUp() {
    audioUnit = MockAudioUnit()
    button = .init()
    support = .init()
    appMenu = makeAppMenu()
    button.menu = makeButtonMenu()

    upm = UserPresetsManager(for: audioUnit)
    pmm = PresetsMenuManager(button: button, appMenu: appMenu, userPresetsManager: upm, support: support)
    pmm.build()
  }

  func testBuild() {
    XCTAssertEqual(appMenu.items.count, 2)
    XCTAssertEqual(appMenu.items[0].title, "User")
    XCTAssertEqual(appMenu.items[0].submenu!.items.count, 8)
    XCTAssertEqual(appMenu.items[0].submenu!.items[.new].title, "New")
    XCTAssertTrue(appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertEqual(appMenu.items[0].submenu!.items[.save].title, "Save")
    XCTAssertFalse(appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertEqual(appMenu.items[0].submenu!.items[.rename].title, "Rename")
    XCTAssertFalse(appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertEqual(appMenu.items[0].submenu!.items[.delete].title, "Delete")
    XCTAssertFalse(appMenu.items[0].submenu!.items[.delete].isEnabled)
    XCTAssertTrue(appMenu.items[0].submenu!.items[4].isSeparatorItem)
    XCTAssertEqual(appMenu.items[0].submenu!.items[5].title, "A User 2")
    XCTAssertTrue(appMenu.items[0].submenu!.items[5].isEnabled)
    XCTAssertEqual(appMenu.items[0].submenu!.items[6].title, "Blah User 3")
    XCTAssertTrue(appMenu.items[0].submenu!.items[6].isEnabled)
    XCTAssertEqual(appMenu.items[0].submenu!.items[7].title, "The User 1")
    XCTAssertTrue(appMenu.items[0].submenu!.items[7].isEnabled)

    XCTAssertEqual(appMenu.items[1].title, "Factory")
    XCTAssertEqual(appMenu.items[1].submenu!.items.count, 2)
    XCTAssertEqual(appMenu.items[1].submenu!.items[0].title, "Zero")
    XCTAssertTrue(appMenu.items[1].submenu!.items[0].isEnabled)
    XCTAssertEqual(appMenu.items[1].submenu!.items[1].title, "One")
    XCTAssertTrue(appMenu.items[1].submenu!.items[1].isEnabled)

    XCTAssertEqual(button.menu!.items[1].submenu!.items.count, 8)
    XCTAssertEqual(button.menu!.items[2].submenu!.items.count, 2)
  }

  func testSelectUserPreset() {
    XCTAssertEqual(appMenu.items[0].submenu!.items[5].state, .off)
    pmm.handlePresetMenuSelection(appMenu.items[0].submenu!.items[5])
    XCTAssertEqual(appMenu.items[0].submenu!.items[5].state, .on)

    XCTAssertEqual(button.menu!.items[1].submenu!.items[5].state, .off)
    pmm.selectActive()
    XCTAssertEqual(button.menu!.items[1].submenu!.items[5].state, .on)

    XCTAssertTrue(appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertTrue(appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertTrue(appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertTrue(appMenu.items[0].submenu!.items[.delete].isEnabled)
  }

  func testSelectFactoryPreset() {

    // Select first factory preset
    XCTAssertEqual(appMenu.items[1].submenu!.items[0].state, .off)
    pmm.handlePresetMenuSelection(appMenu.items[1].submenu!.items[0])
    XCTAssertEqual(appMenu.items[1].submenu!.items[0].state, .on)

    XCTAssertEqual(button.menu!.items[2].submenu!.items[0].state, .off)
    pmm.selectActive()
    XCTAssertEqual(button.menu!.items[2].submenu!.items[0].state, .on)

    // Select second factory preset
    pmm.handlePresetMenuSelection(appMenu.items[1].submenu!.items[1])
    pmm.selectActive()

    XCTAssertEqual(appMenu.items[1].submenu!.items[0].state, .off)
    XCTAssertEqual(appMenu.items[1].submenu!.items[1].state, .on)
    XCTAssertEqual(button.menu!.items[2].submenu!.items[0].state, .off)
    XCTAssertEqual(button.menu!.items[2].submenu!.items[1].state, .on)

    XCTAssertTrue(appMenu.items[0].submenu!.items[.new].isEnabled)
    XCTAssertFalse(appMenu.items[0].submenu!.items[.save].isEnabled)
    XCTAssertFalse(appMenu.items[0].submenu!.items[.rename].isEnabled)
    XCTAssertFalse(appMenu.items[0].submenu!.items[.delete].isEnabled)
  }

  func testNewPreset() {
    pmm.createPreset(appMenu.items[0].submenu!.items[.new])
    pmm.build()
    XCTAssertEqual(button.menu!.items[1].submenu!.items.count, 9)
    XCTAssertEqual(button.menu!.items[1].submenu!.items[8].title, "Zaphod")
    XCTAssertEqual(audioUnit.changes.count, 1)
    XCTAssertEqual(audioUnit.changes[0].action, .new)
    XCTAssertEqual(audioUnit.changes[0].preset.name, "Zaphod")
    XCTAssertEqual(audioUnit.changes[0].preset.number, -1)
  }

  func testUpdatePreset() {
    pmm.createPreset(appMenu.items[0].submenu!.items[.new])
    pmm.build()
    pmm.updatePreset(appMenu.items[0].submenu!.items[.save])
    XCTAssertEqual(button.menu!.items[1].submenu!.items.count, 9)
    XCTAssertEqual(button.menu!.items[1].submenu!.items[8].title, "Zaphod")
    XCTAssertEqual(audioUnit.changes.count, 2)
    XCTAssertEqual(audioUnit.changes[1].action, .update)
    XCTAssertEqual(audioUnit.changes[1].preset.name, "Zaphod")
    XCTAssertEqual(audioUnit.changes[1].preset.number, -1)
  }

  func testDeletePreset() {
    pmm.createPreset(appMenu.items[0].submenu!.items[.new])
    pmm.build()
    pmm.deletePreset(appMenu.items[0].submenu!.items[.delete])
    pmm.build()
    XCTAssertEqual(button.menu!.items[1].submenu!.items.count, 8)
    XCTAssertEqual(audioUnit.changes.count, 2)
    XCTAssertEqual(audioUnit.changes[1].action, .delete)
    XCTAssertEqual(audioUnit.changes[1].preset.name, "Zaphod")
    XCTAssertEqual(audioUnit.changes[1].preset.number, -1)
  }

}

#endif
