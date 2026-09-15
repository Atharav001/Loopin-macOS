import XCTest
@testable import Loopin

final class DatabaseTests: XCTestCase {
    var db: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        // Use an in-memory database for clean, isolated tests
        db = DatabaseManager(inMemory: true)
    }
    
    override func tearDown() {
        db = nil
        super.tearDown()
    }
    
    func testInsertAndFetchEntry() {
        let now = Date()
        let start = now
        let end = now.addingTimeInterval(3600)
        
        let entry = TimesheetEntry(
            id: "test-1",
            kind: EntryKind.logged.rawValue,
            startAt: start,
            endAt: end,
            rawText: "Building Swift UI",
            inputMethod: InputMethod.typed.rawValue,
            category: "Coding",
            productivity: ProductivityType.productive.rawValue
        )
        
        db.insertEntry(entry)
        
        let fetched = db.fetchEntry(id: "test-1")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, "test-1")
        XCTAssertEqual(fetched?.rawText, "Building Swift UI")
        XCTAssertEqual(fetched?.category, "Coding")
        XCTAssertEqual(fetched?.productivity, "productive")
        XCTAssertEqual(fetched?.durationMinutes, 60)
    }
    
    func testUpdateEntry() {
        let now = Date()
        var entry = TimesheetEntry(
            id: "test-2",
            kind: EntryKind.planned.rawValue,
            startAt: now,
            endAt: now.addingTimeInterval(1800),
            rawText: "Initial Plan"
        )
        db.insertEntry(entry)
        
        entry.rawText = "Updated Plan"
        entry.category = "Planning"
        entry.productivity = "productive"
        db.updateEntry(entry)
        
        let fetched = db.fetchEntry(id: "test-2")
        XCTAssertEqual(fetched?.rawText, "Updated Plan")
        XCTAssertEqual(fetched?.category, "Planning")
    }
    
    func testDeleteEntry() {
        let entry = TimesheetEntry(
            id: "test-3",
            startAt: Date(),
            endAt: Date().addingTimeInterval(1800),
            rawText: "To delete"
        )
        db.insertEntry(entry)
        XCTAssertNotNil(db.fetchEntry(id: "test-3"))
        
        db.deleteEntry(id: "test-3")
        XCTAssertNil(db.fetchEntry(id: "test-3"))
    }
    
    func testFetchForDayFiltersCorrectly() {
        let cal = Calendar.current
        let today = Date()
        let startOfToday = cal.startOfDay(for: today)
        
        let todayEntry = TimesheetEntry(
            id: "today-1",
            startAt: cal.date(byAdding: .hour, value: 10, to: startOfToday)!,
            endAt: cal.date(byAdding: .hour, value: 11, to: startOfToday)!,
            rawText: "Today task"
        )
        
        let yesterdayEntry = TimesheetEntry(
            id: "yesterday-1",
            startAt: cal.date(byAdding: .day, value: -1, to: startOfToday)!,
            endAt: cal.date(byAdding: .hour, value: 2, to: cal.date(byAdding: .day, value: -1, to: startOfToday)!)!,
            rawText: "Yesterday task"
        )
        
        db.insertEntry(todayEntry)
        db.insertEntry(yesterdayEntry)
        
        let todayResults = db.fetchForDay(today)
        XCTAssertEqual(todayResults.count, 1)
        XCTAssertEqual(todayResults.first?.id, "today-1")
    }
    
    func testClassificationRulesCRUD() {
        let rule1 = ClassificationRule(phrase: "youtube", category: "YouTube Watching", productivity: "wasteful")
        let rule2 = ClassificationRule(phrase: "youtube shorts", category: "YouTube Watching", productivity: "wasteful")
        
        db.insertRule(rule1)
        db.insertRule(rule2)
        
        let rules = db.fetchAllRules()
        XCTAssertEqual(rules.count, 2)
        // Should sort longest phrase first: "youtube shorts" before "youtube"
        XCTAssertEqual(rules[0].phrase, "youtube shorts")
        XCTAssertEqual(rules[1].phrase, "youtube")
        
        db.deleteRule(id: rule1.id)
        let updatedRules = db.fetchAllRules()
        XCTAssertEqual(updatedRules.count, 1)
        XCTAssertEqual(updatedRules.first?.phrase, "youtube shorts")
    }
}
