import Foundation
import SwiftUI

// MARK: - CalendarEvent Model
public struct CalendarEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var calendarId: String // "primary", "logged", "planned", "birthdays", "holidays_india", "custom"
    public var colorHex: String
    public var location: String?
    public var notes: String?
    public var gcalId: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = true,
        calendarId: String = "primary",
        colorHex: String = "#0288EB",
        location: String? = nil,
        notes: String? = nil,
        gcalId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarId = calendarId
        self.colorHex = colorHex
        self.location = location
        self.notes = notes
        self.gcalId = gcalId
    }
    
    public var color: Color {
        Color(hex: colorHex)
    }
    
    /// Returns true if this event spans more than 1 calendar day
    public var isMultiDay: Bool {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: startDate)
        let endDay = cal.startOfDay(for: endDate)
        return startDay != endDay
    }
}

// MARK: - Color Hex Initializer
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 2, 136, 235) // Default accent blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "#0288EB" }
        let r = Float(components.redComponent)
        let g = Float(components.greenComponent)
        let b = Float(components.blueComponent)
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Calendar Meta Information
public struct CalendarMeta: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let colorHex: String
    public let isSystemOrHoliday: Bool
    
    public init(id: String, name: String, colorHex: String, isSystemOrHoliday: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isSystemOrHoliday = isSystemOrHoliday
    }
    
    public var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Holidays Provider (India & Global)
public enum HolidaysProvider {
    public static func holidays(for year: Int) -> [CalendarEvent] {
        var items: [CalendarEvent] = []
        let cal = Calendar.current
        
        func makeDate(year: Int, month: Int, day: Int) -> Date {
            var c = DateComponents()
            c.year = year
            c.month = month
            c.day = day
            c.hour = 0
            c.minute = 0
            c.second = 0
            return cal.date(from: c) ?? Date()
        }
        
        let emeraldGreen = "#34A853" // Google Calendar Holiday Green (#34A853)
        
        // India Holidays (Fixed and key festivals for 2025, 2026, 2027)
        let holidayTable: [(month: Int, day: Int, name: String)] = [
            (1, 26, "Republic Day"),
            (3, 4, "Maha Shivratri"),
            (3, 15, "Holi"),
            (4, 3, "Good Friday"),
            (4, 14, "Ambedkar Jayanti"),
            (5, 1, "Labour Day"),
            (8, 15, "Independence Day"),
            (8, 28, "Raksha Bandhan"),
            (9, 4, "Janmashtami (Smarta)"),
            (9, 14, "Ganesh Chaturthi"),
            (10, 2, "Mahatma Gandhi Jayanti"),
            (10, 20, "Dussehra (Vijayadashami)"),
            (11, 8, "Diwali (Deepavali)"),
            (11, 9, "Govardhan Puja"),
            (11, 10, "Bhai Dooj"),
            (11, 24, "Guru Nanak Jayanti"),
            (12, 25, "Christmas Day"),
            (1, 1, "New Year's Day")
        ]
        
        for h in holidayTable {
            let sDate = makeDate(year: year, month: h.month, day: h.day)
            let eDate = sDate
            items.append(CalendarEvent(
                id: UUID(),
                title: h.name,
                startDate: sDate,
                endDate: eDate,
                isAllDay: true,
                calendarId: "holidays_india",
                colorHex: emeraldGreen,
                location: "India"
            ))
        }
        
        return items
    }
}
