// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit.AUViewController
import os.log

/// Namespace for the `create` global function below.
public enum FilterAudioUnitFactory {}

public extension FilterAudioUnitFactory {

  /**
   Create a new FilterAudioUnit instance to run in an AUv3 container.

   - parameter componentDescription: descriptions of the audio environment it will run in
   - parameter parameters: provider of AUParameter values that define the runtime parameters for the audio unit
   - parameter kernel: the audio sample renderer to use
   - parameter viewConfigurationManager: optional delegate for view configuration management
   - returns: new FilterAudioUnit
   */
  static func create(componentDescription: AudioComponentDescription,
                     parameters: ParameterSource,
                     kernel: AudioRenderer,
                     viewConfigurationManager: AudioUnitViewConfigurationManager? = nil) throws -> FilterAudioUnit {
#if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
#else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
#endif
    let audioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: options)
    audioUnit.configure(parameters: parameters, kernel: kernel)
    audioUnit.viewConfigurationManager = viewConfigurationManager
    return audioUnit
  }
}
