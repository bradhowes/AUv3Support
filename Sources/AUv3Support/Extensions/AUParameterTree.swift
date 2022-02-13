// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameterTree {

  /**
   Access parameter in tree via ParameterAddressProvider (eg enum).

   - parameter address: the address to fetch
   - returns: the found value
   */
  @inlinable
  func parameter(source: ParameterAddressProvider) -> AUParameter? {
    parameter(withAddress: source.parameterAddress)
  }
}

public extension AUParameter {
  var range: ClosedRange<AUValue> { minValue...maxValue }
}
