import XCTest
@testable import Loopin

final class GoogleCalendarTests: XCTestCase {
    func testEventPayloadSerializationForPlannedEntry() {
        let now = Date()
        let end = now.addingTimeInterval(3600)
        let entry = TimesheetEntry(
            id: "gcal-test-1",
            kind: "planned",
            startAt: now,
            endAt: end,
            rawText: "Sprint planning and task breakdown",
            inputMethod: "typed",
            category: "Deep Work",
            productivity: "productive"
        )
        
        let payload = GoogleCalendarService.makeCalendarEventPayload(for: entry)
        XCTAssertEqual(payload["summary"] as? String, "[PLANNED] Sprint planning and task breakdown")
        
        let desc = payload["description"] as? String ?? ""
        XCTAssertTrue(desc.contains("Category: Deep Work"))
        XCTAssertTrue(desc.contains("Productivity: Productive"))
        
        XCTAssertNotNil(payload["start"])
        XCTAssertNotNil(payload["end"])
    }
    
    func testEventPayloadSerializationForLoggedEntry() {
        let now = Date()
        let end = now.addingTimeInterval(1800)
        let entry = TimesheetEntry(
            id: "gcal-test-2",
            kind: "logged",
            startAt: now,
            endAt: end,
            rawText: "Watched YouTube shorts",
            inputMethod: "typed",
            category: "YouTube Watching",
            productivity: "wasteful"
        )
        
        let payload = GoogleCalendarService.makeCalendarEventPayload(for: entry)
        XCTAssertEqual(payload["summary"] as? String, "Watched YouTube shorts")
        
        let desc = payload["description"] as? String ?? ""
        XCTAssertTrue(desc.contains("Category: YouTube Watching"))
        XCTAssertTrue(desc.contains("Productivity: Wasteful"))
    }
}
