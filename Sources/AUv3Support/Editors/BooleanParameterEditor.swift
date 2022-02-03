// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

public protocol BooleanControl: NSObject {
  var isOn: Bool { get set }
}

/**
 An editor for a boolean parameter value that uses a switch element.
 */
public final class BooleanParameterEditor {
  private let log = Shared.logger("BooleanParameterControl")
  private let parameterObserverToken: AUParameterObserverToken
  private let booleanControl: BooleanControl

  public let parameter: AUParameter
  public var control: NSObject { booleanControl }

  public init(parameterObserverToken: AUParameterObserverToken, parameter: AUParameter, booleanControl: BooleanControl) {
    self.parameterObserverToken = parameterObserverToken
    self.parameter = parameter
    self.booleanControl = booleanControl
    booleanControl.isOn = parameter.value >= 0.5 ? true : false
  }
}

extension BooleanParameterEditor: AUParameterEditor {

  public func controlChanged(source: AUParameterValueProvider) {
    os_log(.debug, log: log, "controlChanged - %f", source.value)
    parameter.setValue(source.value, originator: parameterObserverToken)
  }

  public func parameterChanged() {
    os_log(.debug, log: log, "parameterChanged - %f", parameter.value)
    booleanControl.isOn = parameter.value >= 0.5 ? true : false
  }

  public func setEditedValue(_ value: AUValue) {
    os_log(.debug, log: log, "setEditedValue - %f", value)
    parameter.setValue(value, originator: parameterObserverToken)
  }
}
