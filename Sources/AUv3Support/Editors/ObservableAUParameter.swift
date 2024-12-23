/**
 An Observable version of AUParameter

 ObservableAUParameter is intended to be used directly in SwiftUI views as an ObservedObject,
 allowing us to expose a binding to the parameter's value, as well as associated parameter data,
 like the minimum, maximum, and default values for the parameter.

 The ObservableAUParameter can also manage automation event types by calling
 `onEditingChanged()` whenever a UI element will change its editing state.

 From Apple's code template
*/
@Observable
@MainActor
final class ObservableAUParameter: ObservableAUParameterNode {

  private(set) weak var parameter: AUParameter?
  private var observerToken: AUParameterObserverToken!
  private var editingState: EditingState = .inactive

  let min: AUValue
  let max: AUValue
  let displayName: String
  let defaultValue: AUValue = 0.0
  let unit: AudioUnitParameterUnit

  init(_ parameter: AUParameter) {
    self.parameter = parameter
    self.value = parameter.value
    self.min = parameter.minValue
    self.max = parameter.maxValue
    self.displayName = parameter.displayName
    self.unit = parameter.unit
    super.init()

    /// Use the parameter.token(byAddingParameterObserver:) function to monitor for parameter
    /// changes from the host. The only role of this callback is to update the UI if the value is changed by the host.
    self.observerToken = parameter.token(byAddingParameterObserver: self.parameterChanged(_:_:))
  }

  /**
   Handle changes reported out by an AUParameter. Testing reveals that it will arrive on any thread, so we need to
   dispatch to the main thread.
   */
  nonisolated func parameterChanged(_ address: AUParameterAddress, _ value: AUValue) {
    DispatchQueue.main.async {
      guard address == self.parameter?.address,
            self.editingState == .inactive
      else {
        return
      }
      self.editingState = .hostUpdate
      self.value = value
      self.editingState = .inactive
    }
  }

  var value: AUValue {
    didSet {
      /// If the editing state is .hostUpdate, don't propagate this back to the host
      guard editingState != .hostUpdate else { return }

      let automationEventType = resolveEventType()
      parameter?.setValue(
        value,
        originator: observerToken,
        atHostTime: 0,
        eventType: automationEventType
      )
      print("Param was set \(value)")
    }
  }

  /// A callback for UI elements to notify the Parameter when UI editing state changes
  ///
  /// This is the core mechanism for ensuring correct automation behavior. With native SwiftUI elements like `Slider`,
  /// this method should be passed directly into the `onEditingChanged:` argument.
  ///
  /// As long as the UI Element correctly sets the editing state, then the ObservableAUParameter's calls to
  /// AUParameter.setValue will contain the correct automation event type.
  ///
  /// `onEditingChanged` should be called with `true` before the first value is sent, so that it can be sent with a
  /// `.touch` event. It's expected that `onEditingChanged` is called with a value of `false` to mark the end
  /// of interaction *after* the last value has been sent, since this is how SwiftUI's `Slider` and `Stepper` views behave.
  func onEditingChanged(_ editing: Bool) {
    if editing {
      editingState = .began
    } else {
      editingState = .ended

      // We set the value here again to prompt its `didSet` implementation, so that we can send the appropriate `.release` event.
      value = value
    }
  }

  private func resolveEventType() -> AUParameterAutomationEventType {
    let eventType: AUParameterAutomationEventType
    switch editingState {
    case .began:
      eventType = .touch
      editingState = .active
    case .ended:
      eventType = .release
      editingState = .inactive
    default:
      eventType = .value
    }
    return eventType
  }

  private enum EditingState {
    case inactive
    case began
    case active
    case ended
    case hostUpdate
  }
}

