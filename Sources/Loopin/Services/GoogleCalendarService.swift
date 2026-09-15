import Foundation
import Combine

// MARK: - GoogleCalendarConfig
@MainActor
public final class GoogleCalendarConfig: ObservableObject, @unchecked Sendable {
    public static let shared = GoogleCalendarConfig()
    
    private let clientIdKey = "Loopin_GCal_ClientId"
    private let clientSecretKey = "Loopin_GCal_ClientSecret"
    private let accessTokenKey = "Loopin_GCal_AccessToken"
    private let refreshTokenKey = "Loopin_GCal_RefreshToken"
    private let plannedCalIdKey = "Loopin_GCal_PlannedCalId"
    private let loggedCalIdKey = "Loopin_GCal_LoggedCalId"
    
    @Published public var clientId: String {
        didSet { UserDefaults.standard.set(clientId, forKey: clientIdKey) }
    }
    
    @Published public var clientSecret: String {
        didSet { UserDefaults.standard.set(clientSecret, forKey: clientSecretKey) }
    }
    
    @Published public var accessToken: String? {
        didSet { UserDefaults.standard.set(accessToken, forKey: accessTokenKey) }
    }
    
    @Published public var refreshToken: String? {
        didSet { UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey) }
    }
    
    @Published public var plannedCalendarId: String? {
        didSet { UserDefaults.standard.set(plannedCalendarId, forKey: plannedCalIdKey) }
    }
    
    @Published public var loggedCalendarId: String? {
        didSet { UserDefaults.standard.set(loggedCalendarId, forKey: loggedCalIdKey) }
    }
    
    public init() {
        self.clientId = UserDefaults.standard.string(forKey: clientIdKey) ?? ""
        self.clientSecret = UserDefaults.standard.string(forKey: clientSecretKey) ?? ""
        self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        self.refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        self.plannedCalendarId = UserDefaults.standard.string(forKey: plannedCalIdKey)
        self.loggedCalendarId = UserDefaults.standard.string(forKey: loggedCalIdKey)
    }
    
    public var isConnected: Bool {
        return !(accessToken ?? "").isEmpty
    }
    
    public func disconnect() {
        accessToken = nil
        refreshToken = nil
        plannedCalendarId = nil
        loggedCalendarId = nil
    }
}

// MARK: - GoogleCalendarService
@MainActor
public final class GoogleCalendarService: ObservableObject, @unchecked Sendable {
    public static let shared = GoogleCalendarService()
    
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncDate: Date?
    @Published public var statusMessage: String = "Ready"
    
    private let session = URLSession(configuration: .default)
    
    public init() {}
    
    // MARK: - Event Serialization Helper
    public nonisolated static func makeCalendarEventPayload(for entry: TimesheetEntry) -> [String: Any] {
        let isoFormatter = ISO8601DateFormatter()
        let kindPrefix = entry.kind == EntryKind.planned.rawValue ? "[PLANNED] " : ""
        let summary = "\(kindPrefix)\(entry.rawText)"
        
        let desc = """
        Logged via Loopin
        Category: \(entry.category ?? "General")
        Productivity: \(entry.productivity?.capitalized ?? "Productive")
        Input Method: \(entry.inputMethod.capitalized)
        Duration: \(entry.formattedDuration)
        """
        
        return [
            "summary": summary,
            "description": desc,
            "start": ["dateTime": isoFormatter.string(from: entry.startAt)],
            "end": ["dateTime": isoFormatter.string(from: entry.endAt)]
        ]
    }
    
    // MARK: - Sync Entry to Google Calendar
    public func pushEntry(_ entry: TimesheetEntry) async throws -> String? {
        let config = GoogleCalendarConfig.shared
        guard let token = config.accessToken, !token.isEmpty else {
            return nil
        }
        
        let calendarId = (entry.kind == EntryKind.planned.rawValue)
            ? (config.plannedCalendarId ?? "primary")
            : (config.loggedCalendarId ?? "primary")
        
        let payload = Self.makeCalendarEventPayload(for: entry)
        let bodyData = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        var requestUrl: URL
        var method: String
        
        if let existingGCalId = entry.gcalEventId, !existingGCalId.isEmpty {
            // Update existing event
            let urlStr = "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events/\(existingGCalId)"
            guard let u = URL(string: urlStr) else { throw URLError(.badURL) }
            requestUrl = u
            method = "PUT"
        } else {
            // Insert new event
            let urlStr = "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events"
            guard let u = URL(string: urlStr) else { throw URLError(.badURL) }
            requestUrl = u
            method = "POST"
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData
        
        let (data, response) = try await session.data(for: request)
        if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let gcalId = json["id"] as? String {
                DatabaseManager.shared.markEntrySynced(id: entry.id, gcalEventId: gcalId)
                return gcalId
            }
        }
        
        return nil
    }
    
    // MARK: - Sync All Pending Entries
    public func syncAll() async {
        isSyncing = true
        statusMessage = "Syncing with Google Calendar..."
        
        let entries = DatabaseManager.shared.fetchAllEntries()
        var pushedCount = 0
        
        for entry in entries where entry.gcalEventId == nil {
            if let _ = try? await pushEntry(entry) {
                pushedCount += 1
            }
        }
        
        let now = Date()
        self.lastSyncDate = now
        self.isSyncing = false
        self.statusMessage = pushedCount > 0 ? "Synced \(pushedCount) events to Google Calendar" : "Calendars up to date"
    }
}
