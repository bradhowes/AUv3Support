// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import UIKit

extension HostViewController {

  @MainActor
  struct UpdatePreset {
    unowned let actionSupporter: ActionSupporter
    let presetsManager: UserPresetsManager

    init(_ actionSupporter: ActionSupporter, presetsManager: UserPresetsManager) {
      self.actionSupporter = actionSupporter
      self.presetsManager = presetsManager
    }

    func handler(_ action: UIAction) {
      guard let preset = presetsManager.currentPreset else { fatalError("nil current preset") }
      do {
        try presetsManager.update(preset: preset)
      } catch {
        actionSupporter.notifyFailure(title: "Update Error", message: error.localizedDescription)
      }
      actionSupporter.completeAction()
    }
  }
}

#endif
