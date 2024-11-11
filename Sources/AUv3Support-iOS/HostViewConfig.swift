// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import CoreAudioKit
import AUv3Support

/**
 The configuration to use for the iOS `HostViewController`.
 */
public struct HostViewConfig {
  public let name: String
  public let appDelegate: AppDelegate
  public let appStoreId: String
  public let componentDescription: AudioComponentDescription
  public let sampleLoop: AudioUnitLoader.SampleLoop
  public let tintColor: UIColor
  public let appStoreVisitor: (URL) -> Void
  public let alwaysShowNotice: Bool
  public let defaults: UserDefaults

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
  @available(*, deprecated, message: "Version is no longer needed")
  public init(
    name: String,
    version: String,
    appDelegate: AppDelegate,
    appStoreId: String,
    componentDescription: AudioComponentDescription,
    sampleLoop: AudioUnitLoader.SampleLoop,
    tintColor: UIColor,
    appStoreVisitor: @escaping (URL) -> Void,
    alwaysShowNotice: Bool = false,
    defaults: UserDefaults = .standard
  ) {
    self.name = name
    self.appDelegate = appDelegate
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.tintColor = tintColor
    self.appStoreVisitor = appStoreVisitor
    self.alwaysShowNotice = alwaysShowNotice
    self.defaults = defaults
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
  public init(
    name: String,
    appDelegate: AppDelegate,
    appStoreId: String,
    componentDescription: AudioComponentDescription,
    sampleLoop: AudioUnitLoader.SampleLoop,
    tintColor: UIColor,
    appStoreVisitor: @escaping (URL) -> Void,
    alwaysShowNotice: Bool = false,
    defaults: UserDefaults = .standard
  ) {
    self.name = name
    self.appDelegate = appDelegate
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.tintColor = tintColor
    self.appStoreVisitor = appStoreVisitor
    self.alwaysShowNotice = alwaysShowNotice
    self.defaults = defaults
  }
}

#endif
