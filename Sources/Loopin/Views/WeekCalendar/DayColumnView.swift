import SwiftUI

public struct DayColumnView: View {
    public let date: Date
    public let entries: [TimesheetEntry]
    public let hourHeight: CGFloat
    public let columnWidth: CGFloat
    public let isToday: Bool
    public let use24HourClock: Bool
    public let hours: [Int]
    
    public var onSelectEntry: ((TimesheetEntry) -> Void)?
    public var onCreateRange: ((Date, Date) -> Void)?
    public var onUpdateEntryTime: ((TimesheetEntry, Date, Date) -> Void)?
    
    @State private var dragSelection: (start: CGFloat, current: CGFloat)?
    
    private var totalHours: Int {
        max(1, hours.count)
    }
    
    public init(
        date: Date,
        entries: [TimesheetEntry],
        hourHeight: CGFloat = 48,
        columnWidth: CGFloat = 140,
        isToday: Bool = false,
        use24HourClock: Bool = false,
        hours: [Int] = Array(0..<24),
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
        self.hours = hours.isEmpty ? Array(0..<24) : hours
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
            
            // 3. Rendered Entry Blocks (Side-by-side alignment when multiple tasks overlap)
            ForEach(computePositionedEntries()) { item in
                let totalCols = CGFloat(item.totalCols)
                let gap: CGFloat = totalCols > 1 ? 2.0 : 0.0
                let totalGaps = (totalCols - 1) * gap
                let availableW = max(24, columnWidth - 4 - totalGaps)
                let blockW = max(20, availableW / totalCols)
                let xOffset = 2 + CGFloat(item.colIndex) * (blockW + gap)
                
                EntryBlockView(
                    entry: item.entry,
                    hourHeight: hourHeight,
                    use24HourClock: use24HourClock,
                    onSelect: { selected in
                        onSelectEntry?(selected)
                    }
                )
                .frame(width: blockW, height: item.height)
                .offset(x: xOffset, y: item.y)
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
    
    // MARK: - Side-by-Side Overlapping Events Algorithm
    public struct PositionedCalendarEntry: Identifiable, Sendable {
        public let id: String
        public let entry: TimesheetEntry
        public let colIndex: Int
        public let totalCols: Int
        public let y: CGFloat
        public let height: CGFloat
    }
    
    public func computePositionedEntries() -> [PositionedCalendarEntry] {
        guard !entries.isEmpty else { return [] }
        
        let cal = Calendar.current
        let visibleEntries: [TimesheetEntry]
        if hours.count < 24 {
            visibleEntries = entries.filter { entry in
                let startH = cal.component(.hour, from: entry.startAt)
                let endH = cal.component(.hour, from: entry.endAt)
                return hours.contains(startH) || hours.contains(endH)
            }
        } else {
            visibleEntries = entries
        }
        
        guard !visibleEntries.isEmpty else { return [] }
        
        let sorted = visibleEntries.sorted { a, b in
            if a.startAt != b.startAt {
                return a.startAt < b.startAt
            }
            return a.duration > b.duration
        }
        
        struct RawBounds {
            let entry: TimesheetEntry
            let y: CGFloat
            let height: CGFloat
            var bottom: CGFloat { y + height }
        }
        
        let rawList = sorted.map { entry -> RawBounds in
            let (y, h) = computeYPosition(for: entry)
            return RawBounds(entry: entry, y: y, height: h)
        }
        
        // Group into overlapping clusters
        var clusters: [[RawBounds]] = []
        var currentCluster: [RawBounds] = []
        var clusterMaxBottom: CGFloat = 0
        
        for item in rawList {
            if currentCluster.isEmpty {
                currentCluster.append(item)
                clusterMaxBottom = item.bottom
            } else {
                if item.y < clusterMaxBottom - 0.5 {
                    currentCluster.append(item)
                    clusterMaxBottom = max(clusterMaxBottom, item.bottom)
                } else {
                    clusters.append(currentCluster)
                    currentCluster = [item]
                    clusterMaxBottom = item.bottom
                }
            }
        }
        if !currentCluster.isEmpty {
            clusters.append(currentCluster)
        }
        
        var result: [PositionedCalendarEntry] = []
        
        for cluster in clusters {
            var columnBottoms: [CGFloat] = []
            var placements: [(RawBounds, Int)] = []
            
            for item in cluster {
                var assignedCol = -1
                for c in 0..<columnBottoms.count {
                    if columnBottoms[c] <= item.y + 0.5 {
                        assignedCol = c
                        columnBottoms[c] = item.bottom
                        break
                    }
                }
                if assignedCol == -1 {
                    assignedCol = columnBottoms.count
                    columnBottoms.append(item.bottom)
                }
                placements.append((item, assignedCol))
            }
            
            let totalColumnsInCluster = max(1, columnBottoms.count)
            for (item, col) in placements {
                result.append(PositionedCalendarEntry(
                    id: item.entry.id,
                    entry: item.entry,
                    colIndex: col,
                    totalCols: totalColumnsInCluster,
                    y: item.y,
                    height: item.height
                ))
            }
        }
        
        return result
    }
    
    private func computeYPosition(for entry: TimesheetEntry) -> (y: CGFloat, height: CGFloat) {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: entry.startAt)
        let min = CGFloat(cal.component(.minute, from: entry.startAt))
        
        let baseIndex: CGFloat
        if let idx = hours.firstIndex(of: hour) {
            baseIndex = CGFloat(idx)
        } else {
            if let first = hours.first, hour < first {
                baseIndex = 0
            } else if let last = hours.last, hour > last {
                baseIndex = CGFloat(hours.count)
            } else {
                baseIndex = 0
            }
        }
        
        let y = (baseIndex + min / 60.0) * hourHeight
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
        let hourIdx = max(0, min(hours.count - 1, Int(y / hourHeight)))
        let targetHour = hours[hourIdx]
        
        let fraction = max(0.0, min(0.99, (y.truncatingRemainder(dividingBy: hourHeight)) / hourHeight))
        let snappedMinutes = Int(round(fraction * 4.0)) * 15
        let clampedMin = max(0, min(59, snappedMinutes))
        
        return cal.date(bySettingHour: targetHour, minute: clampedMin, second: 0, of: startOfDay) ?? date
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
        let hour = cal.component(.hour, from: now)
        let min = CGFloat(cal.component(.minute, from: now))
        guard let idx = hours.firstIndex(of: hour) else {
            return -100 // hidden when current time is outside visible hours
        }
        return (CGFloat(idx) + min / 60.0) * hourHeight
    }
}
