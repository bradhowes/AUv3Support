// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox

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
   Notification that the parameter should change due to a control change.

   - parameter source: the control that caused the change
   */
  func controlChanged(source: AUParameterValueProvider)

  /**
   Notification that the parameter's value changed somewhere else
   */
  func parameterChanged()

  /**
   Apply a new value to both the controls and the parameter.

   - parameter value: the new value to use
   */
  func setEditedValue(_ value: AUValue)
}
