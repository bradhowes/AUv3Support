// Copyright © 2022 Brad Howes. All rights reserved.

import CoreAudioKit

public extension AUViewController {

  /**
   Install an observer on `currentPreset` attribute of a FilterAudioUnit so that the editors are updated when the
   preset value changes.

   - parameter audioUnit: the FilterAudioUnit to monitor
   - parameter editors: the collection of AUParameterEditor values to update
   - returns: token for the observation
   */
  static func updateEditorsOnPresetChange(_ audioUnit: FilterAudioUnit,
                                          editors: [AUParameterEditor]) -> NSKeyValueObservation {
    return audioUnit.observe(\.currentPreset) { _, _ in
      DispatchQueue.main.async { editors.forEach { $0.updateControl() } }
    }
  }
}
