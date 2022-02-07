import AudioUnit
import XCTest
@testable import AUv3Support

class ComparableTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testClamp() throws {
    XCTAssertEqual((-1).clamp(to: 0...100), 0)
    XCTAssertEqual(0.clamp(to: 0...100), 0)
    XCTAssertEqual(1.clamp(to: 0...100), 1)

    XCTAssertEqual(99.clamp(to: 0...100), 99)
    XCTAssertEqual(100.clamp(to: 0...100), 100)
    XCTAssertEqual(101.clamp(to: 0...100), 100)
  }
}
