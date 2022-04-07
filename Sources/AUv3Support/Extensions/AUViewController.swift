// Copyright © 2022 Brad Howes. All rights reserved.

import CoreAudioKit

public extension AUViewController {

  func useAudioUnit(_ audioUnit: FilterAudioUnit, editors: [AUParameterEditor]) -> NSKeyValueObservation {
    return audioUnit.observe(\.currentPreset) { _, _ in
      DispatchQueue.main.async {
        for editor in editors {
          editor.updateControl()
        }
      }
    }
  }
}
