// Copyright © 2021-2024 Brad Howes. All rights reserved.

import CoreAudioKit
import os.log

/**
 An editor for a float value parameter that relies on a RangedControl to provide a value between a range of values.
 */
public final class FloatParameterEditor: AUParameterEditorBase {
  private let logSliderMinValue: Float = 0.0
  private let logSliderMaxValue: Float = 9.0
  private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)
  private let formatting: AUParameterFormatting
  private let rangedControl: RangedControl
  private let label: AUv3Label?
  private let useLogValues: Bool
  private var restoreNameTimer: Timer?
  private var hasActiveLabel: Bool = false

#if os(iOS)
  private var valueEditor: ValueEditor!
#endif

#if os(macOS)
  private var valueLabel: AUv3Label?
#endif

  /**
   Construct a new instance that links together a RangedControl + label with an AUParameter value, keeping the two
   in sync. It monitors for async changes in the AUParameter and sends updates to the control. When the control changes,
   it is expected to call the editor's `controlChanged()` method so that the editor can update the parameter.
   Note that the `controlChanged` method can be called by other controls, not just the one registered with this editor.
   In this way, multiple views can keep each other up-to-date.

   If the parameter has `flag_DisplayLogarithmic` value set.

   - parameter parameter: the parameter to control
   - parameter formatting: attributes and methods to format AUValue values to strings
   - parameter rangedControl: the Knob instance to change value
   - parameter label: the Label to show the new value
   */
  public init(parameter: AUParameter, formatting: AUParameterFormatting, rangedControl: RangedControl, label: AUv3Label?) {
    self.formatting = formatting
    self.rangedControl = rangedControl
    self.label = label
    self.useLogValues = parameter.flags.contains(.flag_DisplayLogarithmic)
    super.init(parameter: parameter)

    if let label = self.label {
      configureLabel(label)
    }

    configureRangedControl()
    startObservingParameter {
      self.parameterChanged($0)
    }
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
    valueEditor.beginEditing(editor: self, editingValue: formatting.editingValueFormatter(parameter.value))
  }
}

#endif

extension FloatParameterEditor: AUParameterEditor {

  public var differs: Bool {
    rangedControl.value != (useLogValues ? paramValueToControlLogValue(parameter.value) : parameter.value)
  }

  /**
   Notification that the parameter should change due to a widget control change.

   - parameter source: the control that caused the change
   */
  public func controlChanged(source: AUParameterValueProvider) {
    os_log(.debug, log: log, "controlChanged - %f", source.value)

#if os(macOS)
    NSApp?.keyWindow?.makeFirstResponder(nil)
#endif

    let value = useLogValues ? paramValueFromControlLogValue(source.value) : source.value
    setValue(value)
  }

  private func parameterChanged(_ value: AUValue) {
    setControlState(value)
  }

  /**
   Apply a new value to both the control and the parameter.

   - parameter value: the new value to use in parameter units and scaling
   - parameter eventType: description of why the new value changed.
   */
  public func setValue(_ value: AUValue, eventType: AUParameterAutomationEventType = .value) {
    os_log(.debug, log: log, "setValue - %f", value)
    let newValue = value.clamped(to: parameter.minValue...parameter.maxValue)
    if newValue != parameter.value || eventType != .value {
      parameter.setValue(newValue, originator: parameterObserverToken, atHostTime: 0, eventType: eventType)
    }
    setControlState(newValue)
  }
}

extension FloatParameterEditor {

  private func setControlState(_ value: AUValue) {
    showNewValue(value)
    setRangedControlValue(useLogValues ? paramValueToControlLogValue(value) : value)
  }

  private func setRangedControlValue(_ value: AUValue) {
    if value != rangedControl.value {
      rangedControl.value = value
    }
  }

  private func configureRangedControl() {
    rangedControl.setParameterAddress(parameter.address)
    if useLogValues {
      rangedControl.minimumValue = logSliderMinValue
      rangedControl.maximumValue = logSliderMaxValue
      setRangedControlValue(paramValueToControlLogValue(parameter.value))
    }
    else {
      rangedControl.minimumValue = parameter.minValue
      rangedControl.maximumValue = parameter.maxValue
      setRangedControlValue(parameter.value)
    }
  }

