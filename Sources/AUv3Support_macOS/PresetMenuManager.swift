// Copyright © 2022 Brad Howes. All rights reserved.

import Cocoa
import AUv3Support
import AudioToolbox

enum UserMenuItem: Int {
  case save
  case update
  case rename
  case delete
}

public class PresetsMenuManager: NSObject {
  private let noCurrentPreset = Int.max
  private let commandTag = Int.max - 1

  private let button: NSPopUpButton
  private let appMenu: NSMenu
  private let userPresetsManager: UserPresetsManager

  public init(button: NSPopUpButton, appMenu: NSMenu, userPresetsManager: UserPresetsManager) {
    self.button = button
    self.appMenu = appMenu
    self.userPresetsManager = userPresetsManager
    super.init()
  }

  public func build() {
    guard let buttonMenu = button.menu else { fatalError() }
    populateUserPresetsMenu(appMenu.items[0].submenu!)
    populateFactoryPresetsMenu(appMenu.items[1].submenu!)
    populateUserPresetsMenu(buttonMenu.items[1].submenu!)
    populateFactoryPresetsMenu(buttonMenu.items[2].submenu!)
  }

  public func selectActive() {
    let activeNumber = userPresetsManager.audioUnit.currentPreset?.number ?? noCurrentPreset
    refreshUserPresetsMenu(appMenu.items[0].submenu, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(appMenu.items[1].submenu, activeNumber: activeNumber)
    refreshUserPresetsMenu(button.menu?.items[1].submenu, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(button.menu?.items[2].submenu, activeNumber: activeNumber)
  }
}

extension PresetsMenuManager {

  @IBAction func handlePresetMenuSelection(_ sender: NSMenuItem) {
    userPresetsManager.makeCurrentPreset(number: sender.tag)
    appMenu.items.forEach { $0.state = .off }
    sender.state = .on
  }

  @IBAction func savePreset(_ sender: NSMenuItem) {
    guard let presetName = getNewPresetName(default: "Preset \(-userPresetsManager.nextNumber)") else { return }
    try? userPresetsManager.create(name: presetName)
    build()
  }

  @IBAction func updatePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset, activePreset.number < 0 else { fatalError() }
    try? userPresetsManager.update(preset: activePreset)
  }

  @IBAction func renamePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset else { fatalError() }
    guard let presetName = getRenamePresetName(existing: activePreset.name) else { return }
    try? userPresetsManager.renameCurrent(to: presetName)
    build()
  }

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

    menu.addItem(withTitle: "New", action: #selector(savePreset(_:)), keyEquivalent: "n")
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
