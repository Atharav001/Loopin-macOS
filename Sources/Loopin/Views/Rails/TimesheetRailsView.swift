import SwiftUI

public struct TimesheetRailsView: View {
    public var entries: [TimesheetEntry]
    public var onSelectEntry: ((TimesheetEntry) -> Void)?
    
    @State private var hoveredEntry: TimesheetEntry?
    @State private var currentTime = Date()
    @State private var timerCancellable: Timer?
    
    private let hourWidth: CGFloat = 64
    private let railHeight: CGFloat = 38
    private let totalHours: Int = 24
    
    public init(entries: [TimesheetEntry], onSelectEntry: ((TimesheetEntry) -> Void)? = nil) {
        self.entries = entries
        self.onSelectEntry = onSelectEntry
    }
    
    private var totalWidth: CGFloat {
        CGFloat(totalHours) * hourWidth
    }
    
    private var plannedEntries: [TimesheetEntry] {
        entries.filter { $0.kind == EntryKind.planned.rawValue }
    }
    
    private var loggedEntries: [TimesheetEntry] {
        entries.filter { $0.kind == EntryKind.logged.rawValue }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with legend
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "timeline.selection")
                        .foregroundColor(Theme.accentLight)
                    Text("Today's Timesheet Rails")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                // Color Legend
                HStack(spacing: 12) {
                    legendItem(label: "Productive", color: Theme.productive)
                    legendItem(label: "Non-Productive", color: Theme.wasteful)
                    legendItem(label: "Planned", color: Theme.planned)
                    legendItem(label: "Skipped", color: Theme.skipped)
                }
            }
            
            // Rails container inside horizontal scroll view
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Time Ruler (Hours 00:00 to 24:00)
                    HStack(spacing: 0) {
                        ForEach(0..<totalHours, id: \.self) { hour in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%02d:00", hour))
                                    .font(Theme.caption)
                                    .foregroundColor(Theme.textMuted)
                                Rectangle()
                                    .fill(Theme.border)
                                    .frame(width: 1, height: 6)
                            }
                            .frame(width: hourWidth, alignment: .leading)
                        }
                    }
                    .frame(height: 24)
                    
                    // Dual Rails area with Grid and "Now" line
                    ZStack(alignment: .topLeading) {
                        // Background Hour Grid Lines
                        HStack(spacing: 0) {
                            ForEach(0..<totalHours, id: \.self) { _ in
                                Rectangle()
                                    .fill(Theme.borderSubtle)
                                    .frame(width: 1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width: totalWidth, height: railHeight * 2 + 16)
                        
                        VStack(spacing: 8) {
                            // Rail 1: PLANNED
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppState.shared.currentTheme.isDark ? Theme.bgDark.opacity(0.6) : Color.black.opacity(0.035))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )
                                    .frame(width: totalWidth, height: railHeight)
                                
                                // Rail Label overlay on leading edge
                                Text("PLANNED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.planned.opacity(0.6))
                                    .padding(.leading, 8)
                                
                                // Planned Entry Blocks
                                ForEach(plannedEntries) { entry in
                                    railBlock(entry: entry, isPlanned: true)
                                }
                            }
                            .frame(width: totalWidth, height: railHeight)
                            
                            // Rail 2: LOGGED
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppState.shared.currentTheme.isDark ? Theme.bgDark.opacity(0.6) : Color.black.opacity(0.035))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )
                                    .frame(width: totalWidth, height: railHeight)
                                
                                // Rail Label overlay
                                Text("LOGGED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textMuted.opacity(0.6))
                                    .padding(.leading, 8)
                                
                                // Logged Entry Blocks
                                ForEach(loggedEntries) { entry in
                                    railBlock(entry: entry, isPlanned: false)
                                }
                            }
                            .frame(width: totalWidth, height: railHeight)
                        }
                        
                        // Live "Now" Line
                        let nowOffset = computeNowOffset()
                        if nowOffset >= 0 && nowOffset <= totalWidth {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Theme.nowLine)
                                    .frame(width: 8, height: 8)
                                Rectangle()
                                    .fill(Theme.nowLine)
                                    .frame(width: 2, height: railHeight * 2 + 10)
                            }
                            .offset(x: nowOffset - 4, y: -4)
                            .shadow(color: Theme.nowLine.opacity(0.6), radius: 4)
                        }
                    }
                    .frame(width: totalWidth)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
        .onAppear {
            currentTime = Date()
            timerCancellable = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                Task { @MainActor in
                    currentTime = Date()
                }
            }
        }
        .onDisappear {
            timerCancellable?.invalidate()
        }
    }
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }
    
    private func railBlock(entry: TimesheetEntry, isPlanned: Bool) -> some View {
        let (xOffset, blockWidth) = computePosition(entry: entry)
        let color = isPlanned ? Theme.planned : Color.forProductivity(entry.productivityType)
        let isHover = hoveredEntry?.id == entry.id
        
        return ZStack(alignment: .leading) {
            if isPlanned {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(color, style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                    .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.18)))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 1)
                    )
            }
            
            HStack(spacing: 4) {
                Text(entry.rawText)
                    .font(Theme.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Text(entry.formattedDuration)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(.horizontal, 6)
        }
        .frame(width: max(24, blockWidth), height: railHeight - 8)
        .offset(x: xOffset)
        .shadow(color: isHover ? color.opacity(0.5) : Color.clear, radius: 6)
        .scaleEffect(isHover ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredEntry = hovering ? entry : nil
            }
        }
        .onTapGesture {
            onSelectEntry?(entry)
        }
        .help("\(entry.rawText) (\(entry.formattedTimeRange)) • \(entry.category ?? "General")")
    }
    
    private func computePosition(entry: TimesheetEntry) -> (x: CGFloat, width: CGFloat) {
        let cal = Calendar.current
        let startHour = CGFloat(cal.component(.hour, from: entry.startAt))
        let startMin = CGFloat(cal.component(.minute, from: entry.startAt))
        let x = (startHour + startMin / 60.0) * hourWidth
        
        let durationMinutes = CGFloat(entry.durationMinutes)
        let width = (durationMinutes / 60.0) * hourWidth
        return (x, width)
    }
    
    private func computeNowOffset() -> CGFloat {
        let cal = Calendar.current
        let hour = CGFloat(cal.component(.hour, from: currentTime))
        let minute = CGFloat(cal.component(.minute, from: currentTime))
        return (hour + minute / 60.0) * hourWidth
    }
}
