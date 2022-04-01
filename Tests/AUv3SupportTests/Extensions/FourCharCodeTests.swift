import AudioUnit
import XCTest
@testable import AUv3Support

private let invalidCode = FourCharCode("????")

class FourCharCodeTests: XCTestCase {

  func testInvalid() throws {
    XCTAssertEqual(FourCharCode(""), invalidCode)
    XCTAssertEqual(FourCharCode("1"), invalidCode)
    XCTAssertEqual(FourCharCode("12"), invalidCode)
    XCTAssertEqual(FourCharCode("123"), invalidCode)
    XCTAssertEqual(FourCharCode("12345"), invalidCode)
  }

  func testValid() {
    XCTAssertEqual(FourCharCode("1234").stringValue, "1234")
    let z = "9876"
    XCTAssertEqual(FourCharCode(z).stringValue, "9876")
  }
}
