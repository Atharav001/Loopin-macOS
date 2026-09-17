import SwiftUI
import AppKit

public struct MonthCalendarGrid: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    var monthDate: Date
    var onSelectEvent: (CalendarEvent) -> Void
    var onSelectRange: (Date, Date) -> Void
    var onScrollMonth: ((Int) -> Void)?
    
    // Drag selection state
    @State private var dragStartDay: Date?
    @State private var dragCurrentDay: Date?
    @State private var isDraggingRange: Bool = false
    
    public init(
        monthDate: Date,
        onSelectEvent: @escaping (CalendarEvent) -> Void,
        onSelectRange: @escaping (Date, Date) -> Void,
        onScrollMonth: ((Int) -> Void)? = nil
    ) {
        self.monthDate = monthDate
        self.onSelectEvent = onSelectEvent
        self.onSelectRange = onSelectRange
        self.onScrollMonth = onScrollMonth
    }
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = appState.weekStartsOnMonday ? 2 : 1
        return cal
    }
    
    private var weekdaySymbols: [String] {
        if appState.weekStartsOnMonday {
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        } else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
    }
    
    // Dynamic month grid metrics (completes week with preceding & succeeding days)
    private var gridMetrics: (days: [Date], rowCount: Int) {
        let cal = calendar
        guard let monthInterval = cal.dateInterval(of: .month, for: monthDate) else {
            return ([], 5)
        }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = cal.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end
        let firstWeekday = cal.firstWeekday
        let startWeekday = cal.component(.weekday, from: startOfMonth)
        let daysToPrepend = (startWeekday - firstWeekday + 7) % 7
        let firstCalendarDay = cal.date(byAdding: .day, value: -daysToPrepend, to: startOfMonth) ?? startOfMonth
        
        let endWeekday = cal.component(.weekday, from: endOfMonth)
        let daysToAppend = (firstWeekday - endWeekday + 6) % 7
        let lastCalendarDay = cal.date(byAdding: .day, value: daysToAppend, to: endOfMonth) ?? endOfMonth
        
        let dayCount = cal.dateComponents([.day], from: firstCalendarDay, to: lastCalendarDay).day! + 1
        let rows = max(5, (dayCount + 6) / 7)
        let totalCells = rows * 7
        
        let allDays = (0..<totalCells).compactMap { cal.date(byAdding: .day, value: $0, to: firstCalendarDay) }
        return (allDays, rows)
    }
    
    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let totalHeight = geo.size.height
            let colWidth = floor(totalWidth / 7.0)
            let headerHeight: CGFloat = 26
            
            let metrics = gridMetrics
            let days = metrics.days
            let rowCount = metrics.rowCount
            let rowHeight = floor((totalHeight - headerHeight) / CGFloat(rowCount))
            
            ZStack {
                // Trackpad / Mouse Scroll Listener for Month Flipping
                if let onScrollMonth = onScrollMonth {
                    MonthScrollWheelOverlay(onScroll: onScrollMonth)
                }
                
                VStack(spacing: 0) {
                    // 1. Weekday Column Headers (Right-aligned matching macOS Calendar)
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            Text(weekdaySymbols[col])
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color(white: 0.58))
                                .frame(width: colWidth, height: headerHeight, alignment: .trailing)
                                .padding(.trailing, 10)
                        }
                    }
                    .background(Color(red: 25/255, green: 26/255, blue: 28/255))
                    .overlay(
                        Rectangle()
                            .fill(Color(white: 0.17))
                            .frame(height: 1),
                        alignment: .bottom
                    )
                    
                    // 2. Month Grid Rows
                    let activeYear = calendar.component(.year, from: monthDate)
                    let visibleEvents = calendarManager.allVisibleEvents(forYear: activeYear)
                    
                    VStack(spacing: 0) {
                        ForEach(0..<rowCount, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { col in
                                    let index = row * 7 + col
                                    if index < days.count {
                                        let day = days[index]
                                        let isSelectedRange = isDayInDragRange(day)
                                        
                                        MonthDayCell(
                                            date: day,
                                            displayedMonth: monthDate,
                                            width: colWidth,
                                            height: rowHeight,
                                            events: eventsForDay(day, from: visibleEvents),
                                            isSelectedRange: isSelectedRange,
                                            onSelectEvent: onSelectEvent,
                                            onDayTapped: {
                                                onSelectRange(day, day)
                                            }
                                        )
                                        .frame(width: colWidth, height: rowHeight)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 4, coordinateSpace: .named("MonthGridSpace"))
                                                .onChanged { value in
                                                    handleDragChanged(
                                                        value: value,
                                                        colWidth: colWidth,
                                                        rowHeight: rowHeight,
                                                        headerHeight: headerHeight,
                                                        rowCount: rowCount,
                                                        days: days
                                                    )
                                                }
                                                .onEnded { _ in
                                                    handleDragEnded()
                                                }
                                        )
                                    }
                                }
                            }
                            
                            if row < rowCount - 1 {
                                Rectangle()
                                    .fill(Color(white: 0.17))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "MonthGridSpace")
        }
        .background(Color(red: 27/255, green: 28/255, blue: 30/255))
    }
    
    // MARK: - Drag Selection Logic
    private func handleDragChanged(value: DragGesture.Value, colWidth: CGFloat, rowHeight: CGFloat, headerHeight: CGFloat, rowCount: Int, days: [Date]) {
        if !isDraggingRange {
            isDraggingRange = true
            let startCol = Int(value.startLocation.x / colWidth)
            let startRow = Int((value.startLocation.y - headerHeight) / rowHeight)
            let startIndex = startRow * 7 + startCol
            if startIndex >= 0 && startIndex < days.count {
                dragStartDay = days[startIndex]
            }
        }
        
        let currentCol = max(0, min(6, Int(value.location.x / colWidth)))
        let currentRow = max(0, min(rowCount - 1, Int((value.location.y - headerHeight) / rowHeight)))
        let currentIndex = currentRow * 7 + currentCol
        if currentIndex >= 0 && currentIndex < days.count {
            dragCurrentDay = days[currentIndex]
        }
    }
    
    private func handleDragEnded() {
        if let start = dragStartDay, let end = dragCurrentDay {
            let actualStart = min(start, end)
            let actualEnd = max(start, end)
            onSelectRange(actualStart, actualEnd)
        }
        dragStartDay = nil
        dragCurrentDay = nil
        isDraggingRange = false
    }
    
    private func isDayInDragRange(_ day: Date) -> Bool {
        guard let start = dragStartDay, let current = dragCurrentDay else { return false }
        let cal = calendar
        let dayStart = cal.startOfDay(for: day)
        let rStart = cal.startOfDay(for: min(start, current))
        let rEnd = cal.startOfDay(for: max(start, current))
        return dayStart >= rStart && dayStart <= rEnd
    }
    
    private func eventsForDay(_ day: Date, from allEvents: [CalendarEvent]) -> [CalendarEvent] {
        let cal = calendar
        let targetDayStart = cal.startOfDay(for: day)
        
        let matched = allEvents.filter { event in
            let eventStartDay = cal.startOfDay(for: event.startDate)
            let eventEndDay = cal.startOfDay(for: event.endDate)
            return targetDayStart >= eventStartDay && targetDayStart <= eventEndDay
        }
        
        // Sort: All-day / holidays first, then timed events sorted by start time
        return matched.sorted { lhs, rhs in
            if lhs.isAllDay != rhs.isAllDay {
                return lhs.isAllDay && !rhs.isAllDay
            }
            return lhs.startDate < rhs.startDate
        }
    }
}

