// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit
import os.log

public enum Shared {}

extension Shared {

  /// The top-level identifier to use for logging.
  private static var loggingSubsystem: String! = nil

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ subsystem: String, _ category: String) -> OSLog {
    precondition(loggingSubsystem == nil, "loggingSubsystem has already been set")
    loggingSubsystem = subsystem
    return .init(subsystem: loggingSubsystem, category: category)
  }

  public static func logger(_ category: String) -> OSLog {
    precondition(loggingSubsystem != nil, "nil loggingSubsystem")
    return .init(subsystem: loggingSubsystem, category: category)
  }
}
