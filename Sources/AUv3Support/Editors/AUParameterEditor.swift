// Copyright © 2021-2024 Brad Howes. All rights reserved.

import AudioToolbox
import os.log

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
   than one UI control / value provider, so this provides a way to keep them in sync. For instance, two sliders or
   knobs could control the same parameter but in different views. Either could call this to supply a new value.

   - parameter source: the control that caused the change
   */
  func controlChanged(source: AUParameterValueProvider)

  /**
   Set the value of the editor and the value of the parameter.

   - parameter value: the value to assign to the parameter
   */
  func setValue(_ value: AUValue, eventType: AUParameterAutomationEventType)
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
  private var task: Task<Void, Never>?

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
  internal func startObservingParameter(closure: @escaping (AUValue) -> Void) {
    precondition(task == nil)
    let stream: AsyncStream<AUValue>
    (parameterObserverToken, stream) = parameter.startObserving()
    task = Task {
      for await value in stream {
        closure(value)
      }
    }
  }
}

internal extension AUParameter {

  /**
   Obtain a stream of value changes from a parameter, presumably changed by another entity such as a MIDI
   connection.

   - returns: 2-tuple containing a token for cancelling the observation and an AsyncStream of observed values
   */
  func startObserving() -> (AUParameterObserverToken, AsyncStream<AUValue>) {
    let (stream, continuation) = AsyncStream<AUValue>.makeStream()
    let observerToken = self.token(byAddingParameterObserver: { address, value in
      var lastSeen: AUValue?
      if address == self.address && value != lastSeen {
        lastSeen = value
        continuation.yield(value)
      }
    })

    return (observerToken, stream)
  }
}
