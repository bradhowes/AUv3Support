import AVKit

import XCTest
@testable import AUv3Support

@MainActor
fileprivate class LoaderDelegate: AudioUnitLoaderDelegate {

  let expectation: XCTestExpectation
  var good: Bool = false

  init(expectation: XCTestExpectation) {
    self.expectation = expectation
  }

  func connected(audioUnit: AVAudioUnit, viewController: AUv3ViewController) {
    good = true
    expectation.fulfill()
  }

  func failed(error: AudioUnitLoaderError) {
    good = false
    expectation.fulfill()
  }
}

fileprivate let acd = AudioComponentDescription(componentType: FourCharCode("aufx"),
                                                componentSubType: FourCharCode("dely"),
                                                componentManufacturer: FourCharCode("appl"),
                                                componentFlags: 0,
                                                componentFlagsMask: 0)

final class AudioUnitLoaderTests: XCTestCase {

  @MainActor
  func testFailure() throws {
    let acd = AudioComponentDescription(componentType: FourCharCode("aufx"), componentSubType: FourCharCode("zzzz"),
                                        componentManufacturer: FourCharCode("appl"), componentFlags: 0,
                                        componentFlagsMask: 0)
    let audioUnitLoader = AudioUnitLoader(componentDescription: acd, maxLocateAttempts: 2)
    let exp = expectation(description: "failed")
    let delegate = LoaderDelegate(expectation: exp)
    audioUnitLoader.delegate = delegate

    waitForExpectations(timeout: 60.0, handler: nil)
    XCTAssertFalse(delegate.good)

    XCTAssertNoThrow(audioUnitLoader.save())
  }

  @MainActor
  func testConnected() throws {
    let audioUnitLoader = AudioUnitLoader(componentDescription: acd)
    let exp = expectation(description: "good")
    let delegate = LoaderDelegate(expectation: exp)
    audioUnitLoader.delegate = delegate

    waitForExpectations(timeout: 90.0, handler: nil)
    XCTAssertTrue(delegate.good)

    XCTAssertNoThrow(audioUnitLoader.save())
  }

  @MainActor
  func testPlaybackState() throws {
    let audioUnitLoader = AudioUnitLoader(componentDescription: acd)
    let engine = SimplePlayEngine()
    engine.setSampleLoop(.sample1)
    let exp = expectation(description: "failed")
    let delegate = LoaderDelegate(expectation: exp)
    audioUnitLoader.delegate = delegate

    waitForExpectations(timeout: 90.0, handler: nil)
    XCTAssertTrue(delegate.good)

    XCTAssertFalse(engine.isPlaying)
    _ = engine.startStop()
    XCTAssertTrue(engine.isPlaying)
    _ = engine.startStop()
    XCTAssertFalse(engine.isPlaying)
  }
}
