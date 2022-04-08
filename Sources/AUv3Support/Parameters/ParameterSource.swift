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
   Apply the parameter settings found in the given factory preset.

   - parameter preset: the preset to apply
   */
  func useFactoryPreset(_ preset: AUAudioUnitPreset)

  /**
   Add parameter values to the given state dictionary. This is not strictly necessary since the state dict already has
   the values in its `data` key, but that is in a binary format.

   - parameter dict: the dictionary to update
   */
  func storeParameters(into dict: inout [String: Any])

  func useUserPreset(from dict: [String: Any])
}

extension ParameterSource {

  public func storeParameters(into dict: inout [String: Any]) {
    for parameter in parameters {
      dict[parameter.identifier] = parameter.value
    }
  }

  public func useUserPreset(from dict: [String: Any]) {
    for parameter in parameters {
      if let value = dict[parameter.identifier] as? AUValue {
        parameter.value = value
      }
    }
  }
}
