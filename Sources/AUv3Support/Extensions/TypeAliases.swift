// Copyright © 2022 Brad Howes. All rights reserved.

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

/**
 Custom `NSTextField` that provides a way to convey an `onFocusChange` event to another party. This is done in two
 parts:

 - When the text field becomes the first responder and starts editing, it invokes `onFocusChange(true)`.
 - When the text field ends editing, the *delegate* invokes `onFocusChange(false)` from `controlTextDidEndEditing`.
 Also, it should probably capture ENTER/RETURN key events and give up first responder state when they are seen.

 Here is an example delegate implementation that does the job:
 ```
 extension Controller: NSTextFieldDelegate {

   public func controlTextDidEndEditing(_ obj: Notification) {
     if let control = obj.object as? FocusAwareTextField {
       control.onFocusChange(false)
       control.window?.makeFirstResponder(nil)
     }
   }

   public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
     if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
       control.window?.makeFirstResponder(nil)
       return true
     }
     return false
   }
 }
```
 */
final public class FocusAwareTextField: NSTextField {
  /**
   Allow for others to identify when a NSTextField is the first responder. There are notifications from the NSWindow but
   this seems to be the easiest for AUv3 work. Perhaps it is a hack, but it works and I know of no other way to
   accomplish the same in Cocoa.
   */
  public var onFocusChange: (Bool) -> Void = { _ in }

  override public func becomeFirstResponder() -> Bool {
    if super.becomeFirstResponder() {

      // Select the contents of the field when it becomes the first responder.
      if let editor = self.currentEditor() {
        editor.perform(#selector(selectAll(_:)), with: self, afterDelay: 0)
      }

      onFocusChange(true)
      return true
    }
    return false
  }
}

#endif
