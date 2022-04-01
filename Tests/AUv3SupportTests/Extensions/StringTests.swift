import AudioUnit
import XCTest
@testable import AUv3Support

class StringTests: XCTestCase {

  func testPointer() throws {
    XCTAssertEqual(String.pointer(nil), "nil")
    XCTAssertTrue(self.pointer.hasPrefix("0x00"))
    XCTAssertEqual(self.pointer.count, 18)
  }
}
