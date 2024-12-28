// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AudioToolbox.AUAudioUnitImplementation
import AVFoundation.AVAudioFormat
import DSPHeaders

/**
 Protocol for a Swift/Obj-C++ kernel that can perform audio sample rendering. There is an issue providing an
 AUInternalRenderBlock value from conforming instances, so there is a `TypeErasedKernel` value that is used by a
 `RenderBlockShim` to provide one for the `FilterAudioUnit`.
 */
public protocol AudioRenderer: AUParameterHandler {

  /**
   Start processing.

   - parameter busCount: the number of output busses the kernel will be processing on
   - parameter format: the audio format for the samples that will be processed
   - parameter maxFramesToRender: the maximum number of frames to render in one shot
   */
  func setRenderingFormat(_ busCount: Int, _ format: AVAudioFormat, _ maxFramesToRender: AUAudioFrameCount)

  /**
   Stopped audio processing due to resources being deallocated.
   */
  func deallocateRenderResources()

  /**
   Obtain a type-erased kernel that can be used where Swift/Obj-C++ interop breaks down, such as when the
   AUInternalRenderBlock typing gets munged.

   - returns: an instance of `TypeErasedKernel`
   */
  func bridge() -> DSPHeaders.TypeErasedKernel

  func getBypass() -> Bool

  func setBypass(_ bypass: Bool)
}
