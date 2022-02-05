// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import UIKit

extension HostViewController {

  struct DeletePreset {
    unowned let actionSupporter: ActionSupporter
    let presetsManager: UserPresetsManager

    init(_ actionSupporter: ActionSupporter, presetsManager: UserPresetsManager) {
      self.actionSupporter = actionSupporter
      self.presetsManager = presetsManager
    }

    func handler(_ action: UIAction) {
      actionSupporter.confirmAction(
        title: "Delete Preset", message: "Do you wish to delete the preset? This cannot be undone.", deletePreset)
    }

    func deletePreset() {
      do {
        try presetsManager.deleteCurrent()
      } catch {
        actionSupporter.notifyFailure(title: "Delete Error", message: error.localizedDescription)
      }
      actionSupporter.completeAction()
    }
  }
}

#endif
