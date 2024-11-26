// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AudioUnit
import os.log

#if os(iOS)

import UIKit
public typealias Color = UIColor
public typealias Label = UILabel
public typealias Slider = UISlider
public typealias Storyboard = UIStoryboard
public typealias Switch = UISwitch
public typealias View = UIView
public typealias Control = UIControl
public typealias ViewController = UIViewController

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
public typealias Color = NSColor
public typealias Label = FocusAwareTextField
public typealias Slider = NSSlider
public typealias Storyboard = NSStoryboard
public typealias Switch = NSSwitch
public typealias View = NSView
public typealias Control = NSControl
public typealias ViewController = NSViewController

public extension NSView {

  /// Replicate UIKit API
  func setNeedsDisplay() { needsDisplay = true }

  /// Replicate UIKit API
  func setNeedsLayout() { needsLayout = true }

  /// Replicate the `backgroundColor` property found in `UIView`.
  var backgroundColor: NSColor? {
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

public extension NSTextField {
  /// Replicate the `text` property found in `UILabel`.
  var text: String? {
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
