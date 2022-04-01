#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

import XCTest
@testable import AUv3Support

class CATransactionTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testNoAnimation() throws {
    let exp = expectation(description: "no animation block ran")
    CATransaction.noAnimation {
      exp.fulfill()
    }
    wait(for: [exp], timeout: 10.0)
  }
}
