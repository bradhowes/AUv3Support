import XCTest
@testable import AUv3Support

class SimplePlayEngineTests: XCTestCase {

  @MainActor
  func testStartStop() {
    let spe = SimplePlayEngine(name: "testing", audioFileName: "sample1.wav")
    XCTAssertFalse(spe.isPlaying)
    spe.start()
    XCTAssertTrue(spe.isPlaying)
    spe.start()
    XCTAssertTrue(spe.isPlaying)
    spe.stop()
    XCTAssertFalse(spe.isPlaying)
    spe.stop()
    XCTAssertFalse(spe.isPlaying)
    XCTAssertTrue(spe.startStop())
    XCTAssertTrue(spe.isPlaying)
    XCTAssertFalse(spe.startStop())
    XCTAssertFalse(spe.isPlaying)
  }
}
