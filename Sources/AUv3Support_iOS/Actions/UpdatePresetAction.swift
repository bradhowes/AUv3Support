// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import UIKit

extension HostViewController {

  struct UpdatePresetAction {
    weak var viewController: HostViewController?
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: HostViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
    }

    func start(_ action: UIAction) {
      do {
        try userPresetsManager.update(preset: userPresetsManager.currentPreset!)
      } catch {
        viewController?.notify(title: "Update Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}
