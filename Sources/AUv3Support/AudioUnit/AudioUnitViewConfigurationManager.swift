// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit.AUViewController

/// Protocol for delegates that handle view configuration. The FilterAudioUnit has no concern for this stuff.
public protocol AudioUnitViewConfigurationManager: AnyObject {

  /**
   Request from the AU host for what view configurations are acceptable to use when showing the view for this effect.

   - parameter available: array of available configurations
   - returns: set of indices into `available` that are acceptable to use
   */
  func supportedViewConfigurations(_ available: [AUAudioUnitViewConfiguration]) -> IndexSet

  /**
   Request from the AU host for the effect to use a specific view configuration.

   - parameter viewConfiguration: the configuration to use
   */
  func selectViewConfiguration(_ viewConfiguration: AUAudioUnitViewConfiguration)
}
