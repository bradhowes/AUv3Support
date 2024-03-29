#if os(iOS)

import XCTest
@testable import AUv3Support_iOS
import AVFoundation

class HostViewControllerTests: XCTestCase {
  
  func testShowInstructions() {
    let acd: AudioComponentDescription = .init(componentType: .init("abcd"), componentSubType: .init("efgh"),
                                               componentManufacturer: .init("ijkl"), componentFlags: 0,
                                               componentFlagsMask: 0)
    let appDelegate: AppDelegate = .init()
    let tintColor: UIColor = .red
    let appStoreVisitor: (URL) -> Void = { _ in }

    let config = HostViewConfig(name: "componentName",
                                version: "v1.2.3",
                                appDelegate: appDelegate,
                                appStoreId: "abcd",
                                componentDescription: acd,
                                sampleLoop: .sample1,
                                tintColor: tintColor,
                                appStoreVisitor: appStoreVisitor)
    let hostViewController = HostViewController()
    hostViewController.setConfig(config)

    let userDefaults = UserDefaults.standard
    userDefaults.set("", forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(hostViewController.showInstructions)
    userDefaults.set("v1.2.3", forKey: HostViewController.showedInitialAlertKey)
    XCTAssertFalse(hostViewController.showInstructions)

    HostViewController.alwaysShowInstructions = true
    userDefaults.set("", forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(hostViewController.showInstructions)
    userDefaults.set("v1.2.3", forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(hostViewController.showInstructions)
  }
}

#endif
