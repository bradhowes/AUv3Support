// Copyright © 2022 Brad Howes. All rights reserved.

import Accelerate
import AVFoundation

extension AVAudioPCMBuffer {

  var leftPtr: UnsafeMutableBufferPointer<AUValue> {
    let bufferList = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)
    let buffer = bufferList[0]
    let ptr = UnsafeMutableBufferPointer<AUValue>(buffer)
    return ptr
  }

  var rightPtr: UnsafeMutableBufferPointer<AUValue> {
    let bufferList = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)
    precondition(bufferList.count == 2)
    let buffer = bufferList[1]
    let ptr = UnsafeMutableBufferPointer<AUValue>(buffer)
    return ptr
  }

  func clear() {
    vDSP_vclr(leftPtr.baseAddress!, 1, vDSP_Length(frameCapacity))
    vDSP_vclr(rightPtr.baseAddress!, 1, vDSP_Length(frameCapacity))
  }

  func append(_ buffer: AVAudioPCMBuffer) { append(buffer, startingFrame: 0, frameCount: buffer.frameLength) }

  func append(_ buffer: AVAudioPCMBuffer, startingFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) {
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
