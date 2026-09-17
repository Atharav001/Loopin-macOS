import Foundation
import Combine
import SwiftUI

@MainActor
public final class CalendarManager: ObservableObject {
    public static let shared = CalendarManager()
    
    private let customEventsStorageKey = "Loopin_Calendar_CustomEvents"
    private let visibleCalendarsKey = "Loopin_Calendar_VisibleIds"
    
    @Published public var customEvents: [CalendarEvent] = []
    @Published public var visibleCalendarIds: Set<String> = ["primary", "birthdays", "tasks", "holidays_india"] {
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
        if let saved = UserDefaults.standard.stringArray(forKey: visibleCalendarsKey) {
            visibleCalendarIds = Set(saved)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: customEventsStorageKey),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            customEvents = decoded
        } else {
            // Seed a sample initial event if none exists
            let cal = Calendar.current
            let now = Date()
            let sample = CalendarEvent(
                title: "Product Roadmap Review",
                startDate: now,
                endDate: cal.date(byAdding: .day, value: 2, to: now) ?? now,
                isAllDay: true,
                calendarId: "primary",
                colorHex: "#0288EB",
                notes: "Quarterly review of Loopin features"
            )
            customEvents = [sample]
            saveCustomEvents()
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
        
        // If Google Calendar is connected, push asynchronously
        Task {
            await pushEventToGoogleCalendarIfNeeded(event)
        }
    }
    
    public func updateEvent(_ event: CalendarEvent) {
        if let index = customEvents.firstIndex(where: { $0.id == event.id }) {
            customEvents[index] = event
            saveCustomEvents()
            
            Task {
                await pushEventToGoogleCalendarIfNeeded(event)
            }
        }
    }
    
    public func deleteEvent(id: UUID) {
        customEvents.removeAll { $0.id == id }
        saveCustomEvents()
    }
    
    public func toggleCalendarVisibility(id: String) {
        if visibleCalendarIds.contains(id) {
            visibleCalendarIds.remove(id)
        } else {
            visibleCalendarIds.insert(id)
        }
    }
    
    public func isCalendarVisible(id: String) -> Bool {
        visibleCalendarIds.contains(id)
    }
    
    // MARK: - Filtered Active Events
    public func allVisibleEvents(forYear year: Int) -> [CalendarEvent] {
        var result: [CalendarEvent] = []
        
        // 1. Holidays in India
        if visibleCalendarIds.contains("holidays_india") {
            let holidays = HolidaysProvider.holidays(for: year)
            // also load previous and next year for edge months (Dec-Jan)
            let prevHolidays = HolidaysProvider.holidays(for: year - 1)
            let nextHolidays = HolidaysProvider.holidays(for: year + 1)
            result.append(contentsOf: holidays + prevHolidays + nextHolidays)
        }
        
        // 2. Custom Events (User's primary, birthdays, custom)
        let filteredCustom = customEvents.filter { visibleCalendarIds.contains($0.calendarId) }
        result.append(contentsOf: filteredCustom)
        
        // 3. Loopin Logged & Planned Timesheet Entries
        if visibleCalendarIds.contains("tasks") {
            let entries = DatabaseManager.shared.fetchAllEntries()
            for entry in entries {
                let colorHex = entry.kind == EntryKind.planned.rawValue ? "#8B5CF6" : "#10B981"
                let calId = "tasks"
                let calEvent = CalendarEvent(
                    id: UUID(uuidString: entry.id) ?? UUID(),
                    title: entry.rawText.isEmpty ? (entry.category ?? "Activity") : entry.rawText,
                    startDate: entry.startAt,
                    endDate: entry.endAt,
                    isAllDay: false,
                    calendarId: calId,
                    colorHex: colorHex,
                    notes: "Logged via Loopin: \(entry.productivity ?? "productive")"
                )
                result.append(calEvent)
            }
        }
        
        return result
    }
    
    // MARK: - Google Calendar Sync
    public func syncWithGoogleCalendar() async {
        isSyncing = true
        syncStatusMessage = "Syncing with Google Calendar..."
        
        // Call GoogleCalendarService
        await GoogleCalendarService.shared.syncAll()
        
        // Artificial micro-pause for smooth UI feedback
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        self.lastSyncDate = Date()
        self.isSyncing = false
        self.syncStatusMessage = "All calendars up to date"
        
        AppState.shared.triggerCelebration()
    }
    
    private func pushEventToGoogleCalendarIfNeeded(_ event: CalendarEvent) async {
        guard GoogleCalendarConfig.shared.isConnected else { return }
        
        // Create matching TimesheetEntry payload for pushEntry
        let entry = TimesheetEntry(
            id: event.id.uuidString,
            kind: EntryKind.planned.rawValue,
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
