// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import UIKit

extension HostViewController {

  struct RenamePreset {
    unowned let actionSupporter: ActionSupporter
    let presetsManager: UserPresetsManager

    init(_ actionSupporter: ActionSupporter, presetsManager: UserPresetsManager) {
      self.actionSupporter = actionSupporter
      self.presetsManager = presetsManager
    }

    func handler(_ action: UIAction) {
      guard let name = presetsManager.currentPreset?.name else { fatalError() }
      actionSupporter.askForName(title: "Rename Preset", placeholder: name, activity: "Rename") {
        self.renamePreset(with: $0)
      }
    }

    func renamePreset(with name: String) {
      do {
        try presetsManager.renameCurrent(to: name)
      } catch {
        actionSupporter.notifyFailure(title: "Rename Error", message: error.localizedDescription)
      }
      actionSupporter.completeAction()
    }
  }
}

#endif
