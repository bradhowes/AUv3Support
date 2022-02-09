// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit.AUViewController

/// Protocol for a delegate that receives notifications when the currentPreset attribute of the FilterAudioUnit changes
/// value. This exists because of a linking issue when referencing `currentPreset` attribute by its key path.
public protocol CurrentPresetMonitor: AnyObject {

  /**
   Notification that the current preset of the FilterAudioUnit has changed.

   - parameter value: current value
   */
  func currentPresetChanged(_ value: AUAudioUnitPreset?)
}
