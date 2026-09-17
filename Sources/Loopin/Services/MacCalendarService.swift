import Foundation
import EventKit
import Combine
import SwiftUI

// MARK: - MacCalendarService
@MainActor
public final class MacCalendarService: ObservableObject {
    public static let shared = MacCalendarService()
    
    private let eventStore = EKEventStore()
    
    @Published public var macEvents: [CalendarEvent] = []
    @Published public var isSyncing: Bool = false
    @Published public var hasFullAccess: Bool = false
    @Published public var statusMessage: String = "Ready"
    
    public init() {
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            hasFullAccess = (status == .fullAccess)
        } else {
            hasFullAccess = (status == .authorized)
        }
    }
    
    public func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            hasFullAccess = granted
            return granted
        } catch {
            print("[MacCalendarService] Error requesting access: \(error.localizedDescription)")
            hasFullAccess = false
            return false
        }
    }
    
    /// Sync events from the MacBook Calendar app for a given year range (defaulting to ±1 year of today)
    public func fetchMacEvents(forYear year: Int) async -> [CalendarEvent] {
        if !hasFullAccess {
            let granted = await requestAccess()
            guard granted else {
                statusMessage = "Calendar access not granted"
                return []
            }
        }
        
        isSyncing = true
        statusMessage = "Fetching Mac calendar events..."
        
        let cal = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = year - 1
        startComponents.month = 1
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = year + 1
        endComponents.month = 12
        endComponents.day = 31
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        
        let startDate = cal.date(from: startComponents) ?? Date()
        let endDate = cal.date(from: endComponents) ?? Date()
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let rawEvents = eventStore.events(matching: predicate)
        
        var converted: [CalendarEvent] = []
        
        for ekEvent in rawEvents {
            let title = ekEvent.title ?? "Event"
            let isAllDay = ekEvent.isAllDay
            let calTitle = ekEvent.calendar.title.lowercased()
            let isHolidayCal = calTitle.contains("holiday") || calTitle.contains("festival") || ekEvent.calendar.type == .subscription
            
            // Map color
            let colorHex: String
            if let cgColor = ekEvent.calendar.cgColor,
               let nsColor = NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB) {
                let r = Float(nsColor.redComponent)
                let g = Float(nsColor.greenComponent)
                let b = Float(nsColor.blueComponent)
                colorHex = String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
            } else {
                colorHex = isHolidayCal ? "#34A853" : "#3B82F6"
            }
            
            let event = CalendarEvent(
                id: UUID(),
                title: title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                isAllDay: isAllDay,
                calendarId: isHolidayCal ? "holidays_india" : "mac_calendar",
                colorHex: colorHex,
                location: ekEvent.location,
                notes: ekEvent.notes,
                gcalId: ekEvent.eventIdentifier
            )
            converted.append(event)
        }
        
        // Apply holiday deduplication
        let deduped = deduplicateEvents(converted)
        self.macEvents = deduped
        self.isSyncing = false
        self.statusMessage = "Mac Calendar synced (\(deduped.count) events)"
        
        return deduped
    }
    
    // MARK: - Holiday & Event Deduplication
    /// Deduplicates duplicate holiday entries (e.g. "Janmashtami" from multiple subscriptions)
    public func deduplicateEvents(_ events: [CalendarEvent]) -> [CalendarEvent] {
        let cal = Calendar.current
        var nonHolidays: [CalendarEvent] = []
        var holidaysByDay: [Date: [CalendarEvent]] = [:]
        
        for event in events {
            if isHolidayEvent(event) {
                let dayKey = cal.startOfDay(for: event.startDate)
                holidaysByDay[dayKey, default: []].append(event)
            } else {
                nonHolidays.append(event)
            }
        }
        
        var dedupedHolidays: [CalendarEvent] = []
        
        for (_, dayHolidays) in holidaysByDay {
            var seenKeys: Set<String> = []
            
            for holiday in dayHolidays {
                let normalized = normalizeHolidayTitle(holiday.title)
                
                // Check if this normalized root matches any already accepted holiday for this day
                let isDuplicate = seenKeys.contains(where: { existing in
                    existing == normalized ||
                    (existing.count >= 4 && normalized.count >= 4 && (existing.contains(normalized) || normalized.contains(existing)))
                })
                
                if !isDuplicate {
                    seenKeys.insert(normalized)
                    dedupedHolidays.append(holiday)
                }
            }
        }
        
        return nonHolidays + dedupedHolidays
    }
    
    /// Normalizes a holiday title for collision matching
    public func normalizeHolidayTitle(_ raw: String) -> String {
        var str = raw.lowercased()
        
        // Remove symbols like stars, emojis, bullets
        str = str.replacingOccurrences(of: "★", with: "")
        str = str.replacingOccurrences(of: "⭐", with: "")
        str = str.replacingOccurrences(of: "•", with: "")
        
        // Remove parentheticals like "(smarta)", "(observed)", "(gazetted)", etc.
        if let regex = try? NSRegularExpression(pattern: "\\s*\\([^)]*\\)", options: []) {
            let range = NSRange(location: 0, length: str.utf16.count)
            str = regex.stringByReplacingMatches(in: str, options: [], range: range, withTemplate: "")
        }
        
        // Remove common holiday/festival suffix phrases
        let noiseSuffixes = [
            "'s birthday", " birthday", " jayanti", " festival", " day",
            " utsav", " celebration", " puja", " vrath", " eve"
        ]
        for suffix in noiseSuffixes {
            if str.hasSuffix(suffix) {
                str = String(str.dropLast(suffix.count))
            }
        }
        
        // Remove punctuation and extra whitespace
        str = str.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: " ")
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return str
    }
    
    /// Determines whether an event is considered a holiday/festival
    public func isHolidayEvent(_ event: CalendarEvent) -> Bool {
        if event.calendarId == "holidays_india" { return true }
        
        let lower = event.title.lowercased()
        let holidayKeywords = [
            "janmashtami", "ganesh", "chaturthi", "gandhi", "labor", "labour",
            "independence", "republic", "diwali", "deepavali", "holi", "shivratri",
            "eid", "christmas", "new year", "good friday", "raksha bandhan",
            "dussehra", "bhai dooj", "guru nanak", "ambedkar", "thanksgiving",
            "halloween", "memorial day", "veterans day", "martin luther", "presidents"
        ]
        
        return event.isAllDay && holidayKeywords.contains(where: { lower.contains($0) })
    }
}
