import XCTest
@testable import AUv3Support

class ClosedRangeTests: XCTestCase {

  func testMid() throws {
    XCTAssertEqual((10.0...20.0).mid, 15.0)
    XCTAssertEqual((10.1...17.5).mid, 13.8)
  }

  func testDistance() throws {
    XCTAssertEqual((10.0...20.0).distance, 10.0)
    XCTAssertEqual((10.1...17.5).distance, 7.4)
  }
}
