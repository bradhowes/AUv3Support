// Copyright © 2022 Brad Howes. All rights reserved.

import CoreAudioKit

/**
 Protocol for an entity that can provide an AUParameterTree and the parameters that are found in it. It also can provide
 a set of factory presets and the means to use them.
 */
public protocol ParameterSource {

  /// Obtain the `AUParameterTree` to use for the audio unit
  var parameterTree: AUParameterTree { get }
  /// Obtain a list of defined factory presets
  var factoryPresets: [AUAudioUnitPreset] { get }
  /// Obtain a list of AUParameter entities that pertain to the audio component and are found in the parameter tree.
  var parameters: [AUParameter] { get }

  /**
   Install a delegate that conforms to the `AUParameterHandler` protocol.

   - parameter parameterHandler: the handler to install
   */
  func setParameterHandler(_ parameterHandler: AUParameterHandler)

  /**
   Apply the parameter settings found in the given factory preset.

   - parameter preset: the preset to apply
   */
  func usePreset(_ preset: AUAudioUnitPreset)
}
