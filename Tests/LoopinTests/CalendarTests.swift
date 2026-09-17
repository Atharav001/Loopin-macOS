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
    
    func testIndianHolidaysPresence() {
        let holidays2026 = HolidaysProvider.holidays(for: 2026)
        XCTAssertFalse(holidays2026.isEmpty, "Holidays list should not be empty")
        
        let titles = holidays2026.map { $0.title }
        XCTAssertTrue(titles.contains("Janmashtami (Smarta)"), "Should include Janmashtami (Smarta)")
        XCTAssertTrue(titles.contains("Ganesh Chaturthi"), "Should include Ganesh Chaturthi")
        XCTAssertTrue(titles.contains("Diwali (Deepavali)"), "Should include Diwali")
        XCTAssertTrue(titles.contains("Republic Day"), "Should include Republic Day")
        XCTAssertTrue(titles.contains("Independence Day"), "Should include Independence Day")
    }
    
    func testCalendarManagerCRUDAndFiltering() {
        let manager = CalendarManager.shared
        let originalCount = manager.customEvents.count
        
        let event = CalendarEvent(
            title: "Project Review 2026",
            startDate: Date(),
            endDate: Date(),
            calendarId: "primary"
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
