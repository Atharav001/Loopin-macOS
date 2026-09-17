import SwiftUI

public struct MonthCalendarGrid: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    var monthDate: Date
    var onSelectEvent: (CalendarEvent) -> Void
    var onSelectRange: (Date, Date) -> Void
    
    // Drag selection state
    @State private var dragStartDay: Date?
    @State private var dragCurrentDay: Date?
    @State private var isDraggingRange: Bool = false
    
    public init(
        monthDate: Date,
        onSelectEvent: @escaping (CalendarEvent) -> Void,
        onSelectRange: @escaping (Date, Date) -> Void
    ) {
        self.monthDate = monthDate
        self.onSelectEvent = onSelectEvent
        self.onSelectRange = onSelectRange
    }
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = appState.weekStartsOnMonday ? 2 : 1
        return cal
    }
    
    private var weekdaySymbols: [String] {
        if appState.weekStartsOnMonday {
            return ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        } else {
            return ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        }
    }
    
    // Dynamic month grid metrics (precisely calculates 5 or 6 full weeks without truncating days)
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
            let headerHeight: CGFloat = 32
            
            let metrics = gridMetrics
            let days = metrics.days
            let rowCount = metrics.rowCount
            let rowHeight = floor((totalHeight - headerHeight) / CGFloat(rowCount))
            
            VStack(spacing: 0) {
                // 1. Weekday Column Headers
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        Text(weekdaySymbols[col])
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.6)
                            .frame(width: colWidth, height: headerHeight)
                    }
                }
                .background(Theme.bgDark.opacity(0.5))
                .overlay(
                    Rectangle()
                        .fill(Theme.border)
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
                            Divider().background(Theme.border)
                        }
                    }
                }
            }
            .coordinateSpace(name: "MonthGridSpace")
        }
        .background(Theme.bgDeep)
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
        
        return allEvents.filter { event in
            let eventStartDay = cal.startOfDay(for: event.startDate)
            let eventEndDay = cal.startOfDay(for: event.endDate)
            return targetDayStart >= eventStartDay && targetDayStart <= eventEndDay
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
                        ? Theme.accent.opacity(0.18)
                        : (isHovered ? Theme.bgSubtle : Theme.bgDeep)
                )
            
            // Vertical Right Border
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 3) {
                // Day Number Pill / Header
                HStack {
                    if isToday {
                        Text(dayLabel)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                    } else {
                        Text(dayLabel)
                            .font(.system(size: 11, weight: dayNumber == 1 ? .bold : .medium))
                            .foregroundColor(isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.35))
                            .padding(.leading, 6)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                
                // Event Bars Container
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(events.prefix(3)) { event in
                        EventPillView(
                            event: event,
                            date: date,
                            onTap: { onSelectEvent(event) }
                        )
                    }
                    
                    if events.count > 3 {
                        Text("+\(events.count - 3) more")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .padding(.leading, 6)
                            .padding(.top, 1)
                    }
                }
                
                Spacer()
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

// MARK: - EventPillView
public struct EventPillView: View {
    var event: CalendarEvent
    var date: Date
    var onTap: () -> Void
    
    private var cal: Calendar { Calendar.current }
    private var isStart: Bool { cal.isDate(event.startDate, inSameDayAs: date) }
    private var isEnd: Bool { cal.isDate(event.endDate, inSameDayAs: date) }
    private var isMultiDay: Bool { event.isMultiDay }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isStart || !isMultiDay {
                    Text(event.title)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(Color.white)
                } else {
                    Text(event.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .opacity(0.85)
                        .foregroundColor(Color.white)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(height: 19)
            .background(event.color)
            .clipShape(
                RoundedCornerShape(
                    topLeft: isStart || !isMultiDay ? 4 : 0,
                    bottomLeft: isStart || !isMultiDay ? 4 : 0,
                    bottomRight: isEnd || !isMultiDay ? 4 : 0,
                    topRight: isEnd || !isMultiDay ? 4 : 0
                )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1, y: 0.5)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
    }
}

// MARK: - RoundedCornerShape for Multi-day Banners
public struct RoundedCornerShape: Shape {
    var topLeft: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0
    var topRight: CGFloat = 0

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height

        let tr = min(min(self.topRight, h/2), w/2)
        let tl = min(min(self.topLeft, h/2), w/2)
        let bl = min(min(self.bottomLeft, h/2), w/2)
        let br = min(min(self.bottomRight, h/2), w/2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}
