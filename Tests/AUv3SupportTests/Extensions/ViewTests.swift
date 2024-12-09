// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

class ViewTests: XCTestCase {

  override func setUp() {}
  override func tearDown() {}

  @MainActor
  func testPinToSuperviewEdges() throws {
    let parent = AUv3View(frame: .init(x: 0, y: 0, width: 100, height: 200))
    parent.addConstraint(.init(item: parent, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100))
    parent.addConstraint(.init(item: parent, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 200))

    let child = AUv3View(frame: .init(x: 10, y: 10, width: 20, height: 20))
    child.pinToSuperviewEdges()

    parent.addSubview(child)
    child.pinToSuperviewEdges()

#if os(macOS)
    parent.layoutSubtreeIfNeeded()
#endif

#if os(iOS)
    parent.setNeedsLayout()
    parent.layoutIfNeeded()
#endif

    XCTAssertEqual(child.frame.origin, .zero)
    XCTAssertEqual(child.frame.width, 100)
    XCTAssertEqual(child.frame.height, 200)
  }
}
