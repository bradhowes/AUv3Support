// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation

/**
 Configuration for a new AUParameter in an AUParameterTree.
 */
public struct ParameterDefinition {
  public let addressProvider: ParameterAddressProvider
  public let identifier: String
  public let localizedName: String
  public let minValue: AUValue
  public let maxValue: AUValue
  public let unit: AudioUnitParameterUnit
  public let unitName: String?
  public let ramping: Bool

  public init(addressProvider: ParameterAddressProvider, identifier: String, localizedName: String,
              minValue: AUValue, maxValue: AUValue, unit: AudioUnitParameterUnit = .generic, unitName: String? = nil,
              ramping: Bool = false) {
    self.addressProvider = addressProvider
    self.identifier = identifier
    self.localizedName = localizedName
    self.minValue = minValue
    self.maxValue = maxValue
    self.unit = unit
    self.unitName = unitName
    self.ramping = ramping
  }
}
