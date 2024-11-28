// Copyright © 2022-2024 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit.AUViewController
import os.log

public enum FilterAudioUnitFactory {

  /**
   Create a new FilterAudioUnit instance to run in an AUv3 container.
   Note that one must call `configure` in order to supply the parameters and the kernel to use.

   - parameter componentDescription: descriptions of the audio environment it will run in
   - parameter viewConfigurationManager: optional delegate for view configuration management
   - returns: new FilterAudioUnit
   */
  static public func create(
    componentDescription: AudioComponentDescription,
    viewConfigurationManager: AudioUnitViewConfigurationManager? = nil
  ) throws -> FilterAudioUnit {
#if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
#else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
#endif
    let audioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: options)
    audioUnit.viewConfigurationManager = viewConfigurationManager
    return audioUnit
  }

  /**
   Create a new FilterAudioUnit instance to run in an AUv3 container.

   - parameter componentDescription: descriptions of the audio environment it will run in
   - parameter parameters: provider of AUParameter values that define the runtime parameters for the audio unit
   - parameter kernel: the audio sample renderer to use
   - parameter viewConfigurationManager: optional delegate for view configuration management
   - returns: new FilterAudioUnit
   */
  static public func create(
    componentDescription: AudioComponentDescription,
    parameters: ParameterSource,
    kernel: AudioRenderer,
    viewConfigurationManager: AudioUnitViewConfigurationManager? = nil
  ) throws -> FilterAudioUnit {
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
