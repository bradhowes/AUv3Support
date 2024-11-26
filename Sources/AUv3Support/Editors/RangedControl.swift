// Copyright © 2021-2024 Brad Howes. All rights reserved.

import CoreAudioKit
import os.log

/**
 Protocol for an object that maintains a value between a range of min and max values.
 */
@MainActor
public protocol RangedControl: ParameterAddressHolder {

  /// The minimum value that the control can represent
  var minimumValue: Float { get set }

  /// The maximum value that the control can represent
  var maximumValue: Float { get set }

  /// The current value of the control
  var value: Float { get set }
}
