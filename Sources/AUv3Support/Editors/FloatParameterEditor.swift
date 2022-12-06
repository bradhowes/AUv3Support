// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os.log

/**
 Interface for an object that maintains a value between a range of min and max values.
 */
public protocol RangedControl: ParameterAddressHolder {

  /// The minimum value that the control can represent
  var minimumValue: Float { get set }

  /// The maximum value that the control can represent
  var maximumValue: Float { get set }

  /// The current value of the control
  var value: Float { get set }
}

/**
 An editor for a float value parameter that relies on a RangedControl to provide a value between a range of values.
 */
public final class FloatParameterEditor: AUParameterEditorBase {
  public var control: NSObject { return rangedControl }

  private let logSliderMinValue: Float = 0.0
  private let logSliderMaxValue: Float = 9.0
  private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)

  private let formatter: (AUValue) -> String
  private let rangedControl: RangedControl
  private let label: Label?
  private let useLogValues: Bool
  private var restoreNameTimer: Timer?
  private var hasActiveLabel: Bool = false

  #if os(iOS)
  private var valueEditor: ValueEditor!
  #endif

  /**
   Construct a new instance that links together a RangedControl and a label to an AUParameter value.

   - parameter parameter: the parameter to control
   - parameter formatter: the formatter to use when converting values to strings
   - parameter rangedControl: the Knob instance to change value
   - parameter label: the Label to show the new value
   */
  public init(parameter: AUParameter, formatter: @escaping (AUValue) -> String, rangedControl: RangedControl,
              label: Label?) {
    self.formatter = formatter
    self.rangedControl = rangedControl
    self.label = label
    self.useLogValues = parameter.flags.contains(.flag_DisplayLogarithmic)
    super.init(parameter: parameter)

    rangedControl.setParameterAddress(parameter.address)
    label?.setParameterAddress(parameter.address)
    
    label?.text = parameter.displayName
#if os(macOS)
    label?.delegate = self
    label?.onFocusChange = onFocusChanged
#endif

    if useLogValues {
      rangedControl.minimumValue = logSliderMinValue
      rangedControl.maximumValue = logSliderMaxValue
      rangedControl.value = paramValueToControlLogValue(parameter.value)
    }
    else {
      rangedControl.minimumValue = parameter.minValue
      rangedControl.maximumValue = parameter.maxValue
      rangedControl.value = parameter.value
    }
  }

  internal override func handleParameterChanged(value: AUValue) {
    os_log(.debug, log: log, "handleParameterChanged: %f", value)
    precondition(Thread.isMainThread, "handleParameterChanged found running on non-main thread")
    showNewValue(value)
    rangedControl.value = useLogValues ? paramValueToControlLogValue(value) : value
  }
}

#if os(iOS)

extension FloatParameterEditor {

  public func setValueEditor(valueEditor: ValueEditor, tapToEdit: UIView) {
    self.valueEditor = valueEditor
    let gesture = UITapGestureRecognizer(target: self, action: #selector(beginEditing))
    gesture.numberOfTouchesRequired = 1
    gesture.numberOfTapsRequired = 1
    tapToEdit.addGestureRecognizer(gesture)
    tapToEdit.isUserInteractionEnabled = true
  }

  @objc private func beginEditing(_ sender: UITapGestureRecognizer) {
    valueEditor.beginEditing(editor: self)
  }
}

#endif

extension FloatParameterEditor: AUParameterEditor {

  /**
   The user changed something. Make the change to the parameter. This should always run on the main thread.

   - parameter source: the source of the value
   */
  public func controlChanged(source: AUParameterValueProvider) {
    os_log(.debug, log: log, "controlChanged - %f", source.value)
    precondition(Thread.isMainThread, "controlChanged found running on non-main thread")

#if os(macOS)
    NSApp?.keyWindow?.makeFirstResponder(nil)
#endif

    if rangedControl !== source {
      os_log(.debug, log: log, "controlChanged - updating rangedControl.value")
      rangedControl.value = source.value
    }

    let value = useLogValues ? paramValueFromControlLogValue(source.value) : source.value
    os_log(.debug, log: log, "controlChanged - showNewValue %f", value)
    showNewValue(value)

    if value != parameter.value {
      os_log(.debug, log: log, "controlChanged - parameter.setValue %f", value)
      parameter.setValue(value, originator: parameterObserverToken)
    }
  }

