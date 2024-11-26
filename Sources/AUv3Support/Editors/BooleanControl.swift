// Copyright © 2021-2024 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/// Protocol for controls that can provide a boolean (true/false) state.
@MainActor
public protocol BooleanControl: ParameterAddressHolder {
  /// Current value of the object's boolean state
  var booleanState: Bool { get set }
}
