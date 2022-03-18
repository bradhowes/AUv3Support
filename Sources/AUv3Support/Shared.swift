// Copyright © 2022 Brad Howes. All rights reserved.

import os.log

/// Namespace for entities that are shared across package boundaries.
public enum Shared {}

extension Shared {

  /// The top-level identifier to use for logging.
  public private(set) static var loggingSubsystem: String = "com.braysoftware.AUv3Support"

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ subsystem: String, _ category: String) -> OSLog {
    loggingSubsystem = subsystem
    return .init(subsystem: loggingSubsystem, category: category)
  }

  public static func logger(_ category: String) -> OSLog {
    return .init(subsystem: loggingSubsystem, category: category)
  }
}
