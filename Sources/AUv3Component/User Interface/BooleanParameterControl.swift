// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import CoreAudioKit
import os

/**
 Control for a boolean parameter value that uses a switch element.
 */
public final class BooleanParameterControl: AUParameterControl {

  private let parameterObserverToken: AUParameterObserverToken
  private let _control: Switch

  public let parameter: AUParameter
  public var control: NSObject { _control }
  
  public init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter, control: Switch) {
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self._control = control
    control.isOn = parameter.value > 0.0 ? true : false
  }
}

public extension BooleanParameterControl {

  func controlChanged(source: AUParameterValueProvider) {
    parameter.setValue(source.value, originator: parameterObserverToken)
  }

  func parameterChanged() {
    _control.isOn = parameter.value > 0.0 ? true : false
  }

  func setEditedValue(_ value: AUValue) {
    parameter.setValue(value, originator: parameterObserverToken)
  }
}
