// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os.log

/**
 Interface for an object that maintains a value between a range of min and max values.
 */
public protocol RangedControl: TagHolder {

  /// The minimum value that the control can represent
  var minimumValue: Float { get set }

  /// The maximum value that the control can represent
  var maximumValue: Float { get set }

  /// The current value of the control
  var value: Float { get set }
}

extension Label: TagHolder {}

/**
 An editor for a float value parameter that relies on a RangedControl to provide a value between a range of values.
 */
public final class FloatParameterEditor: NSObject {
  private let log: OSLog

  public let parameter: AUParameter
  public var control: NSObject { return rangedControl }

  private let logSliderMinValue: Float = 0.0
  private let logSliderMaxValue: Float = 9.0
  private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)
  private let parameterObserverToken: AUParameterObserverToken
  private let formatter: (AUValue) -> String
  private let rangedControl: RangedControl
  private let label: Label
  private let useLogValues: Bool
  private var restoreNameTimer: Timer?
  private var hasActiveLabel: Bool = false

  /**
   Construct a new instance that links together a RangedControl and a label to an AUParameter value.

   - parameter parameterObserverToken: observer token to use when setting new values to protect against looping
   - parameter parameter: the parameter to control
   - parameter formatter: the formatter to use when converting values to strings
   - parameter knob: the Knob instance to change value
   - parameter label: the Label to show the new value
   - parameter logValues: true if showing log values
   */
  public init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter,
              formatter: @escaping (AUValue) -> String, rangedControl: RangedControl, label: Label) {
    self.log = Shared.logger("FloatParameterEditor")
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self.formatter = formatter
    self.rangedControl = rangedControl
    self.label = label
    self.useLogValues = parameter.flags.contains(.flag_DisplayLogarithmic)
    super.init()

    rangedControl.setParameterAddress(parameter.address)
    label.setParameterAddress(parameter.address)
    
    self.label.text = parameter.displayName
#if os(macOS)
    self.label.delegate = self
    self.label.onFocusChange = onFocusChanged
#endif

    if useLogValues {
      rangedControl.minimumValue = logSliderMinValue
      rangedControl.maximumValue = logSliderMaxValue
      rangedControl.value = logKnobLocation(for: parameter.value)
    }
    else {
      rangedControl.minimumValue = parameter.minValue
      rangedControl.maximumValue = parameter.maxValue
      rangedControl.value = parameter.value
    }
  }
}

extension FloatParameterEditor: AUParameterEditor {

  /**
   Update the controls using the value from the given value provider.

   - parameter source: the source of the value
   */
  public func controlChanged(source: AUParameterValueProvider) {
    os_log(.debug, log: log, "%{public}s %d controlChanged - %f", rangedControl.pointer, rangedControl.tag, source.value)
#if os(macOS)
    NSApp.keyWindow?.makeFirstResponder(nil)
#endif

    if rangedControl !== source {
      rangedControl.value = source.value
    }

    let value = useLogValues ? parameterValue(for: source.value) : source.value
    showNewValue(value)

    if value != parameter.value {
      parameter.setValue(value, originator: parameterObserverToken)
    }
  }

  /**
   THe parameter changed by some means other than a control. Show the new value and update the knob.
   */
  public func parameterChanged() {
    showNewValue(parameter.value)
    rangedControl.value = useLogValues ? logKnobLocation(for: parameter.value) : parameter.value
  }

  /**
   Change the parameter using a value that came entering a text value.

   - parameter value: the new value to use.
   */
  public func setEditedValue(_ value: AUValue) {
    os_log(.debug, log: log, "setEditedValue BEGIN - value: %f", value)
    let newValue = value.clamp(to: parameter.minValue...parameter.maxValue)
    os_log(.debug, log: log, "setEditedValue - using value: %f", newValue)
    parameter.setValue(newValue, originator: parameterObserverToken)
    showNewValue(newValue)
    rangedControl.value = useLogValues ? logKnobLocation(for: newValue) : newValue
  }
}

private extension FloatParameterEditor {

#if os(macOS)
  func onFocusChanged(hasFocus: Bool) {
    os_log(.debug, log: log, "onFocusChanged - hasFocus: %d", hasFocus)
    if hasFocus {
      hasActiveLabel = true
      os_log(.debug, log: log, "showing parameter value: %f", parameter.value)
      label.floatValue = parameter.value
      restoreNameTimer?.invalidate()
    }
    else if hasActiveLabel {
      hasActiveLabel = false
      setEditedValue(label.floatValue)
    }
  }
#endif

  func logKnobLocation(for value: Float) -> Float {
    log2(((value - parameter.minValue) / (parameter.maxValue - parameter.minValue)) *
         logSliderMaxValuePower2Minus1 + 1.0)
  }

  func parameterValue(for knobValue: AUValue) -> AUValue {
    ((pow(2, knobValue) - 1) / logSliderMaxValuePower2Minus1) * (parameter.maxValue - parameter.minValue) +
    parameter.minValue
  }

  func showNewValue(_ value: AUValue) {
    os_log(.debug, log: log, "showNewValue: %f", value)
    label.text = formatter(value)
    restoreName()
  }

  func restoreName() {
    restoreNameTimer?.invalidate()
    let displayName = parameter.displayName
    let label = self.label
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      os_log(.debug, log: self.log, "restoreName: %{public}s", displayName)
#if os(iOS)
      UIView.transition(with: self.label, duration: 0.5, options: [.curveLinear, .transitionCrossDissolve]) {
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
