// Copyright © 2021 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit

extension HostViewController {

  struct DeletePresetAction {
    let viewController: HostViewController
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: HostViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "Delete Preset",
                                         message: "Do you wish to delete the preset? This cannot be undone.",
                                         preferredStyle: .alert)
      controller.addAction(.init(title: "Cancel", style: .cancel))
      controller.addAction(.init(title: "Continue", style: .destructive) { _ in
        self.deletePreset()
      })
      viewController.present(controller, animated: true)
    }

    func deletePreset() {
      do {
        try userPresetsManager.deleteCurrent()
      } catch {
        viewController.notify(title: "Delete Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}

#endif
