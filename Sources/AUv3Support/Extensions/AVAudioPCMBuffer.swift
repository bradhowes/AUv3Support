// Copyright © 2022 Brad Howes. All rights reserved.

import Accelerate
import AVFoundation

// These extension pertain to common AUv3 use-cases where we have one or more buffers of non-interleaved AUValue
// samples.
extension AVAudioPCMBuffer {

  /// - returns pointer to array of AUValue values representing the left channel of a stereo buffer pair.
  var leftPtr: UnsafeMutableBufferPointer<AUValue> {
    precondition(format.isStandard)
    return UnsafeMutableBufferPointer<AUValue>(UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)[0])
  }

  /// - returns pointer to array of AUValue values representing the right channel of a stereo buffer pair.
  var rightPtr: UnsafeMutableBufferPointer<AUValue> {
    precondition(format.isStandard && format.channelCount > 1)
    return UnsafeMutableBufferPointer<AUValue>(UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)[1])
  }

  /**
   Clear the buffer so that all `frameLength` samples are 0.0.
   */
  func zeros() {
    precondition(format.isStandard)
    let channelCount = Int(format.channelCount)
    let buffers = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)
    for index in 0..<channelCount {
      let ptr = UnsafeMutableBufferPointer<AUValue>(buffers[index])
      vDSP_vclr(ptr.baseAddress!, 1, vDSP_Length(frameLength))
    }
  }

  /**
   Append given buffer contents to the end of our contents

   - parameter buffer: the buffer to append
   */
  func append(_ buffer: AVAudioPCMBuffer) { append(buffer, startingFrame: 0, frameCount: buffer.frameLength) }

  /**
   Append given buffer contents to the end of our contents. Halts program if the buffer formats are not the same,
   the range of the source is invalid, or there is not enough space to hold the appended samples.

   - parameter buffer: the buffer to append
   - parameter startingFrame: the index of the first frame to append
   - parameter frameCount: the number of frames to append
   */
  func append(_ buffer: AVAudioPCMBuffer, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
    precondition(format.isStandard)
    precondition(format == buffer.format, "Format mismatch")
    precondition(startingFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength),
                 "Insufficient audio in buffer")
    precondition(frameLength + frameCount <= frameCapacity, "Insufficient space in buffer")

    memcpy(leftPtr.baseAddress!.advanced(by: Int(frameLength)), buffer.leftPtr.baseAddress,
           Int(frameCount) * stride * MemoryLayout<Float>.size)

    memcpy(rightPtr.baseAddress!.advanced(by: Int(frameLength)), buffer.rightPtr.baseAddress,
           Int(frameCount) * stride * MemoryLayout<Float>.size)

    frameLength += frameCount
  }
}
