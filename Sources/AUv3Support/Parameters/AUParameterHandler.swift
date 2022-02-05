import CoreAudioKit

/**
 Protocol for entities that can respond to get/set requests in the AUParameterTree. The Adapter will conform to this
 protocol, but the C++ kernel will actually handle the requests.
 */
@objc public protocol AUParameterHandler {

  /**
   Set an AUParameter to a new value
   */
  func set(_ parameter: AUParameter, value: AUValue)

  /**
   Get the current value of an AUParameter
   */
  func get(_ parameter: AUParameter) -> AUValue
}
