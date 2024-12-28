import XCTest
@testable import AUv3Support

class SimplePlayEngineTests: XCTestCase {

  @MainActor
  func testStartStop() {
    let spe = SimplePlayEngine()
    spe.setSampleLoop(.sample1)
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
