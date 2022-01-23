// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os.log

public extension AudioComponentDescription {

  /**
   Write out an AudioComponentDescription to an OSLog.

   - parameter logger: the log to write to
   - parameter type: the type of message to write
   */
  @inlinable
  func log(_ logger: OSLog, type: OSLogType) {
    os_log(type, log: logger,
           "AudioComponentDescription type: %{public}s, subtype: %{public}s, manufacturer: %{public}s flags: %x (%x)",
           componentType.stringValue,
           componentSubType.stringValue,
           componentManufacturer.stringValue,
           componentFlags,
           componentFlagsMask)
  }
}
