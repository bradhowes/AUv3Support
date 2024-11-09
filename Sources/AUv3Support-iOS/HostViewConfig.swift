// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import CoreAudioKit
import AUv3Support

/**
 The configuration to use for the iOS `HostViewController`.
 */
public struct HostViewConfig {
  public let name: String
  public let version: String
  public let appDelegate: AppDelegate
  public let appStoreId: String
  public let componentDescription: AudioComponentDescription
  public let sampleLoop: AudioUnitLoader.SampleLoop
  public let tintColor: UIColor
  public let appStoreVisitor: (URL) -> Void

  public var versionTag: String {
    version.first == "v" ? version : "v\(version)"
  }

  /**
   The configuration parameters.

   - parameter name: the name of the audio unit to host
   - parameter version: the version of the audio unit being hosted
   - parameter appStoreId: the app store ID for the audio unit
   - parameter componentDescription: the description of the audio unit used to find it on the device
   - parameter sampleLoop: the sample loop to play
   - parameter tintColor: color to use for control tinting
   - parameter appStoreVisitor: the closure to invoke to visit the app store and view the page for the audio unit
   */
  public init(name: String, version: String, appDelegate: AppDelegate, appStoreId: String,
              componentDescription: AudioComponentDescription, sampleLoop: AudioUnitLoader.SampleLoop,
              tintColor: UIColor, appStoreVisitor: @escaping (URL) -> Void) {
    self.name = name
    self.version = version
    self.appDelegate = appDelegate
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.tintColor = tintColor
    self.appStoreVisitor = appStoreVisitor
  }
}

#endif
