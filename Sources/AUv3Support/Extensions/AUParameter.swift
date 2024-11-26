// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AVFoundation

public extension AUParameter {
  var range: ClosedRange<AUValue> { minValue...maxValue }
}

public extension AUParameter {

  /// Obtain the display option for the parameter
  var displayFlag: AudioUnitParameterOptions {

    // Although the flags are part of an OptionSet, we cannot use `contains` -- we must mask out everything else and
    // return the result.
    .init(rawValue: flags.rawValue & AudioUnitParameterOptions.flag_DisplayMask.rawValue)
  }

  /**
   Set the value using a parametric value. The parametric value will be transformed based on the display flags found in
   the parameter definition.

   - parameter t: the parametric value to use
   - parameter originator: the entity causing the value change
   - parameter atHostTime: the time of the value change
   - parameter eventType: the event type associated with the value change
   */
  func setParametricValue(_ t: ParametricValue, originator: AUParameterObserverToken? = nil,
                          atHostTime: UInt64 = 0, eventType: AUParameterAutomationEventType = .value) {
    let transformed: ParametricValue
    switch displayFlag {
    case .flag_DisplaySquared: transformed = t.squareRoot
    case .flag_DisplaySquareRoot: transformed = t.squared
    case .flag_DisplayCubed: transformed = t.cubeRoot
    case .flag_DisplayCubeRoot: transformed = t.cubed
    case .flag_DisplayLogarithmic: transformed = t.exponential
    case .flag_DisplayExponential: transformed = t.logarithmic
    default: transformed = t
    }
    self.setValue(transformed.value * range.distance + range.lowerBound, originator: originator, atHostTime: atHostTime,
                  eventType: eventType)
  }

  /// Obtain the parametric value based on the display flags found in the parameter definition.
  var parametricValue: ParametricValue {
    let t: ParametricValue = .init((value - range.lowerBound) / range.distance)
    switch displayFlag {
    case .flag_DisplaySquared: return t.squared
    case .flag_DisplaySquareRoot: return t.squareRoot
    case .flag_DisplayCubed: return t.cubed
    case .flag_DisplayCubeRoot: return t.cubeRoot
    case .flag_DisplayLogarithmic: return t.logarithmic
    case .flag_DisplayExponential: return t.exponential
    default: return t
    }
  }
}
