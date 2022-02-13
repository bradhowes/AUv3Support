import AudioUnit
import XCTest
@testable import AUv3Support

class ClosedRangeTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testProperties() throws {
    XCTAssertEqual((10...20).mid, 15.0)
    XCTAssertEqual((10...20).span, 10.0)
  }
}
