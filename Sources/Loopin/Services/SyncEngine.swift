import Foundation
import Combine

// MARK: - SyncStatus
public enum SyncStatus: Equatable, Sendable {
    case unconfigured
    case idle
    case syncing
    case synced(Date)
    case error(String)
    
    public var displayText: String {
        switch self {
        case .unconfigured: return "Offline (Local SQLite)"
        case .idle: return "Ready to Sync"
        case .syncing: return "Syncing with Cloud..."
        case .synced(let date):
            let f = DateFormatter()
            f.timeStyle = .short
            return "Synced at \(f.string(from: date))"
        case .error(let msg): return "Sync Error: \(msg)"
        }
    }
    
    public var statusDotColor: String {
        switch self {
        case .unconfigured: return "gray"
        case .idle: return "blue"
        case .syncing: return "orange"
        case .synced: return "green"
        case .error: return "red"
        }
    }
}

// MARK: - SyncEngine
@MainActor
public final class SyncEngine: ObservableObject, @unchecked Sendable {
    public static let shared = SyncEngine()
    
    @Published public var syncStatus: SyncStatus = .unconfigured
    @Published public var pendingCount: Int = 0
    @Published public var lastSyncTime: Date?
    
    private var syncTimer: AnyCancellable?
    private let session = URLSession(configuration: .default)
    
    public init() {
        refreshPendingCount()
        checkConfiguration()
    }
    
    public func checkConfiguration() {
        if SupabaseConfig.shared.isConfigured {
            if case .unconfigured = syncStatus {
                syncStatus = .idle
            }
        } else {
            syncStatus = .unconfigured
        }
    }
    
    public func refreshPendingCount() {
        let pending = DatabaseManager.shared.fetchPendingSyncEntries()
        self.pendingCount = pending.count
    }
    
    public func startAutoSync(intervalSeconds: TimeInterval = 60) {
        syncTimer?.cancel()
        syncTimer = Timer.publish(every: intervalSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, SupabaseConfig.shared.isAutoSyncEnabled else { return }
                Task {
                    await self.syncNow()
                }
            }
    }
    
    public func stopAutoSync() {
        syncTimer?.cancel()
        syncTimer = nil
    }
    
    public func syncNow() async {
        guard SupabaseConfig.shared.isConfigured else {
            syncStatus = .unconfigured
            return
        }
        
        syncStatus = .syncing
        
        let pending = DatabaseManager.shared.fetchPendingSyncEntries()
        self.pendingCount = pending.count
        
        do {
            if !pending.isEmpty {
                try await pushEntriesToSupabase(pending)
            }
            
            // Mark pushed entries as synced locally
            for entry in pending {
                DatabaseManager.shared.markEntrySynced(id: entry.id)
            }
            
            // Pull any remote entries
            try await pullEntriesFromSupabase()
            
            let now = Date()
            self.lastSyncTime = now
            self.syncStatus = .synced(now)
            self.refreshPendingCount()
        } catch {
            self.syncStatus = .error(error.localizedDescription)
            self.refreshPendingCount()
        }
    }
    
    // MARK: - PostgREST Push
    private func pushEntriesToSupabase(_ entries: [TimesheetEntry]) async throws {
        let config = SupabaseConfig.shared
        guard let url = URL(string: "\(config.projectUrl)/rest/v1/timesheet_entries") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonApiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.authToken ?? config.anonApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Map to PostgREST JSON format
        let payload = entries.map { entry in
            [
                "id": entry.id,
                "kind": entry.kind,
                "start_at": ISO8601DateFormatter().string(from: entry.startAt),
                "end_at": ISO8601DateFormatter().string(from: entry.endAt),
                "raw_text": entry.rawText,
                "input_method": entry.inputMethod,
                "category": entry.category as Any,
                "subcategory": entry.subcategory as Any,
                "productivity": entry.productivity as Any,
                "gcal_event_id": entry.gcalEventId as Any,
                "device_id": entry.deviceId,
                "updated_at": ISO8601DateFormatter().string(from: entry.updatedAt)
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let (_, response) = try await session.data(for: request)
        if let httpRes = response as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            throw NSError(domain: "SupabaseSync", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpRes.statusCode)"])
        }
    }
    
    // MARK: - PostgREST Pull
    private func pullEntriesFromSupabase() async throws {
        let config = SupabaseConfig.shared
        guard let url = URL(string: "\(config.projectUrl)/rest/v1/timesheet_entries?select=*&order=updated_at.desc&limit=100") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(config.anonApiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.authToken ?? config.anonApiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                let isoFormatter = ISO8601DateFormatter()
                for dict in jsonArray {
                    guard let id = dict["id"] as? String,
                          let kind = dict["kind"] as? String,
                          let startStr = dict["start_at"] as? String,
                          let endStr = dict["end_at"] as? String,
                          let rawText = dict["raw_text"] as? String,
                          let startAt = isoFormatter.date(from: startStr),
                          let endAt = isoFormatter.date(from: endStr) else { continue }
                    
                    let inputMethod = dict["input_method"] as? String ?? "typed"
                    let category = dict["category"] as? String
                    let subcategory = dict["subcategory"] as? String
                    let productivity = dict["productivity"] as? String
                    let gcalEventId = dict["gcal_event_id"] as? String
                    let deviceId = dict["device_id"] as? String ?? "remote"
                    let updatedAt = (dict["updated_at"] as? String).flatMap { isoFormatter.date(from: $0) } ?? Date()
                    
                    let remoteEntry = TimesheetEntry(
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
                        isSynced: true,
                        updatedAt: updatedAt
                    )
                    
                    // Upsert into local SQLite if newer or not present
                    if let local = DatabaseManager.shared.fetchEntry(id: id) {
                        if remoteEntry.updatedAt > local.updatedAt {
                            DatabaseManager.shared.updateEntry(remoteEntry)
                        }
                    } else {
                        DatabaseManager.shared.insertEntry(remoteEntry)
                    }
                }
            }
        }
    }
}
