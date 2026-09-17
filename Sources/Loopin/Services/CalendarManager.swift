import Foundation
import Combine
import SwiftUI

@MainActor
public final class CalendarManager: ObservableObject {
    public static let shared = CalendarManager()
    
    private let customEventsStorageKey = "Loopin_Calendar_CustomEvents"
    private let visibleCalendarsKey = "Loopin_Calendar_VisibleIds_v2"
    
    @Published public var customEvents: [CalendarEvent] = []
    @Published public var googleEvents: [CalendarEvent] = []
    
    // Four real, toggleable calendar groups:
    // 1. "logged" -> Actual logged entries from app
    // 2. "planned" -> Planned rails / tasks
    // 3. "google" -> Connected Google Calendar
    // 4. "holidays_india" -> Official Indian holidays
    @Published public var visibleCalendarIds: Set<String> = ["logged", "planned", "google", "holidays_india"] {
        didSet {
            UserDefaults.standard.set(Array(visibleCalendarIds), forKey: visibleCalendarsKey)
        }
    }
    
    @Published public var isSyncing: Bool = false
    @Published public var syncStatusMessage: String = "Calendars in sync"
    @Published public var lastSyncDate: Date? = Date()
    
    public init() {
        loadSettings()
        loadEvents()
    }
    
    private func loadSettings() {
        if let saved = UserDefaults.standard.stringArray(forKey: visibleCalendarsKey), !saved.isEmpty {
            visibleCalendarIds = Set(saved)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: customEventsStorageKey),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            // Filter out any legacy test dummy events
            customEvents = decoded.filter {
                $0.title != "Product Roadmap Review" &&
                $0.title != "Sample Event" &&
                !$0.title.lowercased().contains("test event")
            }
            saveCustomEvents()
        } else {
            customEvents = []
        }
    }
    
    private func saveCustomEvents() {
        if let data = try? JSONEncoder().encode(customEvents) {
            UserDefaults.standard.set(data, forKey: customEventsStorageKey)
        }
    }
    
    // MARK: - Event CRUD
    public func addEvent(_ event: CalendarEvent) {
        customEvents.append(event)
        saveCustomEvents()
        objectWillChange.send()
        
        Task {
            await pushEventToGoogleCalendarIfNeeded(event)
        }
    }
    
    public func updateEvent(_ event: CalendarEvent) {
        if let index = customEvents.firstIndex(where: { $0.id == event.id }) {
            customEvents[index] = event
            saveCustomEvents()
            objectWillChange.send()
            
            Task {
                await pushEventToGoogleCalendarIfNeeded(event)
            }
        }
    }
    
    public func deleteEvent(id: UUID) {
        customEvents.removeAll { $0.id == id }
        googleEvents.removeAll { $0.id == id }
        saveCustomEvents()
        objectWillChange.send()
    }
    
    public func toggleCalendarVisibility(id: String) {
        if visibleCalendarIds.contains(id) {
            visibleCalendarIds.remove(id)
        } else {
            visibleCalendarIds.insert(id)
        }
        objectWillChange.send()
    }
    
    public func isCalendarVisible(id: String) -> Bool {
        visibleCalendarIds.contains(id)
    }
    
    // MARK: - Aggregated Visible Events
    public func allVisibleEvents(forYear year: Int) -> [CalendarEvent] {
        var result: [CalendarEvent] = []
        
        // 1. Indian Holidays Calendar
        if visibleCalendarIds.contains("holidays_india") {
            let holidays = HolidaysProvider.holidays(for: year)
            let prevHolidays = HolidaysProvider.holidays(for: year - 1)
            let nextHolidays = HolidaysProvider.holidays(for: year + 1)
            result.append(contentsOf: holidays + prevHolidays + nextHolidays)
        }
        
        // 2. Loopin Log Sheet Entries (Actual entries logged on the app itself)
        if visibleCalendarIds.contains("logged") {
            let entries = DatabaseManager.shared.fetchAllEntries().filter { $0.kind == EntryKind.logged.rawValue }
            for entry in entries {
                let colorHex = entry.productivity == "wasteful" ? "#EF4444" : "#10B981"
                result.append(CalendarEvent(
                    id: UUID(uuidString: entry.id) ?? UUID(),
                    title: entry.rawText.isEmpty ? (entry.category ?? "Log Sheet") : entry.rawText,
                    startDate: entry.startAt,
                    endDate: entry.endAt,
                    isAllDay: false,
                    calendarId: "logged",
                    colorHex: colorHex,
                    notes: "Log Sheet • \(entry.productivity?.capitalized ?? "Productive")"
                ))
            }
        }
        
        // 3. Loopin Pre-planned Entries (Planned blocks)
        if visibleCalendarIds.contains("planned") {
            let entries = DatabaseManager.shared.fetchAllEntries().filter { $0.kind == EntryKind.planned.rawValue }
            for entry in entries {
                result.append(CalendarEvent(
                    id: UUID(uuidString: entry.id) ?? UUID(),
                    title: entry.rawText.isEmpty ? (entry.category ?? "Pre-planned") : entry.rawText,
                    startDate: entry.startAt,
                    endDate: entry.endAt,
                    isAllDay: false,
                    calendarId: "planned",
                    colorHex: "#8B5CF6",
                    notes: "Pre-planned Block"
                ))
            }
            
            // Custom pre-planned events created directly in Calendar
            let customPlanned = customEvents.filter { $0.calendarId == "planned" || $0.calendarId == "primary" }
            result.append(contentsOf: customPlanned)
        }
        
        // 4. Connected Google Calendar Events
        if visibleCalendarIds.contains("google") {
            result.append(contentsOf: googleEvents)
            let customGoogle = customEvents.filter { $0.calendarId == "google" }
            result.append(contentsOf: customGoogle)
        }
        
        return result
    }
    
    // MARK: - Google Calendar Sync
    public func syncWithGoogleCalendar() async {
        isSyncing = true
        syncStatusMessage = "Syncing with Google Calendar..."
        
        // Push pending local entries
        await GoogleCalendarService.shared.syncAll()
        
        // Pull remote events if signed in
        if AppState.shared.isSignedInWithGoogle {
            let cal = Calendar.current
            let now = Date()
            let timeMin = cal.date(byAdding: .month, value: -6, to: now) ?? now
            let timeMax = cal.date(byAdding: .month, value: 12, to: now) ?? now
            
            let remoteEvents = await GoogleCalendarService.shared.fetchEvents(timeMin: timeMin, timeMax: timeMax)
            if !remoteEvents.isEmpty {
                self.googleEvents = remoteEvents
            }
        }
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        self.lastSyncDate = Date()
        self.isSyncing = false
        self.syncStatusMessage = "All calendars up to date"
        
        AppState.shared.triggerCelebration()
    }
    
    private func pushEventToGoogleCalendarIfNeeded(_ event: CalendarEvent) async {
        guard GoogleCalendarConfig.shared.isConnected else { return }
        
        let entry = TimesheetEntry(
            id: event.id.uuidString,
            kind: event.calendarId == "logged" ? EntryKind.logged.rawValue : EntryKind.planned.rawValue,
            startAt: event.startDate,
            endAt: event.endDate,
            rawText: event.title,
            inputMethod: "calendar",
            category: "Calendar Event",
            productivity: "productive",
            gcalEventId: event.gcalId
        )
        
        _ = try? await GoogleCalendarService.shared.pushEntry(entry)
    }
}
