// Copyright © 2020 Brad Howes. All rights reserved.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension CALayer {
  convenience init(color: Color, frame: CGRect) {
    self.init()
    backgroundColor = color.cgColor
    self.frame = frame
  }
}
