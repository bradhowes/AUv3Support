import CoreAudioKit
import XCTest
@testable import AUv3Support

fileprivate class AUVCM: AudioUnitViewConfigurationManager {}

final class AudioUnitViewConfigurationManagerTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testSupportedViewConfigurations() throws {
    let auvcm = AUVCM()
    XCTAssertTrue(auvcm.supportedViewConfigurations([]).isEmpty)
    XCTAssertTrue(auvcm.supportedViewConfigurations([.init(width: 0, height: 0, hostHasController: false)]).isEmpty)
    XCTAssertTrue(auvcm.supportedViewConfigurations([.init(width: 0, height: 0, hostHasController: true)]).isEmpty)
    XCTAssertTrue(auvcm.supportedViewConfigurations([.init(width: 1, height: 0, hostHasController: false)]).isEmpty)
    XCTAssertTrue(auvcm.supportedViewConfigurations([.init(width: 0, height: 1, hostHasController: false)]).isEmpty)

    let indices = auvcm.supportedViewConfigurations([
      .init(width: 0, height: 1, hostHasController: false),
      .init(width: 1, height: 1, hostHasController: false),
      .init(width: 0, height: 0, hostHasController: false),
      .init(width: 2, height: 2, hostHasController: false),
      .init(width: 1, height: 0, hostHasController: false),
    ])

    XCTAssertEqual(indices.count, 2)
    XCTAssertTrue(indices.contains(1))
    XCTAssertTrue(indices.contains(3))
  }

  func testSelectViewConfiguration() throws {
    let auvcm = AUVCM()
    XCTAssertNoThrow(auvcm.selectViewConfiguration(.init(width: 1, height: 2, hostHasController: false)))
  }
}
