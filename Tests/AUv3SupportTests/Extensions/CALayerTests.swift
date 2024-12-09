#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

import XCTest
@testable import AUv3Support

class CALayerTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testProperties() throws {
    let z = CALayer(color: .red, frame: .zero)
    XCTAssertEqual(z.backgroundColor, AUv3Color.red.cgColor)
    XCTAssertEqual(z.frame, .zero)
  }
}
