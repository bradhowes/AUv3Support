// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import AUv3Support

class BundleTests: XCTestCase {

  func testComponentAttributes() throws {
    let bundles = Bundle.allBundles
    print(bundles)
    
//    let bundle = Bundle(for: AudioUnitHost.self)
//    XCTAssertEqual("LPF", bundle.auBaseName)
//    XCTAssertEqual("B-Ray: SimplyLowPass", bundle.auComponentName)
//    XCTAssertEqual("aufx", bundle.auComponentType)
//    XCTAssertEqual("lpas", bundle.auComponentSubtype)
//    XCTAssertEqual("BRay", bundle.auComponentManufacturer)
  }
}
