// Copyright © 2022 Brad Howes. All rights reserved.

import AudioToolbox
import os.log

extension AudioComponentDescription: CustomStringConvertible {

  public var description: String {
    "<AudioComponentDescription type: '\(componentType.stringValue)', subtype: '\(componentSubType.stringValue)', manufacturer: '\(componentManufacturer.stringValue)' flags: \(componentFlags) mask: \(componentFlagsMask)>"
  }
}
