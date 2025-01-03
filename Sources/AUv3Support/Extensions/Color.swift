// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension AUv3Color {
  /// Obtain a darker variation of the current color
  var darker: AUv3Color {
#if os(macOS)
    guard let hsb = usingColorSpace(.extendedSRGB) else { return self }
#elseif os(iOS)
    let hsb = self
#endif
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    hsb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    return AUv3Color(hue: hue, saturation: saturation, brightness: brightness * 0.8, alpha: alpha)
  }

  /// Obtain a lighter variation of the current color
  var lighter: AUv3Color {
#if os(macOS)
    guard let hsb = usingColorSpace(.extendedSRGB) else { return self }
#elseif os(iOS)
    let hsb = self
#endif
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    hsb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    return AUv3Color(hue: hue, saturation: saturation, brightness: brightness * 1.2, alpha: alpha)
  }
}
