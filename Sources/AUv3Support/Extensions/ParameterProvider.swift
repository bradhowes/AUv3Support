// Copyright © 2022 Brad Howes. All rights reserved.

import AudioUnit

/**
 Protocol for enums that can provide AUParameter information.
 */
public protocol ParameterProvider {
  var parameterAddress: AUParameterAddress { get }
  var parameterIdentifier: String { get }
  var parameterLocalizedName: String { get }
  var parameterClosedRange: ClosedRange<AUValue> { get }
  var parameterUnit: AudioUnitParameterUnit { get }
  var parameterUnitName: String? { get }
  var parameterRamping: Bool { get }
}
