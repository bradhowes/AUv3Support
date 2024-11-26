// Copyright © 2022-2024 Brad Howes. All rights reserved.

import CoreAudioKit
import AVKit

/**
 Protocol for a Swift/Obj-C++ kernel that can perform audio sample rendering.
 */
@objc public protocol AudioRenderer: AUParameterHandler {

  /**
   Start processing.

   - parameter busCount: the number of output busses the kernel will be processing on
   - parameter format: the audio format for the samples that will be processed
   - parameter maxFramesToRender: the maximum number of frames to render in one shot
   */
  func setRenderingFormat(_ busCount: Int, format: AVAudioFormat, maxFramesToRender: AUAudioFrameCount)

  /**
   Stopped audio processing due to resources being deallocated.
   */
  func deallocateRenderResources()

  /**
   Obtain the internal render block that is used for rendering and processing events.

   - returns: the render block to use
   */
  func internalRenderBlock() -> AUInternalRenderBlock

  /**
   Set the bypass attribute. When enabled, audio is passed through unchanged by the filter.

   - parameter state: new state of bypass
   */
  func setBypass(_ state: Bool)
}
