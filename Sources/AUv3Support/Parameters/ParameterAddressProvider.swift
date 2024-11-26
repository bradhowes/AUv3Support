// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AudioUnit.AUParameters

/**
 Protocol for entities that can provide an AUParameterAddress value
 */
public protocol ParameterAddressProvider {
  var parameterAddress: AUParameterAddress { get }
}
