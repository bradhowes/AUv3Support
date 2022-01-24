// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension CATransaction {

  /**
   Execute a block within a CATransaction that has animation disabled.

   @param block the closure to run inside of a CATransaction.
   */
  class func noAnimation(_ block: () -> Void) {
    defer { CATransaction.commit() }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    block()
  }
}
