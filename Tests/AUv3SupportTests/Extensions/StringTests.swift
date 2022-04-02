import AudioUnit
import XCTest
@testable import AUv3Support

class TypeAliasesTests: XCTestCase {

#if os(iOS)

  func testUIViewExtensions() {
    let z = View()
    XCTAssertEqual(z.parameterAddress, 0)
    z.parameterAddress = AUParameterAddress(123)
    XCTAssertEqual(z.parameterAddress, 123)
  }

  func testUISwitchExtensions() {
    let z = UISwitch()
    XCTAssertFalse(z.booleanState)
    XCTAssertEqual(z.value, 0.0)
    z.booleanState = true
    XCTAssertTrue(z.booleanState)
    XCTAssertEqual(z.value, 1.0)
  }

#endif

#if os(macOS)

  func testNSViewExtensions() throws {
    let z = NSView()
    XCTAssertNoThrow(z.setNeedsLayout())
    XCTAssertNoThrow(z.setNeedsDisplay())
    XCTAssertNil(z.backgroundColor)
    z.backgroundColor = Color.red
    XCTAssertNotNil(z.backgroundColor)
  }

  func testControlExtensions() throws {
    let z = NSSlider()
    XCTAssertEqual(z.parameterAddress, 0)
    z.parameterAddress = AUParameterAddress(123)
    XCTAssertEqual(z.parameterAddress, 123)
  }

  func testNSTextFieldExtensions() throws {
    let z = NSTextField()
    XCTAssertEqual(z.text, "")
    z.text = "foo"
    XCTAssertEqual(z.text, "foo")
  }

  func testNSSwitchExtensions() throws {
    let z = NSSwitch()
    XCTAssertFalse(z.booleanState)
    XCTAssertEqual(z.value, 0.0)
    z.booleanState = true
    XCTAssertTrue(z.booleanState)
    XCTAssertEqual(z.value, 1.0)

    z.setTint(.red)
    XCTAssertNotNil(z.layer)
    XCTAssertEqual(z.layer!.backgroundColor, Color.red.cgColor)
    XCTAssertTrue(z.layer!.masksToBounds)
    XCTAssertEqual(z.layer!.cornerRadius, 10)
  }

#endif
}

