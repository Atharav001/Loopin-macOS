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
        state.currentTheme = .tocklogDark
        XCTAssertEqual(state.currentTheme, .tocklogDark)
        XCTAssertTrue(state.currentTheme.isDark)
        
        state.currentTheme = .tickTickDark
        XCTAssertEqual(state.currentTheme, .tickTickDark)
        
        state.currentTheme = .clockifyDark
        XCTAssertEqual(state.currentTheme, .clockifyDark)
    }
    
    @MainActor
    func testGoogleAccountState() {
        let state = AppState.shared
        state.isSignedInWithGoogle = true
        state.googleUserName = "Atharav Narang"
        state.googleUserEmail = "atharav.narang@gmail.com"
        state.googleCalendarSyncEnabled = true
        
        XCTAssertTrue(state.isSignedInWithGoogle)
        XCTAssertEqual(state.googleUserName, "Atharav Narang")
        XCTAssertEqual(state.googleUserEmail, "atharav.narang@gmail.com")
        XCTAssertTrue(state.googleCalendarSyncEnabled)
    }
    
    @MainActor
    func testHourlyClockAlignment() {
        let state = AppState.shared
        state.alignToClockHour = true
        state.selectedIntervalMinutes = 60
        
        let now = Date()
        let cal = Calendar.current
        let startHour = cal.date(byAdding: .hour, value: -1, to: now) ?? now
        
        state.triggerHourlyPrompt(start: startHour, end: now)
        XCTAssertNotNil(state.promptIntervalStart)
        XCTAssertNotNil(state.promptIntervalEnd)
        XCTAssertFalse(state.formattedCurrentPromptInterval.isEmpty)
    }
    
    @MainActor
    func testOverlappingEntriesSideBySideLayout() {
        let now = Date()
        let cal = Calendar.current
        let start = cal.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        let end = cal.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
        
        let entry1 = TimesheetEntry(
            id: "e1",
            kind: EntryKind.logged.rawValue,
            startAt: start,
            endAt: end,
            rawText: "Task 1",
            category: "Work",
            productivity: "productive"
        )
        
        let entry2 = TimesheetEntry(
            id: "e2",
            kind: EntryKind.logged.rawValue,
            startAt: start,
            endAt: end,
            rawText: "Task 2",
            category: "Meetings",
            productivity: "productive"
        )
        
        let dayColumn = DayColumnView(date: now, entries: [entry1, entry2])
        let positioned = dayColumn.computePositionedEntries()
        
        XCTAssertEqual(positioned.count, 2)
        XCTAssertEqual(positioned[0].totalCols, 2, "Overlapping entries must share 2 columns")
        XCTAssertEqual(positioned[1].totalCols, 2, "Overlapping entries must share 2 columns")
        XCTAssertNotEqual(positioned[0].colIndex, positioned[1].colIndex, "Overlapping entries must have different column indices")
    }
}

