// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterTree {

  /**
   Access parameter in tree via ParameterAddressProvider (eg enum).

   - parameter address: the address to fetch
   - returns: the found value
   */
  @inlinable
  func parameter(source: ParameterProvider) -> AUParameter? {
    parameter(withAddress: source.parameterAddress)
  }

  /**
   Convenience builder method for AUParameter entries in the AUParameterTree.

   - parameter from: the settings that define the parameter.
   - returns: new AUParameter instance
   */
  @inlinable
  class func createParameter(from source: ParameterProvider) {
    var flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
    if source.parameterRamping {
      flags.insert(.flag_CanRamp)
    }
    let closedRange = source.parameterClosedRange
    createParameter(withIdentifier: source.parameterIdentifier, name: source.parameterLocalizedName,
                    address: source.parameterAddress, min: closedRange.lowerBound, max: closedRange.upperBound,
                    unit: source.parameterUnit, unitName: source.parameterUnitName, flags: flags,
                    valueStrings: nil, dependentParameters: nil)
  }
}
