import SwiftUI

public struct DayColumnView: View {
    public let date: Date
    public let entries: [TimesheetEntry]
    public let hourHeight: CGFloat
    public let isToday: Bool
    
    public var onSelectEntry: ((TimesheetEntry) -> Void)?
    public var onCreateRange: ((Date, Date) -> Void)?
    public var onUpdateEntryTime: ((TimesheetEntry, Date, Date) -> Void)?
    
    @State private var dragSelection: (start: CGFloat, current: CGFloat)?
    @State private var resizingEntry: (entry: TimesheetEntry, isTop: Bool, originalY: CGFloat)?
    
    private let totalHours: Int = 24
    
    public init(
        date: Date,
        entries: [TimesheetEntry],
        hourHeight: CGFloat = 48,
        isToday: Bool = false,
        onSelectEntry: ((TimesheetEntry) -> Void)? = nil,
        onCreateRange: ((Date, Date) -> Void)? = nil,
        onUpdateEntryTime: ((TimesheetEntry, Date, Date) -> Void)? = nil
    ) {
        self.date = date
        self.entries = entries
        self.hourHeight = hourHeight
        self.isToday = isToday
        self.onSelectEntry = onSelectEntry
        self.onCreateRange = onCreateRange
        self.onUpdateEntryTime = onUpdateEntryTime
    }
    
    private var columnHeight: CGFloat {
        CGFloat(totalHours) * hourHeight
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Background Grid Lines
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
            .frame(height: columnHeight)
            .background(isToday ? Theme.accent.opacity(0.02) : Color.clear)
            
            // Rendered Entry Blocks
            ForEach(entries) { entry in
                let (yOffset, _) = computeYPosition(for: entry)
                EntryBlockView(
                    entry: entry,
                    hourHeight: hourHeight,
                    onSelect: { selected in
                        onSelectEntry?(selected)
                    }
                )
                .offset(y: yOffset)
                .padding(.horizontal, 2)
            }
            
            // Live Drag-to-Create Selection Rectangle
            if let drag = dragSelection {
                let topY = min(drag.start, drag.current)
                let height = max(16, abs(drag.current - drag.start))
                let snapped = snapYTo15Min(topY)
                let snappedH = max(hourHeight * 0.25, snapYTo15Min(height))
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.accent.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.accentLight, lineWidth: 1.5)
                    )
                    .overlay(
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New Task")
                                .font(Theme.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(formatTimeRange(startY: snapped, height: snappedH))
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.accentLight)
                        }
                        .padding(6),
                        alignment: .topLeading
                    )
                    .frame(height: snappedH)
                    .offset(y: snapped)
                    .padding(.horizontal, 2)
                    .animation(.none, value: drag.current)
            }
            
            // Live Red "Now" Line on Today's Column
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
                    .offset(y: nowY - 3)
                    .shadow(color: Theme.nowLine.opacity(0.8), radius: 4)
                }
            }
            
            // AppKit Mouse Drag Interceptor Layer
            GridInteractionView(
                onDragBegan: { point in
                    let snappedY = snapYTo15Min(point.y)
                    dragSelection = (start: snappedY, current: snappedY)
                },
                onDragChanged: { start, current in
                    let snappedCurrent = snapYTo15Min(current.y)
                    dragSelection = (start: start.y, current: snappedCurrent)
                },
                onDragEnded: { start, end in
                    let topY = min(start.y, end.y)
                    let bottomY = max(start.y, end.y)
                    let startDate = dateFromY(topY)
                    var endDate = dateFromY(bottomY)
                    
                    if endDate <= startDate {
                        endDate = Calendar.current.date(byAdding: .minute, value: 30, to: startDate) ?? startDate.addingTimeInterval(1800)
                    }
                    
                    dragSelection = nil
                    onCreateRange?(startDate, endDate)
                },
                onSingleClick: { point in
                    let startDate = dateFromY(point.y)
                    let endDate = Calendar.current.date(byAdding: .minute, value: 30, to: startDate) ?? startDate.addingTimeInterval(1800)
                    onCreateRange?(startDate, endDate)
                }
            )
            .opacity(0.01) // Transparent mouse receiver
        }
        .frame(minWidth: 140)
        .frame(height: columnHeight)
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
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
    
    private func computeCurrentTimeY() -> CGFloat {
        let cal = Calendar.current
        let now = Date()
        let hour = CGFloat(cal.component(.hour, from: now))
        let min = CGFloat(cal.component(.minute, from: now))
        return (hour + min / 60.0) * hourHeight
    }
}
