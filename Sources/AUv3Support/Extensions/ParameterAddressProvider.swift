// Copyright © 2022 Brad Howes. All rights reserved.

import AudioUnit

/**
 Protocol for entities that can provide an AUParameter's address value. Useful for enum types that represent parameters.
 */
public protocol ParameterAddressProvider {

  /// Obtain the parameter address value
  var parameterAddress: AUParameterAddress { get }
}
