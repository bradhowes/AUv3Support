// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest
import AVFAudio

class AVAudioPCMBufferTests: XCTestCase {
  override func setUp() {}
  override func tearDown() {}

  func testLeftPtr() {
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false) else {
      XCTFail("invalid format")
      return
    }

    let frameCount = 512
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
      XCTFail("unable to allocate buffer")
      return
    }

    let leftPtr = buffer.leftPtr
    XCTAssertNotNil(leftPtr.baseAddress)
  }

  func testRightPtr() {
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false) else {
      XCTFail("invalid format")
      return
    }

    let frameCount = 512
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
      XCTFail("unable to allocate buffer")
      return
    }

    let rightPtr = buffer.rightPtr
    XCTAssertNotNil(rightPtr.baseAddress)
  }

  func testClear() {
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false) else {
      XCTFail("invalid format")
      return
    }

    let frameCount: AVAudioFrameCount = 512
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
      XCTFail("unable to allocate buffer")
      return
    }

    buffer.frameLength = frameCount
    for index in 0..<frameCount {
      buffer.leftPtr[Int(index)] = 2.1 * AUValue(index)
      buffer.rightPtr[Int(index)] = 1.1 * AUValue(index)
    }

    XCTAssertEqual(511.0 * 2.1, buffer.leftPtr[511])
    XCTAssertEqual(511.0 * 1.1, buffer.rightPtr[511])

    buffer.clear()

    XCTAssertEqual(0.0, buffer.leftPtr[0])
    XCTAssertEqual(0.0, buffer.rightPtr[0])
    XCTAssertEqual(0.0, buffer.leftPtr[511])
    XCTAssertEqual(0.0, buffer.rightPtr[511])
  }

  func testAppend() {
    guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false) else {
      XCTFail("invalid format")
      return
    }

    let frameCount: AVAudioFrameCount = 512
    guard let destination = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount * 2) else {
      XCTFail("unable to allocate buffer")
      return
    }

    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
      XCTFail("unable to allocate buffer")
      return
    }

    source.frameLength = frameCount
    for index in 0..<frameCount {
      source.leftPtr[Int(index)] = 2.1 * AUValue(index)
      source.rightPtr[Int(index)] = 1.1 * AUValue(index)
    }

    destination.frameLength = 5
    for index in 0..<destination.frameLength {
      destination.leftPtr[Int(index)] = 4.1 * AUValue(index)
      destination.rightPtr[Int(index)] = 3.1 * AUValue(index)
    }

    destination.append(source)

    XCTAssertEqual(512 + 5, destination.frameLength)
    XCTAssertEqual(4 * 4.1, destination.leftPtr[4])
    XCTAssertEqual(4 * 3.1, destination.rightPtr[4])

    XCTAssertEqual(0 * 2.1, destination.leftPtr[5])
    XCTAssertEqual(0 * 1.1, destination.rightPtr[5])

    XCTAssertEqual(1 * 2.1, destination.leftPtr[6])
    XCTAssertEqual(1 * 1.1, destination.rightPtr[6])

    XCTAssertEqual(511 * 2.1, destination.leftPtr[Int(destination.frameLength) - 1])
    XCTAssertEqual(511 * 1.1, destination.rightPtr[Int(destination.frameLength) - 1])
  }
}

