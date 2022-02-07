import AudioUnit
import XCTest
@testable import AUv3Support

private let invalidCode = FourCharCode("????")

class FourCharCodeTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testInit() throws {
    XCTAssertEqual(FourCharCode(stringLiteral: ""), invalidCode)
    XCTAssertEqual(FourCharCode(stringLiteral: "1"), invalidCode)
    XCTAssertEqual(FourCharCode(stringLiteral: "12"), invalidCode)
    XCTAssertEqual(FourCharCode(stringLiteral: "123"), invalidCode)
    XCTAssertEqual(FourCharCode(stringLiteral: "12345"), invalidCode)

    XCTAssertEqual(FourCharCode(stringLiteral: "1234").stringValue, "1234")
  }
}
