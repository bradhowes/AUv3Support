// Copyright © 2022-2024 Brad Howes. All rights reserved.

import Foundation

public extension String {

  /**
   Convert an object pointer into a string representation.

   - parameter object: value to convert
   - returns: string representation of the pointer
   */
  static func pointer(_ object: AnyObject?) -> String {
    guard let object = object else { return "nil" }
    let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
    return String(describing: opaque)
  }
}

public extension NSObject {
  /// Obtain a pointer string value for the given object.
  var pointer: String { String.pointer(self) }
}
