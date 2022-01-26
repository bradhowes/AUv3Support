// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit
import os.log

public enum Shared {}

extension Shared {

  /// The top-level identifier to use for logging
  public static var loggingSubsystem = "SimplyFlange"

  /**
   Create a new logger for a subsystem

   - parameter category: the subsystem to log under
   - returns: OSLog instance to use for subsystem logging
   */
  public static func logger(_ category: String) -> OSLog { .init(subsystem: loggingSubsystem, category: category) }
}

public struct HostViewConfig {
  public let name: String
  public let version: String
  public let appStoreId: String
  public let componentDescription: AudioComponentDescription
  public let sampleLoop: AudioUnitLoader.SampleLoop
  public let appStoreVisitor: (URL) -> Void

  public init(name: String, version: String, appStoreId: String, componentDescription: AudioComponentDescription,
              sampleLoop: AudioUnitLoader.SampleLoop, appStoreVisitor: @escaping (URL) -> Void) {
    self.name = name
    self.version = version
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.appStoreVisitor = appStoreVisitor
  }
}
