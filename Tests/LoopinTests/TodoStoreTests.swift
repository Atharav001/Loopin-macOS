import XCTest
@testable import Loopin

@MainActor
final class TodoStoreTests: XCTestCase {
    var store: TodoStore!
    
    override func setUp() async throws {
        store = TodoStore()
        store.items = []
        store.filter = .all
        store.paneTheme = .stickyAmber
    }
    
    func testAddSingleAndMultipleTasks() {
        XCTAssertTrue(store.addTask(title: "Task 1", isStarred: false))
        XCTAssertTrue(store.addTask(title: "Task 2", isStarred: true))
        XCTAssertFalse(store.addTask(title: "   ")) // Empty title rejected
        
        XCTAssertEqual(store.totalCount, 2)
        XCTAssertEqual(store.pendingCount, 2)
        XCTAssertEqual(store.completedCount, 0)
    }
    
    func testToggleCompletion() {
        store.addTask(title: "Finish Report")
        guard let task = store.items.first else {
            XCTFail("Task should exist")
            return
        }
        
        XCTAssertFalse(task.isCompleted)
        store.toggleCompleted(id: task.id)
        
        XCTAssertTrue(store.items.first?.isCompleted == true)
        XCTAssertNotNil(store.items.first?.completedAt)
        XCTAssertEqual(store.completedCount, 1)
        XCTAssertEqual(store.progress, 1.0)
    }
    
    func testToggleStar() {
        store.addTask(title: "Important Priority", isStarred: false)
        guard let task = store.items.first else {
            XCTFail("Task should exist")
            return
        }
        
        XCTAssertFalse(task.isStarred)
        store.toggleStarred(id: task.id)
        XCTAssertTrue(store.items.first?.isStarred == true)
    }
    
    func testFiltering() {
        store.addTask(title: "Active Unstarred", isStarred: false)
        store.addTask(title: "Active Starred", isStarred: true)
        store.addTask(title: "Done Task", isStarred: false)
        
        if let doneTask = store.items.first(where: { $0.title == "Done Task" }) {
            store.toggleCompleted(id: doneTask.id)
        }
        
        // All
        store.filter = .all
        XCTAssertEqual(store.filteredItems.count, 3)
        
        // Active
        store.filter = .active
        XCTAssertEqual(store.filteredItems.count, 2)
        
        // Starred
        store.filter = .starred
        XCTAssertEqual(store.filteredItems.count, 1)
        XCTAssertEqual(store.filteredItems.first?.title, "Active Starred")
        
        // Completed
        store.filter = .completed
        XCTAssertEqual(store.filteredItems.count, 1)
        XCTAssertEqual(store.filteredItems.first?.title, "Done Task")
    }
    
    func testThemeChange() {
        store.setPaneTheme(.cyberEmerald)
        XCTAssertEqual(store.paneTheme, .cyberEmerald)
        
        store.setPaneTheme(.obsidian)
        XCTAssertEqual(store.paneTheme, .obsidian)
    }
    
    func testClearCompleted() {
        store.addTask(title: "Task 1")
        store.addTask(title: "Task 2")
        if let first = store.items.first {
            store.toggleCompleted(id: first.id)
        }
        
        XCTAssertEqual(store.completedCount, 1)
        store.clearCompleted()
        XCTAssertEqual(store.totalCount, 1)
        XCTAssertEqual(store.completedCount, 0)
    }
    
    func testTaskOrderFirstAddedAtTopLastAddedAtBottom() {
        // User requirement: "the task added 1st shall be on the top and the task added at the end shall be added at the last"
        store.addTask(title: "First Added Task")
        store.addTask(title: "Second Added Task")
        store.addTask(title: "Third Added Task")
        store.addTask(title: "Last Added Task")
        
        let titles = store.filteredItems.map { $0.title }
        XCTAssertEqual(titles.first, "First Added Task", "First task added must be at index 0 (top)")
        XCTAssertEqual(titles.last, "Last Added Task", "Task added last must be at the end of the list")
        XCTAssertEqual(titles, [
            "First Added Task",
            "Second Added Task",
            "Third Added Task",
            "Last Added Task"
        ], "Tasks must strictly follow FIFO chronological addition order")
    }
}
