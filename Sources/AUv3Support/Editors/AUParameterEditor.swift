// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os.log

/**
 Protocol for UI controls that can provide a parameter value.
 */
public protocol AUParameterValueProvider: AnyObject {

  /// The current value for a parameter.
  var value: AUValue { get }
}

/**
 Protocol for controls that represent parameter values and can edit them.
 */
public protocol AUParameterEditor: AnyObject {

  /// The AUParameter being edited by the control
  var parameter: AUParameter { get }

  /**
   Notification that the parameter should change due to a widget control change.

   - parameter source: the control that caused the change
   */
  func controlChanged(source: AUParameterValueProvider)

  func setValue(_ value: AUValue)

  func updateControl()
}

public class AUParameterEditorBase: NSObject {
  public let log: OSLog
  public let parameter: AUParameter

  public private(set) var parameterObserverToken: AUParameterObserverToken!

  public init(parameter: AUParameter) {
    self.log = Shared.logger("AUParameterEditor(" + parameter.displayName + ")")
    self.parameter = parameter
    super.init()

    parameterObserverToken = parameter.token(byAddingParameterObserver: { address, value in
      self.parameterChanged(address: address, value: value)
    })
  }

  private func parameterChanged(address: AUParameterAddress, value: AUValue) {
    os_log(.info, log: log, "parameterChanged BEGIN - address: %d value: %f", address, value)
    guard address == self.parameter.address else { return }
    DispatchQueue.main.async { self.handleParameterChanged(value: value) }
    os_log(.info, log: log, "parameterChanged END")
  }

  @objc internal func handleParameterChanged(value: AUValue) {}
}
