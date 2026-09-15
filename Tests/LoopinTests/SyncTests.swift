import XCTest
@testable import Loopin

final class SyncTests: XCTestCase {
    var db: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        db = DatabaseManager(inMemory: true)
    }
    
    override func tearDown() {
        db = nil
        super.tearDown()
    }
    
    func testSyncFieldsAndTracking() {
        let now = Date()
        let entry = TimesheetEntry(
            id: "sync-test-1",
            kind: "logged",
            startAt: now,
            endAt: now.addingTimeInterval(1800),
            rawText: "Building Supabase Sync",
            inputMethod: "typed",
            category: "Deep Work",
            productivity: "productive",
            gcalEventId: nil,
            deviceId: "macOS",
            isSynced: false
        )
        
        db.insertEntry(entry)
        
        // Check pending sync list
        let pending = db.fetchPendingSyncEntries()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.id, "sync-test-1")
        XCTAssertFalse(pending.first?.isSynced ?? true)
        
        // Mark entry synced
        db.markEntrySynced(id: "sync-test-1", gcalEventId: "gcal-12345")
        
        let pendingAfter = db.fetchPendingSyncEntries()
        XCTAssertEqual(pendingAfter.count, 0)
        
        let fetched = db.fetchEntry(id: "sync-test-1")
        XCTAssertTrue(fetched?.isSynced ?? false)
        XCTAssertEqual(fetched?.gcalEventId, "gcal-12345")
    }
    
    func testDetailedUserWastefulTaxonomyMatching() {
        SampleDataSeeder.seedDefaultRulesIfNeeded(db: db)
        let rules = db.fetchAllRules()
        
        // Test "re-watching room scrolling"
        let match1 = ClassifierEngine.classify(text: "I was re-watching room scrolling on my bed", rules: rules)
        XCTAssertNotNil(match1)
        XCTAssertEqual(match1?.category, "Social Scrolling")
        XCTAssertEqual(match1?.subcategory, "Room Scrolling")
        XCTAssertEqual(match1?.productivity, .wasteful)
        
        // Test "room scrolling"
        let match2 = ClassifierEngine.classify(text: "Just room scrolling before sleeping", rules: rules)
        XCTAssertNotNil(match2)
        XCTAssertEqual(match2?.category, "Social Scrolling")
        XCTAssertEqual(match2?.subcategory, "Room Scrolling")
        XCTAssertEqual(match2?.productivity, .wasteful)
        
        // Test "playing cod"
        let match3 = ClassifierEngine.classify(text: "I was playing cod with friends", rules: rules)
        XCTAssertNotNil(match3)
        XCTAssertEqual(match3?.category, "Gaming")
        XCTAssertEqual(match3?.subcategory, "Call of Duty")
        XCTAssertEqual(match3?.productivity, .wasteful)
        
        // Test "youtube shorts" vs "youtube"
        let match4 = ClassifierEngine.classify(text: "Watched youtube shorts for an hour", rules: rules)
        XCTAssertNotNil(match4)
        XCTAssertEqual(match4?.category, "YouTube Watching")
        XCTAssertEqual(match4?.subcategory, "Shorts")
        XCTAssertEqual(match4?.productivity, .wasteful)
        
        // Test "binge watching netflix"
        let match5 = ClassifierEngine.classify(text: "netflix binge watching anime season 2", rules: rules)
        XCTAssertNotNil(match5)
        XCTAssertEqual(match5?.category, "Binge Watching")
        XCTAssertEqual(match5?.productivity, .wasteful)
    }
}
