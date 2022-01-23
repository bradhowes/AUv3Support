// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/**
 Control for a boolean parameter value that uses a switch element.
 */
public final class BooleanParameterControl: AUParameterControl {
  private let log = Logging.logger("BooleanParameterControl")
  
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
    os_log(.debug, log: log, "controlChanged - %f", source.value)
    parameter.setValue(source.value, originator: parameterObserverToken)
  }

  func parameterChanged() {
    os_log(.debug, log: log, "parameterChanged - %f", parameter.value)
    _control.isOn = parameter.value > 0.0 ? true : false
  }

  func setEditedValue(_ value: AUValue) {
    os_log(.debug, log: log, "setEditedValue - %f", value)
    parameter.setValue(value, originator: parameterObserverToken)
  }
}
