import AudioUnit
import XCTest
@testable import AUv3Support

class OptionalTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testDescriptionOrNil() throws {
    XCTAssertEqual(Optional<Int>.none.descriptionOrNil, "nil")
    XCTAssertEqual(Optional.some(123).descriptionOrNil, "123")

    XCTAssertEqual(Optional<String>.none.descriptionOrNil, "nil")
    XCTAssertEqual(Optional.some("blah").descriptionOrNil, "blah")
    XCTAssertEqual(Optional.some("").descriptionOrNil, "")
  }
}
