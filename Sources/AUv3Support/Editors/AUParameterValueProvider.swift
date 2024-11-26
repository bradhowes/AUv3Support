// Copyright © 2021-2024 Brad Howes. All rights reserved.

import AudioToolbox

/**
 Protocol for UI controls that can provide a parameter value.
 */
@MainActor
public protocol AUParameterValueProvider: AnyObject {

  /// The current value for a parameter.
  var value: AUValue { get }
}
