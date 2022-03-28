// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import AudioUnit

/**
 Protocol for (UI) objects that can hold AUParameterAddress values. Useful for mapping from UI elements to specific
 parameters. There are setters for various types, but there are no custom getters defined here. The expectation is that
 `ParameterAddressHolder` will be extended to support whatever custom type a `ParameterAddressHolder` should return.
 */
public protocol ParameterAddressHolder: NSObject {
  var parameterAddress: UInt64 { get set }
}

public extension ParameterAddressHolder {

  /**
   Store a parameter address in the tag attribute.

   - parameter address: the value to store
   */
  func setParameterAddress(_ address: AUParameterAddress) { parameterAddress = address }

  /**
   Store a parameter address in the tag attribute.

   - parameter address: the value to store
   */
  func setParameterAddress(_ address: ParameterAddressProvider) { parameterAddress = address.parameterAddress }
}
