// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import CoreAudioKit.AUViewController
import os.log

public enum FilterAudioUnitFactory {

  /**
   Create a new FilterAudioUnit instance to run in an AVu3 container.

   - parameter componentDescription: descriptions of the audio environment it will run in
   - parameter parameters: provider of AUParameter values that define the runtime parameters for the audio unit
   - parameter kernel: the audio sample renderer to use
   - parameter currentPresetMonitor: optional entity to notify when currentPreset attribute changes
   - parameter viewConfigurationManager: optional delegate for view configuration management
   - returns: new FilterAudioUnit
   */
  public static func create(componentDescription: AudioComponentDescription,
                            parameters: ParameterSource,
                            kernel: AudioRenderer,
                            currentPresetMonitor: CurrentPresetMonitor?,
                            viewConfigurationManager: AudioUnitViewConfigurationManager?) throws -> FilterAudioUnit {
    let audioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: [.loadOutOfProcess])
    audioUnit.configure(parameters: parameters, kernel: kernel)
    audioUnit.currentPresetMonitor = currentPresetMonitor
    audioUnit.viewConfigurationManager = viewConfigurationManager
    return audioUnit
  }
}
