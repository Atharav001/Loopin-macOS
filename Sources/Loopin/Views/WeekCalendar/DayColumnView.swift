import SwiftUI

public struct DayColumnView: View {
    public let date: Date
    public let entries: [TimesheetEntry]
    public let hourHeight: CGFloat
    public let columnWidth: CGFloat
    public let isToday: Bool
    public let use24HourClock: Bool
    
    public var onSelectEntry: ((TimesheetEntry) -> Void)?
    public var onCreateRange: ((Date, Date) -> Void)?
    public var onUpdateEntryTime: ((TimesheetEntry, Date, Date) -> Void)?
    
    @State private var dragSelection: (start: CGFloat, current: CGFloat)?
    
    private let totalHours: Int = 24
    
    public init(
        date: Date,
        entries: [TimesheetEntry],
        hourHeight: CGFloat = 48,
        columnWidth: CGFloat = 140,
        isToday: Bool = false,
        use24HourClock: Bool = false,
        onSelectEntry: ((TimesheetEntry) -> Void)? = nil,
        onCreateRange: ((Date, Date) -> Void)? = nil,
        onUpdateEntryTime: ((TimesheetEntry, Date, Date) -> Void)? = nil
    ) {
        self.date = date
        self.entries = entries
        self.hourHeight = hourHeight
        self.columnWidth = columnWidth
        self.isToday = isToday
        self.use24HourClock = use24HourClock
        self.onSelectEntry = onSelectEntry
        self.onCreateRange = onCreateRange
        self.onUpdateEntryTime = onUpdateEntryTime
    }
    
    private var columnHeight: CGFloat {
        CGFloat(totalHours) * hourHeight
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Background Grid Lines
            VStack(spacing: 0) {
                ForEach(0..<totalHours, id: \.self) { _ in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Theme.borderSubtle)
                            .frame(height: 1)
                        Spacer()
                        // 30-min dashed subdivider
                        Rectangle()
                            .fill(Theme.borderSubtle.opacity(0.5))
                            .frame(height: 0.5)
                        Spacer()
                    }
                    .frame(height: hourHeight)
                }
            }
            .frame(width: columnWidth, height: columnHeight)
            .background(isToday ? Theme.accent.opacity(0.03) : Color.clear)
            
            // 2. Native Click & Drag Gesture Hit Area
            Color.clear
                .frame(width: columnWidth, height: columnHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let startY = snapYTo15Min(value.startLocation.y)
                            let currentY = snapYTo15Min(value.location.y)
                            dragSelection = (start: startY, current: currentY)
                        }
                        .onEnded { value in
                            let topY = min(value.startLocation.y, value.location.y)
                            let bottomY = max(value.startLocation.y, value.location.y)
                            let snappedTop = snapYTo15Min(topY)
                            let snappedBottom = snapYTo15Min(bottomY)
                            
                            let startDate = dateFromY(snappedTop)
                            var endDate = dateFromY(snappedBottom)
                            
                            // If clicked without dragging (or dragged less than 15 mins), create a 30-minute block
                            if endDate <= startDate || abs(bottomY - topY) < 12 {
                                endDate = Calendar.current.date(byAdding: .minute, value: 30, to: startDate) ?? startDate.addingTimeInterval(1800)
                            }
                            
                            dragSelection = nil
                            onCreateRange?(startDate, endDate)
                        }
                )
            
            // 3. Rendered Entry Blocks
            ForEach(entries) { entry in
                let (yOffset, h) = computeYPosition(for: entry)
                EntryBlockView(
                    entry: entry,
                    hourHeight: hourHeight,
                    use24HourClock: use24HourClock,
                    onSelect: { selected in
                        onSelectEntry?(selected)
                    }
                )
                .frame(width: max(40, columnWidth - 4), height: h)
                .offset(x: 2, y: yOffset)
            }
            
            // 4. Clockify Live Drag-to-Create Selection Block
            if let drag = dragSelection {
                let topY = min(drag.start, drag.current)
                let height = max(16, abs(drag.current - drag.start))
                let snapped = snapYTo15Min(topY)
                let snappedH = max(hourHeight * 0.25, snapYTo15Min(height))
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.bgCard.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.accent, lineWidth: 1.5)
                    )
                    .overlay(
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.accent)
                                .frame(width: 4)
                                .padding(.vertical, 3)
                                .padding(.leading, 3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("New Time Entry")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer(minLength: 0)
                                    
                                    Text(formatDuration(startY: snapped, height: snappedH))
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.accentLight)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Theme.accent.opacity(0.2))
                                        .cornerRadius(3)
                                }
                                
                                Text(formatTimeRange(startY: snapped, height: snappedH))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                        },
                        alignment: .topLeading
                    )
                    .frame(width: max(40, columnWidth - 4), height: snappedH)
                    .offset(x: 2, y: snapped)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 6)
                    .allowsHitTesting(false)
            }
            
            // 5. Live Red "Now" Line on Today's Column
            if isToday {
                let nowY = computeCurrentTimeY()
                if nowY >= 0 && nowY <= columnHeight {
                    HStack(spacing: 0) {
                        Circle()
                            .fill(Theme.nowLine)
                            .frame(width: 6, height: 6)
                        Rectangle()
                            .fill(Theme.nowLine)
                            .frame(height: 2)
                    }
                    .frame(width: columnWidth)
                    .offset(y: nowY - 3)
                    .shadow(color: Theme.nowLine.opacity(0.8), radius: 4)
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(width: columnWidth, height: columnHeight)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func computeYPosition(for entry: TimesheetEntry) -> (y: CGFloat, height: CGFloat) {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: entry.startAt))
        let min = CGFloat(cal.component(.minute, from: entry.startAt))
        let y = (hour + min / 60.0) * hourHeight
        let height = (CGFloat(entry.durationMinutes) / 60.0) * hourHeight
        return (y, max(20, height))
    }
    
    private func snapYTo15Min(_ y: CGFloat) -> CGFloat {
        let totalMinutes = (y / hourHeight) * 60.0
        let snappedMinutes = round(totalMinutes / 15.0) * 15.0
        return (snappedMinutes / 60.0) * hourHeight
    }
    
    private func dateFromY(_ y: CGFloat) -> Date {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let totalMinutes = Int(round((y / hourHeight) * 60.0 / 15.0) * 15.0)
        let clampedMinutes = max(0, min(24 * 60 - 15, totalMinutes))
        return cal.date(byAdding: .minute, value: clampedMinutes, to: startOfDay) ?? date
    }
    
    private func formatTimeRange(startY: CGFloat, height: CGFloat) -> String {
        let start = dateFromY(startY)
        let end = dateFromY(startY + height)
        let formatter = DateFormatter()
        formatter.dateFormat = use24HourClock ? "HH:mm" : "h:mm a"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    private func formatDuration(startY: CGFloat, height: CGFloat) -> String {
        let start = dateFromY(startY)
        let end = dateFromY(startY + height)
        let totalMins = max(15, Int(end.timeIntervalSince(start) / 60))
        let hrs = totalMins / 60
        let mins = totalMins % 60
        if hrs > 0 && mins > 0 {
            return "\(hrs)h \(mins)m"
        } else if hrs > 0 {
            return "\(hrs)h"
        } else {
            return "\(mins)m"
        }
    }
    
    private func computeCurrentTimeY() -> CGFloat {
        let cal = Calendar.current
        let now = Date()
        let hour = CGFloat(cal.component(.hour, from: now))
        let min = CGFloat(cal.component(.minute, from: now))
        return (hour + min / 60.0) * hourHeight
    }
}
