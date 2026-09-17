import Foundation
import SwiftUI

// MARK: - CalendarEvent Model
public struct CalendarEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var calendarId: String // "logged", "planned", "google", "holidays_india"
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
        calendarId: String = "planned",
        colorHex: String = "#8B5CF6",
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 2, 136, 235)
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

// MARK: - Holidays Provider (Accurate Year-Specific Indian Holidays)
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
        
        // 1. Fixed National Holidays (Same date every year)
        let fixedHolidays: [(month: Int, day: Int, name: String)] = [
            (1, 1, "New Year's Day"),
            (1, 26, "Republic Day"),
            (4, 14, "Dr. Ambedkar Jayanti"),
            (5, 1, "Maharashtra Day / Labour Day"),
            (8, 15, "Independence Day"),
            (10, 2, "Mahatma Gandhi Jayanti"),
            (12, 25, "Christmas Day")
        ]
        
        for h in fixedHolidays {
            let d = makeDate(year: year, month: h.month, day: h.day)
            items.append(CalendarEvent(
                id: UUID(),
                title: h.name,
                startDate: d,
                endDate: d,
                isAllDay: true,
                calendarId: "holidays_india",
                colorHex: emeraldGreen,
                location: "India"
            ))
        }
        
        // 2. Year-Specific Movable Festivals (Astronomic Lunar Calendar for India)
        let movableTableByYear: [Int: [(month: Int, day: Int, name: String)]] = [
            2025: [
                (2, 26, "Maha Shivratri"),
                (3, 14, "Holi"),
                (3, 31, "Eid-ul-Fitr"),
                (4, 18, "Good Friday"),
                (8, 9, "Raksha Bandhan"),
                (8, 16, "Janmashtami (Smarta)"),
                (8, 27, "Ganesh Chaturthi"),
                (10, 2, "Dussehra (Vijayadashami)"),
                (10, 20, "Diwali (Deepavali)"),
                (10, 22, "Bhai Dooj"),
                (11, 5, "Guru Nanak Jayanti")
            ],
            2026: [
                (3, 4, "Maha Shivratri"),
                (3, 15, "Holi"),
                (3, 20, "Eid-ul-Fitr"),
                (4, 3, "Good Friday"),
                (8, 28, "Raksha Bandhan"),
                (9, 4, "Janmashtami (Smarta)"),
                (9, 14, "Ganesh Chaturthi"),
                (10, 20, "Dussehra (Vijayadashami)"),
                (11, 8, "Diwali (Deepavali)"),
                (11, 9, "Govardhan Puja"),
                (11, 10, "Bhai Dooj"),
                (11, 24, "Guru Nanak Jayanti")
            ],
            2027: [
                (3, 7, "Maha Shivratri"),
                (3, 22, "Holi"),
                (3, 26, "Good Friday"),
                (4, 9, "Eid-ul-Fitr"),
                (8, 17, "Raksha Bandhan"),
                (8, 25, "Janmashtami (Smarta)"),
                (9, 5, "Ganesh Chaturthi"),
                (10, 10, "Dussehra (Vijayadashami)"),
                (10, 29, "Diwali (Deepavali)"),
                (10, 31, "Bhai Dooj"),
                (11, 14, "Guru Nanak Jayanti")
            ],
            2028: [
                (2, 24, "Maha Shivratri"),
                (3, 11, "Holi"),
                (4, 14, "Good Friday"),
                (8, 5, "Raksha Bandhan"),
                (8, 13, "Janmashtami (Smarta)"),
                (8, 24, "Ganesh Chaturthi"),
                (10, 18, "Diwali (Deepavali)"),
                (11, 2, "Guru Nanak Jayanti")
            ]
        ]
        
        let festivals = movableTableByYear[year] ?? [
            // Fallback general dates if queried far into the future/past
            (3, 15, "Holi"),
            (8, 25, "Janmashtami (Smarta)"),
            (9, 10, "Ganesh Chaturthi"),
            (10, 20, "Dussehra"),
            (11, 8, "Diwali (Deepavali)")
        ]
        
        for f in festivals {
            let d = makeDate(year: year, month: f.month, day: f.day)
            items.append(CalendarEvent(
                id: UUID(),
                title: f.name,
                startDate: d,
                endDate: d,
                isAllDay: true,
                calendarId: "holidays_india",
                colorHex: emeraldGreen,
                location: "India"
            ))
        }
        
        return items
    }
}
