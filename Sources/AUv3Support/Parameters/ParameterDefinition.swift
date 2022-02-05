import AudioUnit.AUParameters

/**
 Attributes that will be used for an AUParameter in an AUParameterTree.
 */
public struct ParameterDefinition {
  /// The unique identifier for the parameter. According to Apple, this should never change in value across releases.
  let identifier: String
  /// The localized display name for the parameter.
  let localized: String
  /// The unique address in the AUParameter tree for the parameter.
  let address: AUParameterAddress
  /// The min/max values the parameter can have (inclusive)
  let range: ClosedRange<AUValue>
  /// The unit type of the value
  let unit: AudioUnitParameterUnit
  /// The unit name of the value (useful for custom units)
  let unitName: String?
  /// When true, a parameter should change to a new value over N samples in order to minimize audio noise due to
  /// discontinuities in the signal processing algorithms from large changes in a parameter value.
  let ramping: Bool
  /// If true, show values on a log scale.
  let logScale: Bool

  public init(_ identifier: String, localized: String, address: ParameterAddressProvider, range: ClosedRange<AUValue>,
              unit: AudioUnitParameterUnit, unitName: String?, ramping: Bool, logScale: Bool) {
    self.identifier = identifier
    self.localized = localized
    self.address = address.parameterAddress
    self.range = range
    self.unit = unit
    self.unitName = unitName
    self.ramping = ramping
    self.logScale = logScale
  }

  /**
   Factory method for describing a boolean parameter.

   - parameter identifier: the unique identifier for the parameter
   - parameter localized: the localized name for the parameter
   - parameter address: the unique address for the parameter
   - returns: new ParameterDefinition instance
   */
  public static func defBool(_ identifier: String, localized: String,
                             address: ParameterAddressProvider) -> ParameterDefinition {
    .init(identifier, localized: localized, address: address, range: 0.0...1.0, unit: .boolean, unitName: nil,
          ramping: false, logScale: false)
  }

  /**
   Factory method for describing a float parameter that can exist between a known range of values.

   - parameter identifier: the unique identifier for the parameter
   - parameter localized: the localized name for the parameter
   - parameter address: the unique address for the parameter
   - parameter range: the bounds that the parameter's value will be in
   - parameter unit: the unit of the value
   - parameter unitName: the optional name of the unit
   - parameter ramping: true if the value should ramp over time when being set to a new value (default is true)
   - returns: new ParameterDefinition instance
   */
  public static func defFloat(_ identifier: String, localized: String, address: ParameterAddressProvider,
                              range: ClosedRange<AUValue>, unit: AudioUnitParameterUnit, unitName: String? = nil,
                              ramping: Bool = true, logScale: Bool = false) -> ParameterDefinition {
    .init(identifier, localized: localized, address: address, range: range, unit: unit, unitName: unitName,
          ramping: ramping, logScale: logScale)
  }

  /**
   Convenience factory method for float parameters that represent a percentage between 0 and 100.

   - parameter identifier: the unique identifier for the parameter
   - parameter localized: the localized name for the parameter
   - parameter address: the unique address for the parameter
   - returns: new ParameterDefinition instance
   */
  public static func defPercent(_ identifier: String, localized: String,
                                address: ParameterAddressProvider) -> ParameterDefinition {
    .init(identifier, localized: localized, address: address, range: 0.0...100.0, unit: .percent, unitName: nil,
          ramping: true, logScale: false)
  }

  /// Obtain an AUParameter using the attributes in the definition.
  public var parameter: AUParameter {
    var flags: AudioUnitParameterOptions = [.flag_IsReadable, .flag_IsWritable]
    if ramping { flags.insert(.flag_CanRamp) }
    if logScale { flags.insert(.flag_DisplayLogarithmic) }
    return AUParameterTree.createParameter(withIdentifier: identifier, name: localized,
                                           address: address, min: range.lowerBound,
                                           max: range.upperBound, unit: unit, unitName: unitName,
                                           flags: flags, valueStrings: nil, dependentParameters: nil)
  }
}
