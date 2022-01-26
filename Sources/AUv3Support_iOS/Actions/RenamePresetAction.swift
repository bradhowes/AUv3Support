// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import UIKit

extension HostViewController {

  struct RenamePresetAction {
    weak var viewController: HostViewController?
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: HostViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "Rename Preset", message: nil, preferredStyle: .alert)
      controller.addTextField { textField in textField.placeholder = "New Name" }
      controller.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
        guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty
        else {
          return
        }
        self.renamePreset(with: name)
      })

      controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      viewController?.present(controller, animated: true)
    }

    func renamePreset(with name: String) {
      do {
        try userPresetsManager.renameCurrent(to: name)
      } catch {
        viewController?.notify(title: "Rename Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}