// Copyright © 2021 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/// Protocol for controls that can provide a boolean (true/false) state.
public protocol BooleanControl: NSObject {
  /// Current value of the object's boolean state
  var booleanState: Bool { get set }
}

/**
 An editor for a boolean parameter value that uses a switch element.
 */
public final class BooleanParameterEditor: AUParameterEditorBase {
  private let booleanControl: BooleanControl

  public var control: NSObject { booleanControl }

  public init(parameter: AUParameter, booleanControl: BooleanControl) {
    self.booleanControl = booleanControl
    super.init(parameter: parameter)
    setState(parameter.value)
  }

  internal override func handleParameterChanged(value: AUValue) {
    precondition(Thread.isMainThread, "handleParameterChanged found running on non-main thread")
    setState(value)
  }
}

extension BooleanParameterEditor: AUParameterEditor {

  public var differs: Bool { booleanControl.booleanState != (parameter.value > 0.5 ? true : false) }

  /**
   Notification that the parameter should change due to a widget control change.

   - parameter source: the control that caused the change
   */
  public func controlChanged(source: AUParameterValueProvider) {
    precondition(Thread.isMainThread, "controlChanged found running on non-main thread")

    let value = source.value
    if booleanControl !== source {
      setState(value)
    }

    if value != parameter.value {
      parameter.setValue(source.value, originator: parameterObserverToken)
    }
  }

  public func updateControl() {
    setState(parameter.value)
  }

  /**
   Apply a new value to both the control and the parameter.

   - parameter value: the new value to use
   */
  public func setValue(_ value: AUValue) {
    precondition(Thread.isMainThread, "setEditedValue found running on non-main thread")
    setState(value)
    parameter.setValue(value, originator: parameterObserverToken)
  }
}

private extension BooleanParameterEditor {

  func setState(_ value: AUValue) {
    let newState = value >= 0.5 ? true : false
    if newState != booleanControl.booleanState {
      booleanControl.booleanState = newState
    }
  }
}
