// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension View {
  
  func pinToSuperviewEdges() {
    guard let superview = superview else { return }
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: superview.topAnchor),
      leadingAnchor.constraint(equalTo: superview.leadingAnchor),
      bottomAnchor.constraint(equalTo: superview.bottomAnchor),
      trailingAnchor.constraint(equalTo: superview.trailingAnchor)
    ])
  }
}
