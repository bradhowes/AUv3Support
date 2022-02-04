// Copyright © 2022 Brad Howes. All rights reserved.

import Cocoa
import AUv3Support
import AudioToolbox

enum UserMenuItem: Int {
  case save = 0 // Code expects that the commands start at the top of the menu
  case update
  case rename
  case delete
}

/**
 Manages the preset menus in the macOS app. There are four menus that are managed by this class:
 - user presets in menu bar
 - user presets in pop-down button in main window title bar
 - factory presets in menu bar
 - factory presets in pop-down button in main window title bar

 The user menu starts off with four actions:
 - New -- create a new user preset using the current parameter settings
 - Save -- update active user preset with new parameter settings
 - Rename -- change the name of the active user preset
 - Delete -- delete the active user preset
 */
public class PresetsMenuManager: NSObject {
  private let noCurrentPreset = Int.max
  private let commandTag = Int.max - 1

  private let button: NSPopUpButton
  private let appMenu: NSMenu
  private let userPresetsManager: UserPresetsManager

  /**
   Construct a new manager.

   - parameter button: the `NSPopUpButton` whose menus we will manage
   - parameter appMenu: the `NSMenu` from the app's menu bar whose sub menus we will manage
   - parameter userPresetsManager: the manager for the user presets of the audio unit
   */
  public init(button: NSPopUpButton, appMenu: NSMenu, userPresetsManager: UserPresetsManager) {
    self.button = button
    self.appMenu = appMenu
    self.userPresetsManager = userPresetsManager
    super.init()
  }

  /**
   Populate the menus with the current presets.
   */
  public func build() {
    guard let buttonMenu = button.menu else { fatalError() }
    populateUserPresetsMenu(appMenu.items[0].submenu!)
    populateFactoryPresetsMenu(appMenu.items[1].submenu!)
    populateUserPresetsMenu(buttonMenu.items[1].submenu!)
    populateFactoryPresetsMenu(buttonMenu.items[2].submenu!)
  }

  /**
   Update the menus to show the active preset.
   */
  public func selectActive() {
    let activeNumber = userPresetsManager.audioUnit.currentPreset?.number ?? noCurrentPreset
    refreshUserPresetsMenu(appMenu.items[0].submenu, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(appMenu.items[1].submenu, activeNumber: activeNumber)
    refreshUserPresetsMenu(button.menu?.items[1].submenu, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(button.menu?.items[2].submenu, activeNumber: activeNumber)
  }
}

extension PresetsMenuManager {

  /**
   Make a preset active. The number of he preset is found in the NSMenuItem tag.

   - parameter sender: the NSMenuItem that represents to preset to activate
   */
  @IBAction func handlePresetMenuSelection(_ sender: NSMenuItem) {
    userPresetsManager.makeCurrentPreset(number: sender.tag)
    appMenu.items.forEach { $0.state = .off }
    sender.state = .on
  }

  /**
   Create a new user preset and make it active.

   - parameter sender: the 'New' menu item
   */
  @IBAction func createPreset(_ sender: NSMenuItem) {
    guard let presetName = getNewPresetName(default: "Preset \(-userPresetsManager.nextNumber)") else { return }
    try? userPresetsManager.create(name: presetName)
    build()
  }

  /**
   Update the current user preset.

   - parameter sender: the 'Update' menu item
   */
  @IBAction func updatePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset, activePreset.number < 0 else { fatalError() }
    try? userPresetsManager.update(preset: activePreset)
  }

  /**
   Rename the current user preset.

   - parameter sender: the 'Rename' menu item
   */
  @IBAction func renamePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset else { fatalError() }
    guard let presetName = getRenamePresetName(existing: activePreset.name) else { return }
    try? userPresetsManager.renameCurrent(to: presetName)
    build()
  }

  /**
   Delete the current user preset.

   - parameter sender: the 'Delete' menu item
   */
  @IBAction func deletePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset else { fatalError() }
    if confirmDelete(name: activePreset.name) {
      try? userPresetsManager.deleteCurrent()
      build()
    }
  }
}

private extension PresetsMenuManager {

