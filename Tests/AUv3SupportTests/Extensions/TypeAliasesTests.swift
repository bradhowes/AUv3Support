import AudioUnit
import XCTest
@testable import AUv3Support

//class MockViewController: NSViewController {
//  @IBOutlet weak var textField: FocusAwareTextField!
//}

class StringTests: XCTestCase {

  func testPointer() throws {
    XCTAssertEqual(String.pointer(nil), "nil")
    XCTAssertTrue(self.pointer.hasPrefix("0x00"))
    XCTAssertEqual(self.pointer.count, 18)
  }

#if os(macOS)
  @MainActor
  func testNSTextField() throws {
    let z = NSTextField()
    XCTAssertEqual(z.text, "")
    z.text = nil
    XCTAssertEqual(z.text, "")
    z.text = "blah"
    XCTAssertEqual(z.text, "blah")
  }

  @MainActor
  func testNSSwitch() throws {
    let z = NSSwitch()
    XCTAssertFalse(z.booleanState)
    z.booleanState = true
    XCTAssertTrue(z.booleanState)
    z.booleanState = false
    XCTAssertFalse(z.booleanState)
  }
#endif

//#if os(macOS)
//  func skip_testFocusAwareTextField() throws {
//    var focusChanged = false
//    let onFocusChange = {(state: Bool) in
//      focusChanged = true
//    }
//
//    let testBundle = Bundle(for: type(of: self))
//    guard let resourceBundleUrl = testBundle.url(forResource: "AUv3Support_AUv3Support",
//                                                 withExtension: "bundle") else {
//      return
//    }
//    guard let resourceBundle = Bundle(url: resourceBundleUrl) else { return }
//
//    let contentViewController = MockViewController(nibName: "MockViewController.nib", bundle: resourceBundle)
//    contentViewController.loadView()
//    let window = NSWindow(contentViewController: contentViewController)
//    contentViewController.textField.onFocusChange = onFocusChange
//    XCTAssertTrue(window.makeFirstResponder(contentViewController.textField))
//    XCTAssertTrue(focusChanged)
//  }
//#endif
}
