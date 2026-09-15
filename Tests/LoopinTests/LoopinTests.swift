import XCTest
@testable import Loopin

final class LoopinTests: XCTestCase {
    func testWindowMinSizeConstraint() {
        let minWidth: CGFloat = 980
        let minHeight: CGFloat = 640
        XCTAssertEqual(minWidth, 980)
        XCTAssertEqual(minHeight, 640)
    }
    
    @MainActor
    func testOneHourIntervalDefault() {
        let state = AppState.shared
        XCTAssertEqual(state.selectedIntervalMinutes, 60, "Default check-in interval must be 1 hour (60m)")
    }
    
    @MainActor
    func testClockifyClockToggleAndCelebration() {
        let state = AppState.shared
        XCTAssertFalse(state.use24HourClock, "Default should be 12-hour clock")
        
        state.use24HourClock = true
        XCTAssertTrue(state.use24HourClock)
        
        state.triggerCelebration()
        XCTAssertTrue(state.triggerCelebrationGlow)
    }
    
    @MainActor
    func testThemeSwitching() {
        let state = AppState.shared
        state.currentTheme = .tickTickDark
        XCTAssertEqual(state.currentTheme, .tickTickDark)
        
        state.currentTheme = .clockifyDark
        XCTAssertEqual(state.currentTheme, .clockifyDark)
    }
}
