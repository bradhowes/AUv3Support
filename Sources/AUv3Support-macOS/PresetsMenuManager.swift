// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)

import AppKit
import AUv3Support
import AudioToolbox
import os.log

public enum UserMenuItem: Int {
  case new = 0 // Code expects that the commands start at the top of the menu
  case save
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
@MainActor
public class PresetsMenuManager: NSObject {
  private let log = Shared.logger("PresetsMenuManager")
  private let noCurrentPreset = Int.max
  private let commandTag = Int.max - 1

  private let button: NSPopUpButton
  private let appMenu: NSMenu
  private let userPresetsManager: UserPresetsManager
  private let support: PresetsMenuManagerSupport
  private var userPresetsObserverToken: NSKeyValueObservation?
  
  private struct DefaultSupport: PresetsMenuManagerSupport {}

  /**
   Construct a new manager.

   - parameter button: the `NSPopUpButton` whose menus we will manage
   - parameter appMenu: the `NSMenu` from the app's menu bar whose sub menus we will manage
   - parameter userPresetsManager: the manager for the user presets of the audio unit
   */
  public init(button: NSPopUpButton, appMenu: NSMenu, userPresetsManager: UserPresetsManager,
              support: PresetsMenuManagerSupport? = nil) {
    precondition(appMenu.items.count > 1 &&
                 appMenu.items[0].submenu != nil &&
                 appMenu.items[1].submenu != nil &&
                 button.menu != nil &&
                 button.menu!.items.count > 2 &&
                 button.menu!.items[1].submenu != nil &&
                 button.menu!.items[2].submenu != nil)
    self.button = button
    self.appMenu = appMenu
    self.userPresetsManager = userPresetsManager
    self.support = support ?? DefaultSupport()
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
    selectActive()
  }

  /**
   Update the menus to show the active preset.
   */
  public func selectActive() {
    let activeNumber = userPresetsManager.audioUnit.currentPreset?.number ?? noCurrentPreset
    refreshUserPresetsMenu(appMenu.items[0].submenu!, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(appMenu.items[1].submenu!, activeNumber: activeNumber)
    refreshUserPresetsMenu(button.menu!.items[1].submenu!, activeNumber: activeNumber)
    refreshFactoryPresetsMenu(button.menu!.items[2].submenu!, activeNumber: activeNumber)
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
    support.askForName(title: "New Preset", placeholder: "Preset \(-userPresetsManager.nextNumber)",
                       activity: "Create") { newName in
      if let existing = self.userPresetsManager.find(name: newName) {
        self.support.confirmAction(title: "Update \"\(newName)\"?",
                                   message: "Do you wish to update the existing preset with current settings?") {
          try? self.userPresetsManager.update(preset: existing)
        }
      } else {
        try? self.userPresetsManager.create(name: newName)
      }
    }
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
    support.askForName(title: "Rename Preset", placeholder: activePreset.name, activity: "Rename") { newName in
      try? self.userPresetsManager.renameCurrent(to: newName)
    }
  }

  /**
   Delete the current user preset.

   - parameter sender: the 'Delete' menu item
   */
  @IBAction func deletePreset(_ sender: NSMenuItem) {
    guard let activePreset = userPresetsManager.currentPreset else { fatalError() }
    support.confirmAction(
      title: "Delete \"\(activePreset.name)\" Preset",
      message: "Do you wish to delete the preset? This cannot be undone.") {
        try? self.userPresetsManager.deleteCurrent()
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
      let keyEquivalent = index < 9 ? "\(index + 1)" : ""
      let item = NSMenuItem(title: preset.name, action: #selector(handlePresetMenuSelection),
                            keyEquivalent: keyEquivalent)
      item.target = self
      item.tag = preset.number
      menu.addItem(item)
    }
  }

  func refreshUserPresetsMenu(_ menu: NSMenu, activeNumber: Int) {
    menu.items[.new].isEnabled = true
    menu.items[.save].isEnabled = activeNumber < 0
    menu.items[.rename].isEnabled = activeNumber < 0
    menu.items[.delete].isEnabled = activeNumber < 0
    menu.items.forEach { item in
      item.state = item.tag == activeNumber ? .on : .off
    }
  }

  func refreshFactoryPresetsMenu(_ menu: NSMenu, activeNumber: Int) {
    menu.items.forEach { item in
      item.state = item.tag == activeNumber ? .on : .off
    }
  }
}

extension Array where Element == NSMenuItem {
  public subscript(_ index: UserMenuItem) -> NSMenuItem {
    self[index.rawValue]
  }
}

@MainActor
public protocol PresetsMenuManagerSupport {
  func askForName(title: String, placeholder: String, activity: String, closure: @escaping (String) -> Void)
  func confirmAction(title: String, message: String, confirmed: @escaping () -> Void)
}

extension PresetsMenuManagerSupport {

  func askForName(title: String, placeholder: String, activity: String, closure: @escaping (String) -> Void) {
    let prompt = NSAlert()
    prompt.addButton(withTitle: activity)
    prompt.buttons.last?.tag = NSApplication.ModalResponse.OK.rawValue

    prompt.addButton(withTitle: "Cancel")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.cancel.rawValue

    prompt.messageText = title
    prompt.informativeText = "Enter the preset name:"

    let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    textField.stringValue = placeholder
    prompt.accessoryView = textField
    prompt.window.initialFirstResponder = textField

    let response: NSApplication.ModalResponse = prompt.runModal()
    if response == .OK {
      let value = textField.stringValue.trimmingCharacters(in: .whitespaces)
      if !value.isEmpty {
        closure(value)
      }
    }
  }

  func confirmAction(title: String, message: String, confirmed: @escaping () -> Void) {
    let prompt = NSAlert()
    prompt.alertStyle = .warning
    prompt.messageText = title
    prompt.informativeText = message
    prompt.addButton(withTitle: "Cancel")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.cancel.rawValue
    prompt.addButton(withTitle: "Confirm")
    prompt.buttons.last?.tag = NSApplication.ModalResponse.OK.rawValue
    if #available(macOS 11.0, *) {
      prompt.buttons.last?.hasDestructiveAction = true
    }

    let response: NSApplication.ModalResponse = prompt.runModal()
    if response == .OK {
      confirmed()
    }
  }
}

#endif
