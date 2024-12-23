// Copyright © 2022-2024 Brad Howes. All rights reserved.

import Foundation
import os.log

extension Character {
  var isPrintableASCII: Bool {
    guard let ascii = asciiValue else { return false }
    return 32..<127 ~= ascii
  }
}

extension FourCharCode {

  public init(_ value: StringLiteralType) {
    self = FourCharCode.validate(value: value)
  }

  private static func validate(value: StringLiteralType) -> Self {
    guard value.count == 4,
          value.utf8.count == 4,
          value.allSatisfy(\.isPrintableASCII)
    else {
      os_log(.error, "FourCharCode: Can't initialize with '%s', only printable ASCII allowed. Setting to '????'.",
             value)
      return 0x3F3F3F3F // = '????'
    }
    return value.utf8.reduce(into: 0) { $0 = $0 << 8 + FourCharCode($1) }
  }
}

extension FourCharCode {
  
  private static let bytesSizeForStringValue = MemoryLayout<Self>.size
  
  /// Obtain a 4-character string from our value - based on https://stackoverflow.com/a/60367676/629836
  public var stringValue: String {
    withUnsafePointer(to: bigEndian) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: Self.bytesSizeForStringValue) { bytes in
        String(bytes: UnsafeBufferPointer(start: bytes, count: Self.bytesSizeForStringValue), encoding: .utf8)!
      }
    }
  }
}
