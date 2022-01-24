// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import UIKit
public typealias Color = UIColor
public typealias Label = UILabel
public typealias Slider = UISlider
public typealias Switch = UISwitch
public typealias View = UIView
public typealias ViewController = UIViewController

#elseif os(macOS)

import AppKit
public typealias Color = NSColor
public typealias Label = FocusAwareTextField
public typealias Slider = NSSlider
public typealias Switch = NSSwitch
public typealias View = NSView
public typealias ViewController = NSViewController

public extension NSView {
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

public extension NSTextField {
  var text: String? {
    get { self.stringValue }
    set { self.stringValue = newValue ?? "" }
  }
}

public extension NSSwitch {
  var isOn: Bool {
    get { state == .on }
    set { state = newValue ? .on : .off }
  }
}

/**
 This seems like a hack, but it works. Allow for others to identify when a NSTextField is the first responder. There
 are notifications from the NSWindow but this seems to be the easiest for AUv3 work.
 */
final public class FocusAwareTextField: NSTextField {
  
  public var onFocusChange: (Bool) -> Void = { _ in }
  
  override public func becomeFirstResponder() -> Bool {
    onFocusChange(true)
    return super.becomeFirstResponder()
  }
}

#endif
