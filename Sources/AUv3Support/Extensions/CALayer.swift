// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension CALayer {

  /**
   Initialize a new CALayer with a color and dimensions.

   - parameter color: the color to use
   - parameter frame: the size and origin to use
   */
  convenience init(color: AUv3Color, frame: CGRect) {
    self.init()
    self.backgroundColor = color.cgColor
    self.frame = frame
  }
}
