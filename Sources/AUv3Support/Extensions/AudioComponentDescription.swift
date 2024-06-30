// Copyright © 2022 Brad Howes. All rights reserved.

import AudioToolbox

extension AudioComponentDescription {
  public var description: String {
    "<AudioComponentDescription type: '\(componentType.stringValue)' " +
    "subtype: '\(componentSubType.stringValue)' " +
    "manufacturer: '\(componentManufacturer.stringValue)' " +
    "flags: \(componentFlags) mask: \(componentFlagsMask)>"
  }
}

extension AudioComponentDescription {
  public static func == (lhs: AudioComponentDescription, rhs: AudioComponentDescription) -> Bool {
    lhs.componentType == rhs.componentType &&
    lhs.componentSubType == rhs.componentSubType &&
    lhs.componentManufacturer == rhs.componentManufacturer &&
    lhs.componentFlags == rhs.componentFlags &&
    lhs.componentFlagsMask == rhs.componentFlagsMask
  }
}

#if hasFeature(RetroactiveAttribute)
extension AudioComponentDescription: @retroactive CustomStringConvertible, @retroactive Equatable {}
#else
extension AudioComponentDescription: CustomStringConvertible, Equatable {}
#endif

