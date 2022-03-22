// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest
import AVFAudio

class AVAudioPCMBufferTests: XCTestCase {
  private let frameCount: AVAudioFrameCount = 512
  private var format: AVAudioFormat!
  private var buffer: AVAudioPCMBuffer!

  override func setUp() {
    format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: false)
    guard format != nil else {
      XCTFail("invalid format")
      return
    }

    buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
    guard buffer != nil else {
      XCTFail("unable to allocate buffer")
      return
    }
  }

  override func tearDown() {}

  func testLeftPtr() {
    XCTAssertNotNil(buffer.leftPtr.baseAddress)
  }

  func testRightPtr() {
    XCTAssertNotNil(buffer.rightPtr.baseAddress)
  }

  func testZeros() {
    buffer.frameLength = frameCount
    for index in 0..<frameCount {
      buffer.leftPtr[Int(index)] = 2.1 * AUValue(index)
      buffer.rightPtr[Int(index)] = 1.1 * AUValue(index)
    }

    XCTAssertEqual(511.0 * 2.1, buffer.leftPtr[511])
    XCTAssertEqual(511.0 * 1.1, buffer.rightPtr[511])

    buffer.zeros()

    XCTAssertEqual(0.0, buffer.leftPtr[0])
    XCTAssertEqual(0.0, buffer.rightPtr[0])
    XCTAssertEqual(0.0, buffer.leftPtr[511])
    XCTAssertEqual(0.0, buffer.rightPtr[511])
  }

  func testAppend() {
    let source = buffer!
    guard let destination = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount * 2) else {
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