// MARK: - MonthDayCell
public struct MonthDayCell: View {
    @ObservedObject var appState: AppState = .shared
    
    var date: Date
    var displayedMonth: Date
    var width: CGFloat
    var height: CGFloat
    var events: [CalendarEvent]
    var isSelectedRange: Bool
    var onSelectEvent: (CalendarEvent) -> Void
    var onDayTapped: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var cal: Calendar { Calendar.current }
    private var isToday: Bool { cal.isDateInToday(date) }
    private var isCurrentMonth: Bool { cal.isDate(date, equalTo: displayedMonth, toGranularity: .month) }
    private var dayNumber: Int { cal.component(.day, from: date) }
    
    private var dayLabel: String {
        if dayNumber == 1 {
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            return f.string(from: date)
        }
        return "\(dayNumber)"
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background Canvas
            Rectangle()
                .fill(
                    isSelectedRange
                        ? Color.blue.opacity(0.18)
                        : (isHovered
                           ? Color(white: 0.15)
                           : (isCurrentMonth ? Color(red: 27/255, green: 28/255, blue: 30/255) : Color(red: 23/255, green: 24/255, blue: 25/255)))
                )
            
            // Vertical Right Grid Line
            Rectangle()
                .fill(Color(white: 0.17))
                .frame(width: 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            VStack(spacing: 2) {
                // Day Number at TOP RIGHT matching macOS Calendar
                HStack {
                    Spacer()
                    if isToday {
                        // Red circular badge with bold white text
                        ZStack {
                            Circle()
                                .fill(Color(red: 232/255, green: 38/255, blue: 38/255))
                                .frame(width: 20, height: 20)
                            
                            Text("\(dayNumber)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                        .padding(.trailing, 6)
                    } else {
                        Text(dayLabel)
                            .font(.system(size: 11, weight: dayNumber == 1 ? .semibold : .regular))
                            .foregroundColor(
                                isCurrentMonth
                                    ? Color(white: 0.82)
                                    : Color(white: 0.38)
                            )
                            .padding(.top, 4)
                            .padding(.trailing, 8)
                    }
                }
                
                // Events Container
                VStack(spacing: 1.5) {
                    ForEach(events.prefix(4)) { event in
                        if event.isAllDay || event.calendarId == "holidays_india" {
                            // All-Day / Holiday Pill Banner
                            HolidayPillView(event: event, isDimmed: !isCurrentMonth) {
                                onSelectEvent(event)
                            }
                        } else {
                            // Timed Event / Task Row with vertical color bar
                            TimedEventRowView(event: event, isDimmed: !isCurrentMonth) {
                                onSelectEvent(event)
                            }
                        }
                    }
                    
                    if events.count > 4 {
                        HStack {
                            Text("+\(events.count - 4) more")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(isCurrentMonth ? Color(white: 0.6) : Color(white: 0.35))
                            Spacer()
                        }
                        .padding(.leading, 6)
                        .padding(.top, 1)
                    }
                }
                .padding(.horizontal, 2)
                
                Spacer(minLength: 0)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onDayTapped()
        }
    }
}

// MARK: - HolidayPillView (Full Width Pill matching screenshot)
public struct HolidayPillView: View {
    var event: CalendarEvent
    var isDimmed: Bool = false
    var onTap: () -> Void
    
    private var holidayStyle: (bg: Color, text: Color, iconName: String, iconColor: Color) {
        let lower = event.title.lowercased()
        
        if lower.contains("labor") || lower.contains("labour") {
            // Wine Red Labor Day Pill
            return (
                bg: Color(red: 88/255, green: 32/255, blue: 38/255),
                text: Color(red: 254/255, green: 205/255, blue: 211/255),
                iconName: "calendar",
                iconColor: Color(red: 239/255, green: 68/255, blue: 68/255)
            )
        } else if lower.contains("star") || lower.contains("chaturthi") && event.notes?.contains("star") == true {
            // Warm Amber / Orange with Star
            return (
                bg: Color(red: 84/255, green: 56/255, blue: 26/255),
                text: Color(red: 254/255, green: 240/255, blue: 180/255),
                iconName: "star.fill",
                iconColor: Color(red: 245/255, green: 158/255, blue: 11/255)
            )
        } else if lower.contains("gandhi") || lower.contains("janmashtami") || lower.contains("ganesh") {
            // Muted Teal / Sage Festival Pill
            return (
                bg: Color(red: 44/255, green: 71/255, blue: 64/255),
                text: Color(red: 204/255, green: 251/255, blue: 241/255),
                iconName: "calendar",
                iconColor: Color(red: 52/255, green: 211/255, blue: 153/255)
            )
        } else {
            // Default elegant dark pill
            return (
                bg: Color(red: 38/255, green: 42/255, blue: 48/255),
                text: Color(white: 0.9),
                iconName: "calendar",
                iconColor: event.color
            )
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 3.5) {
                // Left small icon
                Image(systemName: holidayStyle.iconName)
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(holidayStyle.iconColor.opacity(isDimmed ? 0.5 : 1.0))
                
                Text(event.title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(holidayStyle.text.opacity(isDimmed ? 0.5 : 1.0))
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 5)
            .frame(height: 17)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(holidayStyle.bg.opacity(isDimmed ? 0.45 : 1.0))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
    }
}

// MARK: - TimedEventRowView (Vertical accent strip + title + time on right)
public struct TimedEventRowView: View {
    var event: CalendarEvent
    var isDimmed: Bool = false
    var onTap: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var timeFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: event.startDate)
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                // Vertical accent bar (Yellow, Purple, etc.)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(event.color.opacity(isDimmed ? 0.5 : 1.0))
                    .frame(width: 3.5, height: 11)
                
                // Event Title
                Text(event.title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(Color(white: isDimmed ? 0.5 : 0.92))
                
                Spacer(minLength: 2)
                
                // Event Time on Right (e.g. "9 AM", "10 AM")
                Text(timeFormatted)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(Color(white: isDimmed ? 0.35 : 0.55))
                    .lineLimit(1)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .frame(height: 16)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - MonthScrollWheelOverlay
struct MonthScrollWheelOverlay: NSViewRepresentable {
    var onScroll: (Int) -> Void
    
    func makeNSView(context: Context) -> ScrollWheelNSView {
        let v = ScrollWheelNSView()
        v.onScroll = onScroll
        return v
    }
    
    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.onScroll = onScroll
    }
    
    class ScrollWheelNSView: NSView {
        var onScroll: ((Int) -> Void)?
        private var lastScrollTime: TimeInterval = 0
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
        
        override func scrollWheel(with event: NSEvent) {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastScrollTime > 0.25 else { return }
            
            if event.scrollingDeltaY < -6 || event.deltaY < -0.8 {
                lastScrollTime = now
                onScroll?(1)
            } else if event.scrollingDeltaY > 6 || event.deltaY > 0.8 {
                lastScrollTime = now
                onScroll?(-1)
            }
        }
    }
}