  public func updateControl() {
    os_log(.debug, log: log, "updateControl - %f", parameter.value)
    showNewValue(parameter.value)
    rangedControl.value = useLogValues ? paramValueToControlLogValue(parameter.value) : parameter.value
  }

  /**
   Change the parameter using a value that came entering a text value. This should always run on the main thread since
   it comes after editing the parameter value.

   - parameter value: the new value to use.
   */
  public func setValue(_ value: AUValue) {
    os_log(.debug, log: log, "setValue - %f", value)
    precondition(Thread.isMainThread, "setEditedValue found running on non-main thread")
    let newValue = value.clamped(to: parameter.minValue...parameter.maxValue)
    parameter.setValue(newValue, originator: nil)
    updateControl()
  }
}

private extension FloatParameterEditor {

#if os(macOS)
  func onFocusChanged(hasFocus: Bool) {
    os_log(.debug, log: log, "onFocusChanged - hasFocus: %d", hasFocus)
    guard let label = self.label else { fatalError("expected non-nil label") }
    if hasFocus {
      hasActiveLabel = true
      label.floatValue = parameter.value
      restoreNameTimer?.invalidate()
    }
    else if hasActiveLabel {
      hasActiveLabel = false
      setValue(label.floatValue)
    }
  }
#endif

  /**
   Convert an AUParameter value into a value to indicate on a control

   - parameter value: the value from a parameter
   - returns: the value to use in the control
   */
  func paramValueToControlLogValue(_ value: Float) -> Float {
    log2(((value - parameter.minValue) / (parameter.maxValue - parameter.minValue)) *
         logSliderMaxValuePower2Minus1 + 1.0)
  }

  /**
   Convert the indicator value of a control into an AUParameter value

   - parameter knobValue: the value from a control
   - returns: the value to store in AUParameter
   */
  func paramValueFromControlLogValue(_ knobValue: AUValue) -> AUValue {
    ((pow(2, knobValue) - 1) / logSliderMaxValuePower2Minus1) * (parameter.maxValue - parameter.minValue) +
    parameter.minValue
  }

  private func showNewValue(_ value: AUValue) {
    os_log(.debug, log: log, "showNewValue - %f", value)
    label?.text = formatter(value)
    restoreName()
  }

  private func restoreName() {
    restoreNameTimer?.invalidate()
    guard let label = label else { return }
    let displayName = parameter.displayName
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
#if os(iOS)
      UIView.transition(with: label, duration: 0.5, options: [.curveLinear, .transitionCrossDissolve]) {
        label.text = displayName
      } completion: { _ in
        label.text = displayName
      }
#else
      label.text = displayName
#endif
    }
  }
}

#if os(macOS)
extension FloatParameterEditor: NSTextFieldDelegate {

  public func controlTextDidEndEditing(_ obj: Notification) {
    os_log(.debug, log: log, "controlTextDidEndEditing")
    if let control = obj.object as? FocusAwareTextField {
      os_log(.debug, log: log, "controlTextDidEndEditing - giving up focus")
      control.onFocusChange(false)
      control.window?.makeFirstResponder(nil)
    }
  }

  /**
   Detect use of ENTER or RETURN key and give up being first responder.

   - parameter control: the editing control that is active
   - parameter textView: the text view that is active
   - parameter commandSelector: the command that is being interrogated
   - returns: true if the command was handled by this routine, false otherwise
   */
  public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
      os_log(.debug, log: log, "controlTextViewDoCommandBy - insertNewLine")
      control.window?.makeFirstResponder(nil)
      return true
    }
    return false
  }
}
#endif
