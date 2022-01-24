// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import CoreAudioKit
import os

/**
 Interface for an object that maintains a value between a range of min and max values.
 */
public protocol RangedControl: NSObject {

  /// The minimum value that the control can represent
  var minimumValue: Float { get set }

  /// The maximum value that the control can represent
  var maximumValue: Float { get set }

  /// The current value of the control
  var value: Float { get set }

  /// The tag value for the control
  var tag: Int { get }
}

/**
 Control for a float value parameter that contains a knob and text view / label to depict and modify the parameter.
 */
public final class FloatParameterControl: NSObject {

  public let parameter: AUParameter
  public var control: NSObject { return knob }

  private let logSliderMinValue: Float = 0.0
  private let logSliderMaxValue: Float = 9.0
  private lazy var logSliderMaxValuePower2Minus1 = Float(pow(2, logSliderMaxValue) - 1)
  private let parameterObserverToken: AUParameterObserverToken
  private let formatter: (AUValue) -> String
  private let knob: RangedControl
  private let label: Label
  private let useLogValues: Bool
  private var restoreNameTimer: Timer?
  private var hasActiveLabel: Bool = false

  /**
   Construct a new instance that links together a Knob and a label to an AUParameter value.

   - parameter parameterObserverToken: observer token to use when setting new values to protect against looping
   - parameter parameter: the parameter to control
   - parameter formatter: the formatter to use when converting values to strings
   - parameter knob: the Knob instance to change value
   - parameter label: the Label to show the new value
   - parameter logValues: true if showing log values
   */
  public init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter,
              formatter: @escaping (AUValue) -> String, knob: RangedControl, label: Label, logValues: Bool) {
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self.formatter = formatter
    self.knob = knob
    self.label = label
    self.useLogValues = logValues
    super.init()
    
    self.label.text = parameter.displayName
    #if os(macOS)
    self.label.delegate = self
    self.label.onFocusChange = onFocusChanged
    #endif
    
    if useLogValues {
      knob.minimumValue = logSliderMinValue
      knob.maximumValue = logSliderMaxValue
      knob.value = logKnobLocation(for: parameter.value)
    }
    else {
      knob.minimumValue = parameter.minValue
      knob.maximumValue = parameter.maxValue
      knob.value = parameter.value
    }
  }
}

extension FloatParameterControl: AUParameterControl {

  /**
   Update the controls using the value from the given value provider.

   - parameter source: the source of the value
   */
  public func controlChanged(source: AUParameterValueProvider) {
#if os(macOS)
    NSApp.keyWindow?.makeFirstResponder(nil)
#endif

    if knob !== source {
      knob.value = source.value
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
    knob.value = useLogValues ? logKnobLocation(for: parameter.value) : parameter.value
  }

  /**
   Change the parameter using a value that came entering a text value.

   - parameter value: the new value to use.
   */
  public func setEditedValue(_ value: AUValue) {
    let newValue = value.clamp(to: parameter.minValue...parameter.maxValue)
    parameter.setValue(newValue, originator: parameterObserverToken)
    showNewValue(newValue)
    knob.value = useLogValues ? logKnobLocation(for: newValue) : newValue
  }
}

private extension FloatParameterControl {
  
  #if os(macOS)
  func onFocusChanged(hasFocus: Bool) {
    if hasFocus {
      hasActiveLabel = true
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
    label.text = formatter(value)
    restoreName()
  }

  func restoreName() {
    restoreNameTimer?.invalidate()
    let displayName = parameter.displayName
    let label = self.label
    restoreNameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
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
extension FloatParameterControl: NSTextFieldDelegate {
  
  public func controlTextDidEndEditing(_ obj: Notification) {
    label.onFocusChange(false)
    NSApp.keyWindow?.makeFirstResponder(nil)
  }
}
#endif

