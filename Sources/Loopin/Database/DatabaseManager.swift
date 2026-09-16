import Foundation
import SQLite3

// MARK: - DatabaseManager
public final class DatabaseManager: @unchecked Sendable {
    public static let shared = DatabaseManager()
    public static let didChangeNotification = Notification.Name("DatabaseManagerDidChangeNotification")
    public static let syncStatusDidChangeNotification = Notification.Name("SyncStatusDidChangeNotification")
    
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.loopin.database", qos: .userInitiated)
    private let path: String
    
    public init(inMemory: Bool = false) {
        if inMemory {
            self.path = ":memory:"
        } else {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("Loopin", isDirectory: true)
            
            if !fileManager.fileExists(atPath: appDir.path) {
                try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            }
            self.path = appDir.appendingPathComponent("loopin.sqlite").path
        }
        
        openDatabase()
        createTables()
        runMigrations()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Error opening database at \(path): \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    private func createTables() {
        let createEntriesSQL = """
        CREATE TABLE IF NOT EXISTS timesheet_entries (
            id TEXT PRIMARY KEY,
            kind TEXT NOT NULL,
            start_at REAL NOT NULL,
            end_at REAL NOT NULL,
            raw_text TEXT NOT NULL,
            input_method TEXT NOT NULL,
            category TEXT,
            subcategory TEXT,
            productivity TEXT,
            gcal_event_id TEXT,
            device_id TEXT DEFAULT 'macOS',
            is_synced INTEGER DEFAULT 0,
            updated_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_entries_start_at ON timesheet_entries(start_at);
        CREATE INDEX IF NOT EXISTS idx_entries_end_at ON timesheet_entries(end_at);
        CREATE INDEX IF NOT EXISTS idx_entries_kind ON timesheet_entries(kind);
        CREATE INDEX IF NOT EXISTS idx_entries_synced ON timesheet_entries(is_synced);
        """
        
        let createRulesSQL = """
        CREATE TABLE IF NOT EXISTS classification_rules (
            id TEXT PRIMARY KEY,
            phrase TEXT UNIQUE NOT NULL,
            category TEXT NOT NULL,
            subcategory TEXT,
            productivity TEXT NOT NULL,
            updated_at REAL NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_rules_phrase ON classification_rules(phrase);
        """
        
        queue.sync {
            _ = self.execute(sql: createEntriesSQL)
            _ = self.execute(sql: createRulesSQL)
        }
    }
    
    private func runMigrations() {
        queue.sync {
            // Safely attempt adding columns if table already existed from Phase 1
            _ = self.execute(sql: "ALTER TABLE timesheet_entries ADD COLUMN gcal_event_id TEXT;")
            _ = self.execute(sql: "ALTER TABLE timesheet_entries ADD COLUMN device_id TEXT DEFAULT 'macOS';")
            _ = self.execute(sql: "ALTER TABLE timesheet_entries ADD COLUMN is_synced INTEGER DEFAULT 0;")
            
            // Binary productivity migration: migrate all legacy 'neutral' records to 'wasteful' (Non-Productive)
            _ = self.execute(sql: "UPDATE timesheet_entries SET productivity = 'wasteful' WHERE productivity = 'neutral' OR productivity IS NULL OR productivity = '';")
            _ = self.execute(sql: "UPDATE classification_rules SET productivity = 'wasteful' WHERE productivity = 'neutral';")
            _ = self.execute(sql: "DELETE FROM classification_rules WHERE phrase LIKE '%got bigbasket and trying fixing app%';")
            
            // Cleanup: remove any skipped intervals so they do not show on the timesheet
            _ = self.execute(sql: "DELETE FROM timesheet_entries WHERE input_method = 'skipped' OR LOWER(raw_text) = 'skipped interval' OR LOWER(raw_text) = 'skipped';")
            
            // Correct misclassified entries like "Nothing" or slang to wasteful (Non-Productive)
            _ = self.execute(sql: "UPDATE timesheet_entries SET productivity = 'wasteful', category = 'Rest & Leisure' WHERE LOWER(TRIM(raw_text)) = 'nothing' OR LOWER(raw_text) LIKE 'chutiyap%' OR LOWER(raw_text) LIKE 'bakchodi%' OR LOWER(raw_text) LIKE 'timepass%' OR LOWER(raw_text) LIKE 'chill%';")
            _ = self.execute(sql: "UPDATE classification_rules SET productivity = 'wasteful', category = 'Rest & Leisure' WHERE LOWER(TRIM(phrase)) = 'nothing' OR LOWER(phrase) LIKE 'chutiyap%' OR LOWER(phrase) LIKE 'bakchodi%' OR LOWER(phrase) LIKE 'timepass%' OR LOWER(phrase) LIKE 'chill%';")
        }
    }
    
    private func execute(sql: String) -> Bool {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let msg = errMsg {
                let errStr = String(cString: msg)
                // Ignore "duplicate column name" harmless error during migration
                if !errStr.contains("duplicate column") {
                    print("SQLite Exec Error: \(errStr)")
                }
                sqlite3_free(errMsg)
            }
            return false
        }
        return true
    }
    
