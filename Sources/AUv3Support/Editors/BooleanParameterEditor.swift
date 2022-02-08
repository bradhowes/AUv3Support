// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

public protocol BooleanControl: NSObject {
  var isOn: Bool { get set }
}

/**
 An editor for a boolean parameter value that uses a switch element.
 */
public final class BooleanParameterEditor: NSObject {
  private let log = Shared.logger("BooleanParameterControl")
  private let booleanControl: BooleanControl

  public let parameter: AUParameter
  public var control: NSObject { booleanControl }
  private var parameterObserverToken: AUParameterObserverToken!

  public init(parameter: AUParameter, booleanControl: BooleanControl) {
    self.parameter = parameter
    self.booleanControl = booleanControl
    super.init()

    parameterObserverToken = parameter.token(byAddingParameterObserver: { [weak self] _, _ in
      self?.parameterChanged()
    })
    booleanControl.isOn = parameter.value >= 0.5 ? true : false
  }
}

extension BooleanParameterEditor: AUParameterEditor {

  public func controlChanged(source: AUParameterValueProvider) {
    os_log(.info, log: log, "controlChanged - new: %f state: %d", source.value, booleanControl.isOn)

    let value = source.value
    if booleanControl !== source {
      booleanControl.isOn = value >= 0.5 ? true : false
    }

    if value != parameter.value {
      parameter.setValue(source.value, originator: parameterObserverToken)
    }
  }

  public func parameterChanged() {
    os_log(.info, log: log, "parameterChanged - %f", parameter.value)
    booleanControl.isOn = parameter.value >= 0.5 ? true : false
  }

  public func setEditedValue(_ value: AUValue) {
    os_log(.info, log: log, "setEditedValue - %f", value)
    parameter.setValue(value, originator: parameterObserverToken)
    booleanControl.isOn = value >= 0.5 ? true : false
  }
}
