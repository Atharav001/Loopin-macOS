import SwiftUI

public struct YearCalendarGrid: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    var year: Int
    var onSelectMonth: (Date) -> Void
    var onSelectDay: (Date) -> Void
    
    private let cal = Calendar.current
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public init(
        year: Int,
        onSelectMonth: @escaping (Date) -> Void,
        onSelectDay: @escaping (Date) -> Void
    ) {
        self.year = year
        self.onSelectMonth = onSelectMonth
        self.onSelectDay = onSelectDay
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            let visibleEvents = calendarManager.allVisibleEvents(forYear: year)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(1...12, id: \.self) { month in
                    YearMonthCard(
                        year: year,
                        month: month,
                        events: visibleEvents,
                        onMonthTapped: { date in
                            onSelectMonth(date)
                        },
                        onDayTapped: { date in
                            onSelectDay(date)
                        }
                    )
                }
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
    }
}

// MARK: - YearMonthCard
public struct YearMonthCard: View {
    var year: Int
    var month: Int
    var events: [CalendarEvent]
    var onMonthTapped: (Date) -> Void
    var onDayTapped: (Date) -> Void
    
    private var cal: Calendar { Calendar.current }
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var monthDate: Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        return cal.date(from: c) ?? Date()
    }
    
    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: monthDate)
    }
    
    private var daysInMonthGrid: [Date] {
        guard let monthInterval = cal.dateInterval(of: .month, for: monthDate) else { return [] }
        let start = monthInterval.start
        let weekday = cal.component(.weekday, from: start)
        let daysToPrepend = weekday - 1
        let firstDay = cal.date(byAdding: .day, value: -daysToPrepend, to: start) ?? start
        return (0..<35).compactMap { cal.date(byAdding: .day, value: $0, to: firstDay) }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month Title Header
            Button(action: {
                onMonthTapped(monthDate)
            }) {
                HStack {
                    Text(monthName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .buttonStyle(.plain)
            
            // Weekday Initials Row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(weekdaySymbols[idx])
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = daysInMonthGrid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { day in
                    let isCurrentMonth = cal.isDate(day, equalTo: monthDate, toGranularity: .month)
                    let isToday = cal.isDateInToday(day)
                    let hasEvents = dayHasEvents(day)
                    
                    Button(action: {
                        onDayTapped(day)
                    }) {
                        VStack(spacing: 1) {
                            Text("\(cal.component(.day, from: day))")
                                .font(.system(size: 9.5, weight: isToday ? .bold : .regular))
                                .foregroundColor(
                                    isToday ? Theme.accent : (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.25))
                                )
                                .frame(width: 18, height: 18)
                                .background(
                                    isToday ? Circle().stroke(Theme.accent, lineWidth: 1.2) : nil
                                )
                            
                            // Event indicator dot
                            Circle()
                                .fill(hasEvents && isCurrentMonth ? Theme.productive : Color.clear)
                                .frame(width: 3, height: 3)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func dayHasEvents(_ day: Date) -> Bool {
        let dayStart = cal.startOfDay(for: day)
        return events.contains { event in
            let s = cal.startOfDay(for: event.startDate)
            let e = cal.startOfDay(for: event.endDate)
            return dayStart >= s && dayStart <= e
        }
    }
}
