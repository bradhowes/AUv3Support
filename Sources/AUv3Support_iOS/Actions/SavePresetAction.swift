// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import AudioUnit
import UIKit

extension HostViewController {

  struct CreatePresetAction {
    weak var viewController: HostViewController?
    let userPresetsManager: UserPresetsManager
    let completion: () -> Void

    init(_ viewController: HostViewController, completion: @escaping () -> Void) {
      self.viewController = viewController
      self.userPresetsManager = viewController.userPresetsManager!
      self.completion = completion
    }

    func start(_ action: UIAction) {
      let controller = UIAlertController(title: "New Preset", message: nil, preferredStyle: .alert)
      controller.addTextField { textField in textField.placeholder = "Preset Name" }
      controller.addAction(UIAlertAction(title: "Create", style: .default) { _ in
        guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) else { return }
        if !name.isEmpty {
          self.checkIsUniquePreset(named: name)
        }
      })

      controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      viewController?.present(controller, animated: true)
    }

    func checkIsUniquePreset(named name: String) {
      guard let existing = userPresetsManager.find(name: name) else {
        create(under: name)
        return
      }

      viewController?.yesOrNo(title: "Existing Preset",
                             message: "Do you wish to change the existing preset to have the current settings?") { _ in
        self.update(preset: existing)
      }
    }

    func create(under name: String) {
      do {
        try userPresetsManager.create(name: name)
      } catch {
        viewController?.notify(title: "Save Error", message: error.localizedDescription)
      }
      completion()
    }

    func update(preset: AUAudioUnitPreset) {
      do {
        try userPresetsManager.update(preset: preset)
      } catch {
        viewController?.notify(title: "Update Error", message: error.localizedDescription)
      }
      completion()
    }
  }
}