  func populateFactoryPresetsMenu(_ menu: NSMenu) {
    menu.removeAllItems()
    userPresetsManager.audioUnit.factoryPresetsNonNil.forEach { preset in
      let item = NSMenuItem(title: preset.name, action: #selector(handlePresetMenuSelection), keyEquivalent: "")
      item.target = self
      item.tag = preset.number
      menu.addItem(item)
    }
  }

  func populateUserPresetsMenu(_ menu: NSMenu) {
    menu.removeAllItems()

    menu.addItem(withTitle: "New", action: #selector(createPreset(_:)), keyEquivalent: "n")
    menu.addItem(withTitle: "Save", action: #selector(updatePreset(_:)), keyEquivalent: "s")
    menu.addItem(withTitle: "Rename", action: #selector(renamePreset(_:)), keyEquivalent: "r")
    menu.addItem(withTitle: "Delete", action: #selector(deletePreset(_:)), keyEquivalent: "")

    menu.items.forEach { item in
      item.target = self
      item.tag = commandTag
      item.state = .off
      item.isEnabled = false
    }

    if !userPresetsManager.presets.isEmpty {
      menu.addItem(.separator())
    }

    for (index, preset) in userPresetsManager.presetsOrderedByName.enumerated() {
      let keyEquivalent = index < 10 ? "\(index)" : ""
      let item = NSMenuItem(title: preset.name, action: #selector(handlePresetMenuSelection),
                            keyEquivalent: keyEquivalent)
      item.target = self
      item.tag = preset.number
      menu.addItem(item)
    }
  }

  func refreshUserPresetsMenu(_ menu: NSMenu?, activeNumber: Int) {
    guard let menu = menu else { return }

    menu.items[.save].isEnabled = true
    menu.items[.update].isEnabled = activeNumber < 0
    menu.items[.rename].isEnabled = activeNumber < 0
    menu.items[.delete].isEnabled = activeNumber < 0

    menu.items.forEach { item in
      item.state = item.tag == activeNumber ? .on : .off
    }
  }

  func refreshFactoryPresetsMenu(_ menu: NSMenu?, activeNumber: Int) {
    guard let menu = menu else { return }
    menu.items.forEach { item in
      item.state = item.tag == activeNumber ? .on : .off
    }
  }

  func getNewPresetName(default: String) -> String? {
    let prompt = NSAlert()

    prompt.addButton(withTitle: "Continue")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.OK.rawValue

    prompt.addButton(withTitle: "Cancel")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.cancel.rawValue

    prompt.messageText = "New Preset Name"
    prompt.informativeText = "Enter the name to use for the new preset"

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.stringValue = `default`
    prompt.accessoryView = textField
    prompt.window.initialFirstResponder = textField

    let response: NSApplication.ModalResponse = prompt.runModal()
    if response == .OK {
      let value = textField.stringValue.trimmingCharacters(in: .whitespaces)
      return value.isEmpty ? nil : value
    }
    return nil
  }

  func getRenamePresetName(existing: String) -> String? {
    let prompt = NSAlert()
    prompt.addButton(withTitle: "Continue")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.OK.rawValue

    prompt.addButton(withTitle: "Cancel")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.cancel.rawValue

    prompt.messageText = "Change Preset Name"
    prompt.informativeText = "Enter the new name for the preset"

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.stringValue = existing
    prompt.accessoryView = textField
    prompt.window.initialFirstResponder = textField

    let response: NSApplication.ModalResponse = prompt.runModal()
    if response == .OK {
      let value = textField.stringValue.trimmingCharacters(in: .whitespaces)
      return value.isEmpty ? nil : value
    }
    return nil
  }

  func confirmDelete(name: String) -> Bool {
    let prompt = NSAlert()
    prompt.alertStyle = .warning
    prompt.addButton(withTitle: "Cancel")
    prompt.messageText = "Delete Preset \"\(name)\"?"
    prompt.informativeText = "Confirm to delete the preset."

    let button = prompt.addButton(withTitle: "Delete")
    if #available(macOS 11.0, *) {
      button.hasDestructiveAction = true
    }

    let response: NSApplication.ModalResponse = prompt.runModal()
    return response == .OK
  }
}

private extension Array where Element == NSMenuItem {
  subscript(_ index: UserMenuItem) -> NSMenuItem {
    self[index.rawValue]
  }
}