    private func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: DatabaseManager.didChangeNotification, object: nil)
        }
    }
    
    // MARK: - TimesheetEntry CRUD
    
    public func insertEntry(_ entry: TimesheetEntry) {
        queue.sync {
            let sql = """
            INSERT OR REPLACE INTO timesheet_entries 
            (id, kind, start_at, end_at, raw_text, input_method, category, subcategory, productivity, gcal_event_id, device_id, is_synced, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (entry.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (entry.kind as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 3, entry.startAt.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 4, entry.endAt.timeIntervalSince1970)
                sqlite3_bind_text(stmt, 5, (entry.rawText as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 6, (entry.inputMethod as NSString).utf8String, -1, nil)
                
                if let cat = entry.category {
                    sqlite3_bind_text(stmt, 7, (cat as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 7)
                }
                
                if let sub = entry.subcategory {
                    sqlite3_bind_text(stmt, 8, (sub as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 8)
                }
                
                if let prod = entry.productivity {
                    sqlite3_bind_text(stmt, 9, (prod as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 9)
                }
                
                if let gcal = entry.gcalEventId {
                    sqlite3_bind_text(stmt, 10, (gcal as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 10)
                }
                
                sqlite3_bind_text(stmt, 11, (entry.deviceId as NSString).utf8String, -1, nil)
                sqlite3_bind_int(stmt, 12, entry.isSynced ? 1 : 0)
                sqlite3_bind_double(stmt, 13, entry.updatedAt.timeIntervalSince1970)
                
                if sqlite3_step(stmt) != SQLITE_DONE {
                    print("Error inserting entry: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            }
            sqlite3_finalize(stmt)
        }
        notifyChange()
    }
    
    public func updateEntry(_ entry: TimesheetEntry) {
        insertEntry(entry)
    }
    
    public func deleteEntry(id: String) {
        queue.sync {
            let sql = "DELETE FROM timesheet_entries WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                _ = sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
        notifyChange()
    }
    
    public func fetchEntry(id: String) -> TimesheetEntry? {
        return queue.sync {
            let sql = "SELECT id, kind, start_at, end_at, raw_text, input_method, category, subcategory, productivity, gcal_event_id, device_id, is_synced, updated_at FROM timesheet_entries WHERE id = ? LIMIT 1;"
            var stmt: OpaquePointer?
            var entry: TimesheetEntry?
            
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                if sqlite3_step(stmt) == SQLITE_ROW {
                    entry = parseEntryRow(stmt)
                }
            }
            sqlite3_finalize(stmt)
            return entry
        }
    }
    
    public func fetchAllEntries() -> [TimesheetEntry] {
        return queue.sync {
            let sql = "SELECT id, kind, start_at, end_at, raw_text, input_method, category, subcategory, productivity, gcal_event_id, device_id, is_synced, updated_at FROM timesheet_entries ORDER BY start_at ASC;"
            var stmt: OpaquePointer?
            var results: [TimesheetEntry] = []
            
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let entry = parseEntryRow(stmt) {
                        results.append(entry)
                    }
                }
            }
            sqlite3_finalize(stmt)
            return results
        }
    }
    
    public func fetchPendingSyncEntries() -> [TimesheetEntry] {
        return queue.sync {
            let sql = "SELECT id, kind, start_at, end_at, raw_text, input_method, category, subcategory, productivity, gcal_event_id, device_id, is_synced, updated_at FROM timesheet_entries WHERE is_synced = 0 ORDER BY updated_at ASC;"
            var stmt: OpaquePointer?
            var results: [TimesheetEntry] = []
            
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let entry = parseEntryRow(stmt) {
                        results.append(entry)
                    }
                }
            }
            sqlite3_finalize(stmt)
            return results
        }
    }
    
    public func markEntrySynced(id: String, gcalEventId: String? = nil) {
        queue.sync {
            let sql = "UPDATE timesheet_entries SET is_synced = 1, gcal_event_id = COALESCE(?, gcal_event_id) WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                if let gcal = gcalEventId {
                    sqlite3_bind_text(stmt, 1, (gcal as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 1)
                }
                sqlite3_bind_text(stmt, 2, (id as NSString).utf8String, -1, nil)
                _ = sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func fetchForDay(_ date: Date) -> [TimesheetEntry] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return fetchEntriesInRange(start: startOfDay, end: endOfDay)
    }
    
    public func fetchForWeek(_ weekStart: Date) -> [TimesheetEntry] {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: weekStart)
        guard let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfDay) else {
            return []
        }
        return fetchEntriesInRange(start: startOfDay, end: endOfWeek)
    }
    
    public func fetchEntriesInRange(start: Date, end: Date) -> [TimesheetEntry] {
        return queue.sync {
            let sql = """
            SELECT id, kind, start_at, end_at, raw_text, input_method, category, subcategory, productivity, gcal_event_id, device_id, is_synced, updated_at 
            FROM timesheet_entries 
            WHERE (start_at >= ? AND start_at < ?) OR (end_at > ? AND end_at <= ?) OR (start_at <= ? AND end_at >= ?)
            ORDER BY start_at ASC;
            """
            var stmt: OpaquePointer?
            var results: [TimesheetEntry] = []
            
            let startT = start.timeIntervalSince1970
            let endT = end.timeIntervalSince1970
            
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_double(stmt, 1, startT)
                sqlite3_bind_double(stmt, 2, endT)
                sqlite3_bind_double(stmt, 3, startT)
                sqlite3_bind_double(stmt, 4, endT)
                sqlite3_bind_double(stmt, 5, startT)
                sqlite3_bind_double(stmt, 6, endT)
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let entry = parseEntryRow(stmt) {
                        results.append(entry)
                    }
                }
            }
            sqlite3_finalize(stmt)
            return results
        }
    }
    
    private func parseEntryRow(_ stmt: OpaquePointer?) -> TimesheetEntry? {
        guard let stmt = stmt else { return nil }
        
        let id = String(cString: sqlite3_column_text(stmt, 0))
        let kind = String(cString: sqlite3_column_text(stmt, 1))
        let startAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2))
        let endAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
        let rawText = String(cString: sqlite3_column_text(stmt, 4))
        let inputMethod = String(cString: sqlite3_column_text(stmt, 5))
        
        var category: String?
        if let catPtr = sqlite3_column_text(stmt, 6) {
            category = String(cString: catPtr)
        }
        
        var subcategory: String?
        if let subPtr = sqlite3_column_text(stmt, 7) {
            subcategory = String(cString: subPtr)
        }
        
        var productivity: String?
        if let prodPtr = sqlite3_column_text(stmt, 8) {
            productivity = String(cString: prodPtr)
        }
        
        var gcalEventId: String?
        if let gcalPtr = sqlite3_column_text(stmt, 9) {
            gcalEventId = String(cString: gcalPtr)
        }
        
        var deviceId = "macOS"
        if let devPtr = sqlite3_column_text(stmt, 10) {
            deviceId = String(cString: devPtr)
        }
        
        let isSynced = sqlite3_column_int(stmt, 11) == 1
        let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 12))
        
        return TimesheetEntry(
            id: id,
            kind: kind,
            startAt: startAt,
            endAt: endAt,
            rawText: rawText,
            inputMethod: inputMethod,
            category: category,
            subcategory: subcategory,
            productivity: productivity,
            gcalEventId: gcalEventId,
            deviceId: deviceId,
            isSynced: isSynced,
            updatedAt: updatedAt
        )
    }
    
    // MARK: - Classification Rules CRUD
    
    public func insertRule(_ rule: ClassificationRule) {
        queue.sync {
            let sql = """
            INSERT OR REPLACE INTO classification_rules 
            (id, phrase, category, subcategory, productivity, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (rule.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (rule.phrase as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 3, (rule.category as NSString).utf8String, -1, nil)
                
                if let sub = rule.subcategory {
                    sqlite3_bind_text(stmt, 4, (sub as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 4)
                }
                
                sqlite3_bind_text(stmt, 5, (rule.productivity as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 6, rule.updatedAt.timeIntervalSince1970)
                
                _ = sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
        notifyChange()
    }
    
    public func updateRule(_ rule: ClassificationRule) {
        insertRule(rule)
    }
    
    public func deleteRule(id: String) {
        queue.sync {
            let sql = "DELETE FROM classification_rules WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                _ = sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
        notifyChange()
    }
    
    public func fetchAllRules() -> [ClassificationRule] {
        return queue.sync {
            let sql = "SELECT id, phrase, category, subcategory, productivity, updated_at FROM classification_rules ORDER BY length(phrase) DESC;"
            var stmt: OpaquePointer?
            var results: [ClassificationRule] = []
            
            if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(stmt, 0))
                    let phrase = String(cString: sqlite3_column_text(stmt, 1))
                    let category = String(cString: sqlite3_column_text(stmt, 2))
                    
                    var subcategory: String?
                    if let subPtr = sqlite3_column_text(stmt, 3) {
                        subcategory = String(cString: subPtr)
                    }
                    
                    let productivity = String(cString: sqlite3_column_text(stmt, 4))
                    let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
                    
                    results.append(ClassificationRule(
                        id: id,
                        phrase: phrase,
                        category: category,
                        subcategory: subcategory,
                        productivity: productivity,
                        updatedAt: updatedAt
                    ))
                }
            }
            sqlite3_finalize(stmt)
            return results
        }
    }
    
    public func clearAllData() {
        queue.sync {
            _ = self.execute(sql: "DELETE FROM timesheet_entries; DELETE FROM classification_rules;")
        }
        notifyChange()
    }
}
