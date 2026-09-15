import XCTest
@testable import Loopin

final class AnalyticsTests: XCTestCase {
    var db: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        db = DatabaseManager(inMemory: true)
    }
    
    override func tearDown() {
        db = nil
        super.tearDown()
    }
    
    func testAnalyticsAggregationSums() {
        let now = Date()
        
        // 2 hours productive coding
        let e1 = TimesheetEntry(
            id: "a-1",
            kind: "logged",
            startAt: now,
            endAt: now.addingTimeInterval(7200),
            rawText: "Swift coding",
            category: "Coding",
            productivity: "productive"
        )
        
        // 1 hour neutral meeting
        let e2 = TimesheetEntry(
            id: "a-2",
            kind: "logged",
            startAt: now.addingTimeInterval(7200),
            endAt: now.addingTimeInterval(10800),
            rawText: "Team sync",
            category: "Meeting",
            productivity: "neutral"
        )
        
        // 30 min wasteful social media
        let e3 = TimesheetEntry(
            id: "a-3",
            kind: "logged",
            startAt: now.addingTimeInterval(10800),
            endAt: now.addingTimeInterval(12600),
            rawText: "Twitter browsing",
            category: "Social Media",
            productivity: "wasteful"
        )
        
        db.insertEntry(e1)
        db.insertEntry(e2)
        db.insertEntry(e3)
        
        let all = db.fetchAllEntries()
        XCTAssertEqual(all.count, 3)
        
        let totalMinutes = all.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(totalMinutes, 210) // 120 + 60 + 30 = 210
        
        let productiveMins = all.filter { $0.productivity == "productive" }.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(productiveMins, 120)
        
        let neutralMins = all.filter { $0.productivity == "neutral" }.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(neutralMins, 60)
        
        let wastefulMins = all.filter { $0.productivity == "wasteful" }.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(wastefulMins, 30)
        
        let focusScore = Int(round(Double(productiveMins) / Double(totalMinutes) * 100))
        XCTAssertEqual(focusScore, 57) // 120/210 = 57.14% -> 57%
    }
}
