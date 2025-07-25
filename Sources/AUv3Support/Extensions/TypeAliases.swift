// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AudioUnit
import os.log

#if os(iOS) || os(visionOS)

import UIKit
import SwiftUI

public typealias AUv3Color = UIColor
public typealias AUv3Label = UILabel
public typealias AUv3Slider = UISlider
public typealias AUv3Storyboard = UIStoryboard
public typealias AUv3Switch = UISwitch
public typealias AUv3View = UIView
public typealias AUv3Control = UIControl
public typealias AUv3ViewController = UIViewController
public typealias AUv3HostingController = UIHostingController
public typealias AUv3ViewControllerRepresentable = UIViewControllerRepresentable

extension UIView: ParameterAddressHolder {
  public var parameterAddress: UInt64 {
    get { UInt64(tag) }
    set {
      precondition(newValue <= Int.max)
      tag = Int(newValue)
    }
  }
}

extension UISwitch: BooleanControl {
  public var booleanState: Bool {
    get { isOn }
    set { isOn = newValue }
  }
}

extension UISwitch: AUParameterValueProvider {
  public var value: AUValue { isOn ? 1.0 : 0.0 }
}

#elseif os(macOS)

import AppKit
import SwiftUI

public typealias AUv3Color = NSColor
public typealias AUv3Label = FocusAwareTextField
public typealias AUv3Slider = NSSlider
public typealias AUv3Storyboard = NSStoryboard
public typealias AUv3Switch = NSSwitch
public typealias AUv3View = NSView
public typealias AUv3Control = NSControl
public typealias AUv3ViewController = NSViewController
public typealias AUv3HostingController = NSHostingController
public typealias AUv3ViewControllerRepresentable = NSViewControllerRepresentable

extension NSView {

  public func bringSubviewToFront(_ view: NSView) {
    // This function is a no-opp for macOS
  }
}

extension NSView {

  /// Replicate UIKit API
  public func setNeedsDisplay() { needsDisplay = true }

  /// Replicate UIKit API
  public func setNeedsLayout() { needsLayout = true }

  /// Replicate the `backgroundColor` property found in `UIView`.
  public var backgroundColor: NSColor? {
    get {
      guard let colorRef = self.layer?.backgroundColor else { return nil }
      return NSColor(cgColor: colorRef)
    }
    set {
      self.wantsLayer = true
      self.layer?.backgroundColor = newValue?.cgColor
    }
  }
}

extension NSControl: ParameterAddressHolder {
  public var parameterAddress: AUParameterAddress {
    get { AUParameterAddress(tag) }
    set {
      precondition(newValue < Int.max)
      tag = Int(newValue)
    }
  }
}

extension NSTextField {
  /// Replicate the `text` property found in `UILabel`.
  public var text: String? {
    get { self.stringValue }
    set { self.stringValue = newValue ?? "" }
  }
}

extension NSSwitch: BooleanControl {
  public var booleanState: Bool {
    get { state == .on }
    set { state = newValue ? .on : .off }
  }

  // Attempt at tinting a la UISwitch. Not exact but not too bad either.
  public func setTint(_ color: NSColor) {
    wantsLayer = true
    layer?.backgroundColor = color.cgColor
    layer?.masksToBounds = true
    layer?.cornerRadius = 10
  }
}

extension NSSwitch: AUParameterValueProvider {
  public var value: AUValue { booleanState ? 1.0 : 0.0 }
}

#endif
