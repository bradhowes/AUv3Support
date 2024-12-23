// Copyright © 2020, 2023 Brad Howes. All rights reserved.

import XCTest
import AUv3Support

struct MockBundle: AppExtensionBundleInfo {
  var bundleID: String = "one.two.three.four.dev"
  var auExtensionUrl: URL? { URL(fileURLWithPath: "/a/b/c/d") }
  let dict: NSDictionary
  init(dict: NSDictionary) { self.dict = dict }
  public func info(for key: String) -> String { dict[key] as? String ?? "" }
}

class BundleTests: XCTestCase {

  func testAppExtensionBundleInfo() {
    let us = Bundle(for: BundleTests.self)
    var path = us.resourcePath!

    if !FileManager.default.fileExists(atPath: path) {
      path = "/" + path.split(separator: "/").dropLast(3).joined(separator: "/").appending("/AUv3Support_AUv3SupportTests.bundle/Resources")
    } else {
#if os(iOS)
      path = path.appending("/AUv3Support_AUv3SupportTests.bundle/Resources")
#elseif os(macOS)
      path = path.appending("/AUv3Support_AUv3SupportTests.bundle/Contents/Resources/Resources")
#endif
    }

    path = path.appending("/Info.plist")
    print(path)

    let dict = NSDictionary(contentsOfFile: path)!
    let bundle = MockBundle(dict: dict)

    XCTAssertEqual("one.two.three.four.dev", bundle.bundleID)
    XCTAssertNotNil(bundle.auExtensionUrl?.path)
    XCTAssertEqual("6.0", bundle.info(for: "CFBundleInfoDictionaryVersion"))

    XCTAssertEqual(" Dev", bundle.scheme)
    XCTAssertEqual("Version 1.1.0.20220215161008 Dev", bundle.versionString)
    XCTAssertEqual("20220215161008", bundle.buildVersionNumber)
    XCTAssertEqual("1.1.0", bundle.releaseVersionNumber)

    XCTAssertEqual("SimplyChorus", bundle.auBaseName)
    XCTAssertEqual("B-Ray: SimplyChorus", bundle.auComponentName)
    XCTAssertEqual("aufx", bundle.auComponentTypeString)
    XCTAssertEqual("chor", bundle.auComponentSubtypeString)
    XCTAssertEqual("BRay", bundle.auComponentManufacturerString)

    XCTAssertEqual(FourCharCode("aufx"), bundle.auComponentType)
    XCTAssertEqual(FourCharCode("chor"), bundle.auComponentSubtype)
    XCTAssertEqual(FourCharCode("BRay"), bundle.auComponentManufacturer)

    XCTAssertEqual("SimplyChorusAU.appex", bundle.auExtensionName)
    XCTAssertEqual("1554960150", bundle.appStoreId)
  }

  func testSchemes() {
    var mock = MockBundle(dict: NSDictionary())
    mock.bundleID = "one.two.three.four"
    XCTAssertEqual("", mock.scheme)

    mock.bundleID = "one.two.three.four.dev"
    XCTAssertEqual(" Dev", mock.scheme)

    mock.bundleID = "one.two.three.four.staging"
    XCTAssertEqual(" Staging", mock.scheme)
  }

  func testBundleExtension() {

    let bundle = Bundle(for: BundleTests.self)
    let _ = bundle.bundleID

    let empty = Bundle.init()
    XCTAssertEqual("", empty.bundleID)
    XCTAssertNil(empty.auExtensionUrl)
    XCTAssertEqual("", empty.info(for: "silly"))
  }
}
