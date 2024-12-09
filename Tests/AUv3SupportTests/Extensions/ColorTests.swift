import XCTest
@testable import AUv3Support

private let epsilon: CGFloat = 1.0e-7

class ColorTests: XCTestCase {

  func testDarker() {
    let color = AUv3Color.gray
    let darker = color.darker
    var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0
#if os(macOS)
    color.usingColorSpace(.extendedSRGB)!.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
#elseif os(iOS)
    color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
#endif
    var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0
#if os(macOS)
    darker.usingColorSpace(.extendedSRGB)!.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
#elseif os(iOS)
    darker.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
#endif

    XCTAssertTrue(color != darker)
    XCTAssertEqual(a1, a2)
    XCTAssertEqual(r1, r2 + 0.1, accuracy: epsilon)
    XCTAssertEqual(g1, g2 + 0.1, accuracy: epsilon)
    XCTAssertEqual(b1, b2 + 0.1, accuracy: epsilon)
  }

  func testLighter() {
    let color = AUv3Color.gray
    let lighter = color.lighter
    var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0
#if os(macOS)
    color.usingColorSpace(.extendedSRGB)!.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
#elseif os(iOS)
    color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
#endif
    var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0
#if os(macOS)
    lighter.usingColorSpace(.extendedSRGB)!.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
#elseif os(iOS)
    lighter.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
#endif

    XCTAssertTrue(color != lighter)
    XCTAssertEqual(a1, a2)
    XCTAssertEqual(r1, r2 - 0.1, accuracy: epsilon)
    XCTAssertEqual(g1, g2 - 0.1, accuracy: epsilon)
    XCTAssertEqual(b1, b2 - 0.1, accuracy: epsilon)
  }
}