  private func configureLabel(_ label: AUv3Label) {
    label.setParameterAddress(parameter.address)
    label.text = parameter.displayName

#if os(macOS)
    label.delegate = self
    label.onFocusChange = onLabelFocusChanged

    let valueLabel = AUv3Label(string: "")
    label.superview?.addSubview(valueLabel)
    valueLabel.isEditable = false
    valueLabel.isSelectable = false
    valueLabel.isHidden = true
    valueLabel.font = label.font
    valueLabel.textColor = label.textColor
    valueLabel.alignment = .center
    valueLabel.isBordered = false
    valueLabel.drawsBackground = false
    valueLabel.refusesFirstResponder = true
    self.valueLabel = valueLabel
#endif
  }

#if os(macOS)
  private func onLabelFocusChanged(hasFocus: Bool) {
    os_log(.debug, log: log, "onFocusChanged - hasFocus: %d", hasFocus)
    guard let label = self.label else { fatalError("expected non-nil label") }
    if hasFocus {
      if !hasActiveLabel {
        hasActiveLabel = true
        label.text = formatting.editingValueFormatter(parameter.value)
        restoreNameTimer?.invalidate()
      }
    }
    else if hasActiveLabel {
      hasActiveLabel = false
      let newValue = label.floatValue
      if newValue != parameter.value {
        setValue(newValue)
        delegate?.parameterEditorEditingDone(changed: true)
      } else {
        delegate?.parameterEditorEditingDone(changed: false)
      }
    }
  }
#endif

  /**
   Convert an AUParameter value into a value to indicate on a control

   - parameter value: the value from a parameter
   - returns: the value to use in the control
   */
  private func paramValueToControlLogValue(_ value: Float) -> Float {
    log2(((value - parameter.minValue) / (parameter.maxValue - parameter.minValue)) *
         logSliderMaxValuePower2Minus1 + 1.0)
  }

  /**
   Convert the indicator value of a control into an AUParameter value

   - parameter control: the value from a control
   - returns: the value to store in AUParameter
   */
  private func paramValueFromControlLogValue(_ control: AUValue) -> AUValue {
    ((pow(2, control) - 1) / logSliderMaxValuePower2Minus1) * (parameter.maxValue - parameter.minValue) +
    parameter.minValue
  }

  private func showNewValue(_ value: AUValue) {
    os_log(.debug, log: log, "showNewValue - %f", value)
    guard let label = self.label else { return }

#if os(iOS)
    label.text = formatting.displayValueFormatter(value)
#endif

#if os(macOS)
    guard let valueLabel = self.valueLabel else { return }
    label.isHidden = true
    label.alphaValue = 0.0
    label.text = parameter.displayName

    valueLabel.alphaValue = 1.0
    valueLabel.frame = label.frame
    valueLabel.text = formatting.displayValueFormatter(value)
    valueLabel.isHidden = false
#endif

    restoreName()
  }

  private func restoreName() {
    restoreNameTimer?.invalidate()
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      DispatchQueue.main.async {
        self.transitionToDisplayName()
      }
    }
  }

  private func transitionToDisplayName() {
    let displayName = parameter.displayName
    guard let label = label else { return }

#if os(iOS)
    UIView.transition(with: label, duration: 0.5, options: [.curveLinear, .transitionCrossDissolve]) {
      label.text = displayName
    } completion: { _ in
      label.text = displayName
    }
#endif

#if os(macOS)
    guard let valueLabel = self.valueLabel else { return }
    label.alphaValue = 0.0
    label.isHidden = false
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.5
      label.animator().alphaValue = 1.0
      valueLabel.animator().alphaValue = 0.0
    }) {
      valueLabel.isHidden = true
    }
#endif
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
    if commandSelector == #selector(NSResponder.insertNewline(_:)) {
      os_log(.debug, log: log, "controlTextViewDoCommandBy - insertNewLine")
      control.window?.makeFirstResponder(nil)
      return true
    }
    return false
  }
}
#endif
