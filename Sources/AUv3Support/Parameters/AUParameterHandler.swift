import CoreAudioKit

/**
 Protocol for entities that can respond to get/set requests in the AUParameterTree, such as a DSP kernel.
 */
public protocol AUParameterHandler {

  /**
   Obtain a block that can safely change kernel parameter values.

   @returns block that takes an `AUParameter` pointer, and an `AUValue`.
   */
  var parameterValueObserverBlock: AUImplementorValueObserver { get }

  /**
   Obtain a block that can safely obtain kernel parameter values.

   @returns block that takes an `AUParameter` pointer and returns an `AUValue`.
   */
  var parameterValueProviderBlock: AUImplementorValueProvider { get }
}
