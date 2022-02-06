// Copyright © 2022 Brad Howes. All rights reserved.

import Foundation
import AudioUnit

/**
 Protocol for (UI) objects that can hold tag values. Useful for mapping from UI elements to specific parameters. There
 are setters for various types, but there are no custom getters defined here. The expectation is that `TagHolder` will
 be extended to support whatever custom type a `TagHolder` should return.
 */
public protocol TagHolder: NSObject {
  var tag: Int { get set }
}

public extension TagHolder {

  /**
   Store a parameter address in the tag attribute.

   - parameter address: the value to store
   */
  func setParameterAddress(_ address: AUParameterAddress) { tag = Int(address) }

  /**
   Store a parameter address in the tag attribute.

   - parameter address: the value to store
   */
  func setParameterAddress(_ address: ParameterAddressProvider) { tag = Int(address.parameterAddress) }
}
