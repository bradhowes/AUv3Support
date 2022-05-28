#if os(macOS)

import XCTest
@testable import AUv3Support_macOS
import Foundation

class HostViewManagerTests: XCTestCase {

  func testShowInstructions() {
    let userDefaults = UserDefaults.standard
    userDefaults.set(false, forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertTrue(HostViewManager.showInstructions)
    userDefaults.set(true, forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertFalse(HostViewManager.showInstructions)
    HostViewManager.alwaysShowInstructions = true
    userDefaults.set(false, forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertTrue(HostViewManager.showInstructions)
    userDefaults.set(true, forKey: HostViewManager.showedInitialAlertKey)
    XCTAssertTrue(HostViewManager.showInstructions)
  }
}

#endif
