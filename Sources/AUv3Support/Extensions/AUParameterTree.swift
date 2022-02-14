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

public struct ParametricValue: ExpressibleByFloatLiteral {
  public typealias FloatLiteralType = AUValue

  public let value: AUValue

  @inlinable
  public init(_ value: AUValue) {
    self.value = value.clamped(to: 0...1)
  }

  @inlinable
  public init(floatLiteral value: AUValue) {
    self.init(value)
  }
}

public extension AUParameter {

  typealias ParametricTransform = (ParametricValue) -> ParametricValue

  func setParametricValue(_ t: ParametricValue, originator: AUParameterObserverToken? = nil,
                          atHostTime: UInt64 = 0, eventType: AUParameterAutomationEventType = .value) {
    let transform: (ParametricValue) -> ParametricValue
    if flags.contains(.flag_DisplaySquared) {
      transform = ParametricScales.squareRoot
    } else if flags.contains(.flag_DisplaySquareRoot) {
      transform = ParametricScales.squared
    } else if flags.contains(.flag_DisplayCubed) {
      transform = ParametricScales.cubeRoot
    } else if flags.contains(.flag_DisplayCubeRoot) {
      transform = ParametricScales.cubed
    } else if flags.contains(.flag_DisplayLogarithmic) {
      transform = ParametricScales.exp
    } else if flags.contains(.flag_DisplayExponential) {
      transform = ParametricScales.log
    } else {
      transform = ParametricScales.linear
    }
    self.setValue(transform(t).value * range.distance + range.lowerBound, originator: originator, atHostTime: atHostTime,
                  eventType: eventType)
  }

  var parametricValue: ParametricValue {
    let t: ParametricValue = .init((value - range.lowerBound) / range.distance)
    let transform: (ParametricValue) -> ParametricValue
    if flags.contains(.flag_DisplaySquared) {
      transform = ParametricScales.squared
    } else if flags.contains(.flag_DisplaySquareRoot) {
      transform = ParametricScales.squareRoot
    } else if flags.contains(.flag_DisplayCubed) {
      transform = ParametricScales.cubed
    } else if flags.contains(.flag_DisplayCubeRoot) {
      transform = ParametricScales.cubeRoot
    } else if flags.contains(.flag_DisplayLogarithmic) {
      transform = ParametricScales.log
    } else if flags.contains(.flag_DisplayExponential) {
      transform = ParametricScales.exp
    } else {
      transform = ParametricScales.linear
    }
    return transform(t)
  }
}

public enum ParametricScales {
  static var linear: (ParametricValue) -> ParametricValue = { .init($0.value) }
  static var exp: (ParametricValue) -> ParametricValue = { .init((powf(10, $0.value) - 1) / 9.0) }
  static var log: (ParametricValue) -> ParametricValue = { .init(log10f(10 * $0.value + 1) / log10f(11)) }
  static var squared: (ParametricValue) -> ParametricValue = { .init($0.value * $0.value) }
  static var squareRoot: (ParametricValue) -> ParametricValue = { .init(sqrtf($0.value)) }
  static var cubed: (ParametricValue) -> ParametricValue = { .init($0.value * $0.value * $0.value) }
  static var cubeRoot: (ParametricValue) -> ParametricValue = { .init(cbrtf($0.value)) }
  // frequencyRange.lowerBound * pow(2, Float(location / graphLayer.bounds.width) * frequencyScale)
}
