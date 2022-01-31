// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import AudioUnit
import UIKit

extension HostViewController {

  struct CreatePreset {
    unowned let actionSupporter: ActionSupporter // The action never outlives this
    let presetsManager: UserPresetsManager

    init(_ actionSupporter: ActionSupporter, presetsManager: UserPresetsManager) {
      self.actionSupporter = actionSupporter
      self.presetsManager = presetsManager
    }

    func start(_ action: UIAction) {
      actionSupporter.askForName(title: "New Preset", placeholder: "Preset Name", activity: "Create") { name in
        self.checkIsUniquePreset(named: name)
      }
    }

    func checkIsUniquePreset(named name: String) {
      guard let existing = presetsManager.find(name: name) else {
        create(under: name)
        return
      }

      actionSupporter.confirmAction(
        title: "Existing Preset",
        message: "Do you wish to change the existing preset to have the current settings?") {
          self.update(preset: existing)
        }
    }

    func create(under name: String) {
      do {
        try presetsManager.create(name: name)
      } catch {
        actionSupporter.notifyFailure(title: "Save Error", message: error.localizedDescription)
      }
      actionSupporter.completeAction()
    }

    func update(preset: AUAudioUnitPreset) {
      do {
        try presetsManager.update(preset: preset)
      } catch {
        actionSupporter.notifyFailure(title: "Save Error", message: error.localizedDescription)
      }
      actionSupporter.completeAction()
    }
  }
}
