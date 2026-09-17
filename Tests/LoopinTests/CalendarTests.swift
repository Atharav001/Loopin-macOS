import XCTest
@testable import Loopin

@MainActor
final class CalendarTests: XCTestCase {
    
    func testCalendarEventMultiDayCalculation() {
        let cal = Calendar.current
        let today = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        
        let singleDayEvent = CalendarEvent(
            title: "Team Sync",
            startDate: today,
            endDate: today,
            isAllDay: true
        )
        XCTAssertFalse(singleDayEvent.isMultiDay, "Same day event should not be multi-day")
        
        let multiDayEvent = CalendarEvent(
            title: "Hackathon",
            startDate: today,
            endDate: tomorrow,
            isAllDay: true
        )
        XCTAssertTrue(multiDayEvent.isMultiDay, "Event spanning to tomorrow must be multi-day")
    }
    
    func testIndianHolidaysPresenceAndYearSpecificAccuracy() {
        // Test 2026 holidays
        let holidays2026 = HolidaysProvider.holidays(for: 2026)
        XCTAssertFalse(holidays2026.isEmpty, "Holidays list should not be empty")
        
        let titles2026 = holidays2026.map { $0.title }
        XCTAssertTrue(titles2026.contains("Janmashtami (Smarta)"), "Should include Janmashtami (Smarta)")
        XCTAssertTrue(titles2026.contains("Ganesh Chaturthi"), "Should include Ganesh Chaturthi")
        XCTAssertTrue(titles2026.contains("Diwali (Deepavali)"), "Should include Diwali")
        XCTAssertTrue(titles2026.contains("Republic Day"), "Should include Republic Day")
        XCTAssertTrue(titles2026.contains("Independence Day"), "Should include Independence Day")
        
        // Check date for Ganesh Chaturthi in 2026 is Sept 14
        let cal = Calendar.current
        if let ganesh2026 = holidays2026.first(where: { $0.title == "Ganesh Chaturthi" }) {
            XCTAssertEqual(cal.component(.month, from: ganesh2026.startDate), 9)
            XCTAssertEqual(cal.component(.day, from: ganesh2026.startDate), 14)
        }
        
        // Test 2025 year-specific holidays
        let holidays2025 = HolidaysProvider.holidays(for: 2025)
        if let ganesh2025 = holidays2025.first(where: { $0.title == "Ganesh Chaturthi" }) {
            XCTAssertEqual(cal.component(.month, from: ganesh2025.startDate), 8)
            XCTAssertEqual(cal.component(.day, from: ganesh2025.startDate), 27)
        }
    }
    
    func testCalendarManagerTogglesAndRealCalendars() {
        let manager = CalendarManager.shared
        
        // Ensure default visible calendars are the 4 real categories
        XCTAssertTrue(manager.isCalendarVisible(id: "logged"))
        XCTAssertTrue(manager.isCalendarVisible(id: "planned"))
        XCTAssertTrue(manager.isCalendarVisible(id: "google"))
        XCTAssertTrue(manager.isCalendarVisible(id: "holidays_india"))
        
        // Toggle off "logged" to plan without seeing actual logs
        manager.toggleCalendarVisibility(id: "logged")
        XCTAssertFalse(manager.isCalendarVisible(id: "logged"))
        
        // Toggle back on
        manager.toggleCalendarVisibility(id: "logged")
        XCTAssertTrue(manager.isCalendarVisible(id: "logged"))
    }
    
    func testCalendarManagerCRUD() {
        let manager = CalendarManager.shared
        let originalCount = manager.customEvents.count
        
        let event = CalendarEvent(
            title: "Project Review 2026",
            startDate: Date(),
            endDate: Date(),
            calendarId: "planned"
        )
        manager.addEvent(event)
        XCTAssertEqual(manager.customEvents.count, originalCount + 1)
        
        // Update event
        var updated = event
        updated.title = "Project Review Updated"
        manager.updateEvent(updated)
        XCTAssertTrue(manager.customEvents.contains(where: { $0.title == "Project Review Updated" }))
        
        // Clean up
        manager.deleteEvent(id: event.id)
        XCTAssertFalse(manager.customEvents.contains(where: { $0.id == event.id }))
    }
}
