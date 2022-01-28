// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation

/**
 Protocol for entities that can provide an AUParameter's address value. Useful for enum types that represent parameters.
 */
public protocol ParameterAddressProvider {

  /// Obtain the parameter address value
  var parameterAddress: AUParameterAddress { get }
}

public extension AUParameterTree {

  /**
   Access parameter via FilterParameterAddress enum.

   - parameter address: the address to fetch
   - returns: the found value
   */
  @inlinable
  func parameter(withAddress address: ParameterAddressProvider) -> AUParameter? {
    parameter(withAddress: address.parameterAddress)
  }

  /**
   Convenience builder method for AUParameter entries in the AUParameterTree.

   - parameter identifier: the unique and stable identifier for the parameter. It must not change.
   - parameter name: the localized name of the parameter for displaying
   - parameter address: the unique address of the parameter in the tree
   - parameter min: the minimum value for the parameter
   - parameter max: the maximum value for the parameter
   - parameter unit: the units the parameter value is in
   - parameter unitName: the name of the units
   - parameter flags: flags that define the parameter value and capabilities
   - parameter valueStrings: optional strings to use when converting from value to string
   - parameter dependentParameters: optional array of AUParameter address values that may change when this parameter does
   - returns: new AUParameter instance
   */
  @inlinable
  class func createParameter(withIdentifier identifier: String, name: String, address: ParameterAddressProvider,
                             min: AUValue, max: AUValue, unit: AudioUnitParameterUnit, unitName: String? = nil,
                             flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable],
                             valueStrings: [String]? = nil, dependentParameters: [NSNumber]? = nil) -> AUParameter {
    createParameter(withIdentifier: identifier, name: name, address: address.parameterAddress, min: min, max: max,
                    unit: unit, unitName: unitName, flags: flags, valueStrings: valueStrings,
                    dependentParameters: dependentParameters)
  }
}
