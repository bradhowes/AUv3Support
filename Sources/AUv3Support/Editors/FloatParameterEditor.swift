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
    os_log(.info, log: log, "controlChanged BEGIN - address: %d value: %f", parameter.address, source.value)
    precondition(Thread.isMainThread, "controlChanged found running on non-main thread")

#if os(macOS)
    NSApp?.keyWindow?.makeFirstResponder(nil)
#endif

    if rangedControl !== source {
      os_log(.info, log: log, "controlChanged - updating our control value")
      rangedControl.value = source.value
    }

    let value = useLogValues ? paramValueFromControlLogValue(source.value) : source.value
    showNewValue(value)

    if value != parameter.value {
      os_log(.info, log: log, "controlChanged - setting AUParameter value")
      parameter.setValue(value, originator: parameterObserverToken)
    }
    os_log(.info, log: log, "controlChanged END")
  }

  public func updateControl() {
    showNewValue(parameter.value)
    rangedControl.value = useLogValues ? paramValueToControlLogValue(parameter.value) : parameter.value
  }

  /**
   Change the parameter using a value that came entering a text value. This should always run on the main thread since
   it comes after editing the parameter value.

   - parameter value: the new value to use.
   */
  public func setValue(_ value: AUValue) {
    os_log(.debug, log: log, "setValue BEGIN - value: %f", value)
    precondition(Thread.isMainThread, "setEditedValue found running on non-main thread")

    let newValue = value.clamped(to: parameter.minValue...parameter.maxValue)
    os_log(.debug, log: log, "setEditedValue - using value: %f", newValue)
    parameter.setValue(newValue, originator: parameterObserverToken)
    updateControl()
    os_log(.debug, log: log, "setEditedValue END")
  }
}

private extension FloatParameterEditor {

#if os(macOS)
  func onFocusChanged(hasFocus: Bool) {
    guard let label = self.label else { fatalError("expected non-nil label") }
    os_log(.debug, log: log, "onFocusChanged - hasFocus: %d", hasFocus)
    if hasFocus {
      hasActiveLabel = true
      os_log(.debug, log: log, "showing parameter value: %f", parameter.value)
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
    os_log(.info, log: log, "showNewValue BEGIN - %f", value)
    label?.text = formatter(value)
    restoreName()
    os_log(.info, log: log, "showNewValue END")
  }

  private func restoreName() {
    os_log(.info, log: log, "restoreName BEGIN")
    restoreNameTimer?.invalidate()
    guard let label = label else { return }
    let displayName = parameter.displayName
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      os_log(.debug, log: self.log, "restoreName: %{public}s", displayName)
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
    os_log(.debug, log: log, "controlTextDidEndEditing BEGIN")
    if let control = obj.object as? FocusAwareTextField {
      os_log(.debug, log: log, "controlTextDidEndEditing - stop being first responder")
      control.onFocusChange(false)
      control.window?.makeFirstResponder(nil)
    }
    os_log(.debug, log: log, "controlTextDidEndEditing END")
  }

  /**
   Detect use of ENTER or RETURN key and give up being first responder.

   - parameter control: the editing control that is active
   - parameter textView: the text view that is active
   - parameter commandSelector: the command that is being interrogated
   - returns: true if the command was handled by this routine, false otherwise
   */
  public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    os_log(.debug, log: log, "control:textView:doCommandBy BEGIN")
    if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
      os_log(.debug, log: log, "control:textView:doCommandBy END - captured ENTER/RETURN")
      control.window?.makeFirstResponder(nil)
      return true
    }
    os_log(.debug, log: log, "control:textView:doCommandBy END")
    return false
  }
}
#endif
