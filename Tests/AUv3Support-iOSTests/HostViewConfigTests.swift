#if os(iOS)

import XCTest
@testable import AUv3Support_iOS
import Foundation
import AVFoundation

class HostViewConfigTests: XCTestCase {

  @MainActor
  func testInit() {
    let acd: AudioComponentDescription = .init(componentType: .init("abcd"), componentSubType: .init("efgh"),
                                               componentManufacturer: .init("ijkl"), componentFlags: 0,
                                               componentFlagsMask: 0)
    let appDelegate: AppDelegate = .init()
    let tintColor: UIColor = .red
    let appStoreVisitor: (URL) -> Void = { _ in }

    let config = HostViewConfig(name: "componentName",
                                appDelegate: appDelegate,
                                appStoreId: "abcd",
                                componentDescription: acd,
                                sampleLoop: .sample1,
                                tintColor: tintColor,
                                appStoreVisitor: appStoreVisitor)
    XCTAssertEqual("componentName", config.name)
    XCTAssertEqual("abcd", config.appStoreId)
    XCTAssertEqual(acd, config.componentDescription)
    XCTAssertEqual(.sample1, config.sampleLoop)
    XCTAssertEqual(tintColor, config.tintColor)
  }
}

#endif
