import AudioToolbox
import SwiftUI

/**
 An Observable wrapper for an AUParameter

 ObservableAUParameter is intended to be used directly in SwiftUI views as an ObservedObject,
 allowing us to expose a binding to the parameter's value, as well as associated parameter data,
 like the minimum, maximum, and default values for the parameter.

 The ObservableAUParameter can also manage automation event types by calling
 `onEditingChanged()` whenever a UI element will change its editing state.

 From Apple's code template
*/

@available(iOS 17.0, *)
@Observable
@MainActor
public final class ObservableAUParameter {
  public let parameter: AUParameter
  private var observerToken: AUParameterObserverToken?
  private var editingState: EditingState = .inactive

  public var value: AUValue {
    get { parameter.value }
    set { if editingState != .hostUpdate { updateParameterValue(with: newValue) } }
  }

  public convenience init(parameter: AUParameterNodeDML) {
    if case .param(let param) = parameter {
      self.init(parameter: param)
    } else {
      fatalError("unexpected AUParameterNodeDML type")
    }
  }

  public init(parameter: AUParameter?) {
    guard let parameter else { fatalError("nil AUParameter is not supported") }
    self.parameter = parameter
    self.observerToken = parameter.token(byAddingParameterObserver: parameterChanged(_:_:))
  }

  private nonisolated func parameterChanged(_ address: AUParameterAddress, _ value: AUValue) {
    DispatchQueue.main.async {
      guard address == self.parameter.address,
            self.editingState == .inactive
      else {
        return
      }

      self.editingState = .hostUpdate
      self.value = value
      self.editingState = .inactive
    }
  }

  /**
   A callback for UI elements to notify the Parameter when UI editing state changes

   This is the core mechanism for ensuring correct automation behavior. With native SwiftUI elements like `Slider`,
   this method should be passed directly into the `onEditingChanged:` argument.

   As long as the UI Element correctly sets the editing state, then the ObservableAUParameter's calls to
   AUParameter.setValue will contain the correct automation event type.

   `onEditingChanged` should be called with `true` before the first value is sent, so that it can be sent with a
   `.touch` event. It's expected that `onEditingChanged` is called with a value of `false` to mark the end
   of interaction *after* the last value has been sent, since this is how SwiftUI's `Slider` and `Stepper` views behave.
   */
  public func onEditingChanged(_ editing: Bool) {
    if editing {
      editingState = .began
    } else {
      editingState = .ended
      updateParameterValue(with: value)
    }
  }

  private func updateParameterValue(with value: AUValue) {
    parameter.setValue(value, originator: observerToken, atHostTime: 0, eventType: resolveEventType())
  }

  private func resolveEventType() -> AUParameterAutomationEventType {
    switch editingState {
    case .began:
      editingState = .active
      return .touch
    case .ended:
      editingState = .inactive
      return .release
    default:
      return .value
    }
  }

  private enum EditingState {
    case inactive
    case began // begin touch event -- transition to active
    case active // ongoing touch event
    case ended // end touch event -- transition to inactove
    case hostUpdate // change from external party such as a host via preset change
  }
}
