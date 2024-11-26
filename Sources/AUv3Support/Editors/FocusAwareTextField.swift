// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(macOS)

import AppKit

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
