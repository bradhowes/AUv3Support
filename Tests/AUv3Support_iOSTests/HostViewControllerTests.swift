#if os(iOS)

import XCTest
@testable import AUv3Support_iOS
import Foundation

class HostViewControllerTests: XCTestCase {
  
  func testShowInstructions() {
    let userDefaults = UserDefaults.standard
    userDefaults.set(false, forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(HostViewController.showInstructions)
    userDefaults.set(true, forKey: HostViewController.showedInitialAlertKey)
    XCTAssertFalse(HostViewController.showInstructions)
    HostViewController.alwaysShowInstructions = true
    userDefaults.set(false, forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(HostViewController.showInstructions)
    userDefaults.set(true, forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(HostViewController.showInstructions)
  }
}

#endif
