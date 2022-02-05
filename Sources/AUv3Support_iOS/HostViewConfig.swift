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
  public let appStoreId: String
  public let componentDescription: AudioComponentDescription
  public let sampleLoop: AudioUnitLoader.SampleLoop
  public let appStoreVisitor: (URL) -> Void

  /**
   The configuration parameters.

   - parameter name: the name of the audio unit to host
   - parameter version: the version of the audio unit being hosted
   - parameter appStoreId: the app store ID for the audio unit
   - parameter componentDescription: the description of the audio unit used to find it on the device
   - parameter sampleLoop: the sample loop to play
   - parameter appStoreVisitor: the closure to invoke to visit the app store and view the page for the audio unit
   */
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

#endif
