#if os(iOS)

import XCTest
@testable import AUv3Support_iOS
import AVFoundation

class HostViewControllerTests: XCTestCase {

  @MainActor
  func makeConfig(version: String = "v1.2.3", alwaysShowNotice: Bool = false,
                  defaults: UserDefaults = .standard) -> HostViewConfig {
    let acd: AudioComponentDescription = .init(componentType: .init("abcd"), componentSubType: .init("efgh"),
                                               componentManufacturer: .init("ijkl"), componentFlags: 0,
                                               componentFlagsMask: 0)
    let appDelegate: AppDelegate = .init()
    let tintColor: UIColor = .red
    let appStoreVisitor: (URL) -> Void = { _ in }
    return .init(name: "componentName",
                 appDelegate: appDelegate,
                 appStoreId: "abcd",
                 componentDescription: acd,
                 sampleLoop: .sample1,
                 tintColor: tintColor,
                 appStoreVisitor: appStoreVisitor,
                 alwaysShowNotice: alwaysShowNotice,
                 defaults: defaults
    )
  }

  @MainActor
  func testShowInstructions() {
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    var config = makeConfig(defaults: defaults)
    let hvc = HostViewController()
    hvc.setConfig(config)

    XCTAssertTrue(hvc.showInstructions)
    XCTAssertFalse(hvc.showInstructions)

    config = makeConfig(alwaysShowNotice: true, defaults: defaults)
    hvc.setConfig(config)
    XCTAssertTrue(hvc.showInstructions)
    XCTAssertTrue(hvc.showInstructions)
  }

  @MainActor
  func testShowInstructionsOnce() {
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    let config = makeConfig(defaults: defaults)
    let hvc = HostViewController()
    hvc.setConfig(config)
    XCTAssertTrue(hvc.showInstructions)
    XCTAssertFalse(hvc.showInstructions)
  }

  @MainActor
  func testShowInstructionsWhenVersionChanges() {
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    defaults.set("v1.2.3", forKey: HostViewController.showedInitialAlertKey)
    do {
      let config = makeConfig(version: "v1.2.4", defaults: defaults)
      let hvc = HostViewController()
      hvc.setConfig(config)
      XCTAssertTrue(hvc.showInstructions)
    }
    do {
      let config = makeConfig(version: "v1.2.4", defaults: defaults)
      let hvc = HostViewController()
      hvc.setConfig(config)
      XCTAssertFalse(hvc.showInstructions)
    }
  }

  @MainActor
  func testAlwaysShowInstructions() {
    let defaults = UserDefaults(suiteName: "\(NSTemporaryDirectory())\(UUID())")!
    defaults.set("v1.2.3", forKey: HostViewController.showedInitialAlertKey)
    do {
      let config = makeConfig(alwaysShowNotice: true, defaults: defaults)
      let hvc = HostViewController()
      hvc.setConfig(config)
      XCTAssertTrue(hvc.showInstructions)
      XCTAssertTrue(hvc.showInstructions)
    }
    do {
      let config = makeConfig(alwaysShowNotice: false, defaults: defaults)
      let hvc = HostViewController()
      hvc.setConfig(config)
      XCTAssertFalse(hvc.showInstructions)
    }
  }

}

#endif
