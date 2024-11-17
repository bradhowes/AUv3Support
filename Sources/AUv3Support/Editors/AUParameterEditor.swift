// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox
import os.log

/**
 Protocol for UI controls that can provide a parameter value.
 */
@MainActor
public protocol AUParameterValueProvider: AnyObject {

  /// The current value for a parameter.
  var value: AUValue { get }
}

/**
 Delegate protocol for an AUParameterEditor
 */
@MainActor
public protocol AUParameterEditorDelegate: AnyObject {

  /**
   Notification when the editor finishes editing of a value.

   - parameter changed: true if the value changed
   */
  func parameterEditorEditingDone(changed: Bool)
}

/**
 Protocol for controls that represent parameter values and can edit them.
 */
@MainActor
public protocol AUParameterEditor: AnyObject {

  /// Delegate for an editor which receives notification when editing is finished.
  var delegate: AUParameterEditorDelegate? { get set }

  /// The AUParameter being edited by the control
  var parameter: AUParameter { get }

  /// True if the AUParameter value and the control value differ.
  var differs: Bool { get }

  /**
   Notification that the parameter should change due to a widget control change. A parameter can be controlled by more
   than one UI control or value provider, so this provides a way to keep them in sync.

   - parameter source: the control that caused the change
   */
  func controlChanged(source: AUParameterValueProvider)

  /**
   Set the value of the editor and the value of the parameter.

   - parameter value: the value to assign to the parameter
   */
  func setValue(_ value: AUValue)
}

/**
 Base class for parameter editors. Installs a parameter observer so that the editor will be updated when the parameter
 value changes.

 - SeeAlso: `NSObject`
 */
@MainActor
public class AUParameterEditorBase: NSObject {

  /// Delegate for editing notifications
  public weak var delegate: AUParameterEditorDelegate?

  public let log: OSLog
  public let parameter: AUParameter

  // The observer token used to track the parameter value
  internal private(set) var parameterObserverToken: AUParameterObserverToken?

  /**
   Track changes for the given parameter.

   - parameter parameter: the AUParameter to track
   */
  public init(parameter: AUParameter) {
    self.log = Shared.logger("AUParameterEditor(" + parameter.displayName + ")")
    self.parameter = parameter
    super.init()
  }

  /**
   Start observing the parameter given in the initializer.

   - parameter editor: the editor whose `setValue` is invoked. Note that the expectation is that this is `self`, though
   it is not enforced. If it is *not* `self` then one must ensure it is properly retained during the lifetime of the
   observation.
   */
  internal func beginObservingParameter(editor: AUParameterEditor) {
    let _ = parameter.token(byAddingParameterObserver: { address, value in })
//    parameterObserverToken = parameter.token(byAddingParameterObserver: { [weak self, weak editor] address, value in
//      guard let self = self, let editor = editor else { return }
//      // precondition(address == self.parameter.address)
//      DispatchQueue.main.async {
//        editor.setValue(value)
//      }
//    })
  }

  public func runningOnMainThread() {
    precondition(Thread.isMainThread, "** Must be running on the main thread")
  }
}
