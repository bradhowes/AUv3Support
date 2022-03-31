import CoreAudioKit

/**
 Protocol for entities that can respond to get/set requests in the AUParameterTree.
 */
@objc public protocol AUParameterHandler {

  /**
   Set an AUParameter to a new value

   - parameter parameter: the AUParameter to update
   - parameter value: the value to store
   */
  func set(_ parameter: AUParameter, value: AUValue)

  /**
   Get the current value of an AUParameter

   - parameter parameter: the AUParameter to query
   - returns the current value
   */
  func get(_ parameter: AUParameter) -> AUValue
}
