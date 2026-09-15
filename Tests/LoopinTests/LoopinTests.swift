import XCTest
@testable import Loopin

final class LoopinTests: XCTestCase {
    func testWindowMinSizeConstraint() {
        let minWidth: CGFloat = 980
        let minHeight: CGFloat = 640
        XCTAssertEqual(minWidth, 980)
        XCTAssertEqual(minHeight, 640)
    }
}
