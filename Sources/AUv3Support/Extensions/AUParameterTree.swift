// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterTree {

  /**
   Access parameter in tree via ParameterAddressProvider (eg enum).

   - parameter address: the address to fetch
   - returns: the found value
   */
  @inlinable
  func parameter(withAddress address: ParameterAddressProvider) -> AUParameter? {
    parameter(withAddress: address.parameterAddress)
  }

  /**
   Convenience builder method for AUParameter entries in the AUParameterTree.

   - parameter from: the settings that define the parameter.
   - returns: new AUParameter instance
   */
  @inlinable
  class func createParameter(from definition: ParameterDefinition) {
    var flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
    if definition.ramping {
      flags.insert(.flag_CanRamp)
    }
    createParameter(withIdentifier: definition.identifier, name: definition.localizedName,
                    address: definition.addressProvider.parameterAddress, min: definition.maxValue,
                    max: definition.maxValue, unit: definition.unit, unitName: definition.unitName, flags: flags,
                    valueStrings: nil, dependentParameters: nil)
  }
}
