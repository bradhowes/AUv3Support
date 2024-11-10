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
    let version = "v1.2.3"

    let config = HostViewConfig(name: "componentName",
                                version: version,
                                appDelegate: appDelegate,
                                appStoreId: "abcd",
                                componentDescription: acd,
                                sampleLoop: .sample1,
                                tintColor: tintColor,
                                appStoreVisitor: appStoreVisitor)
    let hostViewController = HostViewController()
    hostViewController.setConfig(config)

    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(hostViewController.showInstructions)
    XCTAssertFalse(hostViewController.showInstructions)

    XCTAssertEqual(userDefaults.string(forKey: HostViewController.showedInitialAlertKey), version)

    HostViewController.alwaysShowInstructions = true
    userDefaults.removeObject(forKey: HostViewController.showedInitialAlertKey)
    XCTAssertTrue(hostViewController.showInstructions)
    XCTAssertTrue(hostViewController.showInstructions)

    XCTAssertEqual(userDefaults.string(forKey: HostViewController.showedInitialAlertKey), version)
  }
}

#endif
