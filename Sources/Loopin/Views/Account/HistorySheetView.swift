import SwiftUI

// MARK: - HistoryRange
public enum HistoryRange: String, CaseIterable, Identifiable {
    case today = "TODAY"
    case sevenDays = "7 DAYS"
    case thirtyDays = "30 DAYS"
    case custom = "CUSTOM"
    
    public var id: String { rawValue }
}

// MARK: - HistorySheetView (Tocklog Activity & History Style)
public struct HistorySheetView: View {
    var onClose: () -> Void
    
    @State private var selectedRange: HistoryRange = .sevenDays
    @State private var entries: [TimesheetEntry] = []
    @State private var selectedEntryForEdit: TimesheetEntry? = nil
    @State private var isShowingEditor: Bool = false
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    private var filteredEntries: [TimesheetEntry] {
        let cal = Calendar.current
        let now = Date()
        let todayStart = cal.startOfDay(for: now)
        
        switch selectedRange {
        case .today:
            return entries.filter { $0.startAt >= todayStart && $0.startAt < now.addingTimeInterval(86400) }
        case .sevenDays:
            let start = cal.date(byAdding: .day, value: -7, to: todayStart) ?? todayStart
            return entries.filter { $0.startAt >= start }
        case .thirtyDays:
            let start = cal.date(byAdding: .day, value: -30, to: todayStart) ?? todayStart
            return entries.filter { $0.startAt >= start }
        case .custom:
            return entries
        }
    }
    
    private var totalSessions: Int {
        filteredEntries.filter { $0.kind == EntryKind.logged.rawValue }.count
    }
    
    private var totalTrackedMinutes: Int {
        filteredEntries.filter { $0.kind == EntryKind.logged.rawValue }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var averageMinutesPerDay: Double {
        let days: Double
        switch selectedRange {
        case .today: days = 1.0
        case .sevenDays: days = 7.0
        case .thirtyDays: days = 30.0
        case .custom: days = max(1.0, Double(totalSessions))
        }
        return Double(totalTrackedMinutes) / days
    }
    
    private var formattedTrackedTime: String {
        let hrs = totalTrackedMinutes / 60
        let mins = totalTrackedMinutes % 60
        if hrs > 0 && mins > 0 {
            return "\(hrs)h \(mins)m"
        } else if hrs > 0 {
            return "\(hrs)h"
        } else {
            return "\(mins)m"
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. Top Header
            HStack {
                Text("HISTORY")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            // 2. Filter Pills
            HStack(spacing: 8) {
                ForEach(HistoryRange.allCases) { range in
                    let isSelected = selectedRange == range
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRange = range
                        }
                    }) {
                        HStack(spacing: 4) {
                            if range == .custom {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                            }
                            Text(range.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .semibold))
                        }
                        .foregroundColor(isSelected ? .black : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.white : Theme.bgCard)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.white : Theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 3. KPI 3-Metric Summary Cards Row
            HStack(spacing: 12) {
                kpiCard(value: "\(totalSessions)", label: "SESSIONS")
                kpiCard(value: formattedTrackedTime, label: "TRACKED")
                kpiCard(value: String(format: "%.1f", averageMinutesPerDay / 60.0), label: "AVG / DAY")
            }
            
            // 4. Sessions Section
            VStack(alignment: .leading, spacing: 10) {
                Text("SESSIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(Theme.textMuted)
                
                let loggedList = filteredEntries
                    .filter { $0.kind == EntryKind.logged.rawValue }
                    .sorted { $0.startAt > $1.startAt }
                
                if loggedList.isEmpty {
                    // Empty state matching mobile screenshot
                    VStack(spacing: 12) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 26))
                            .foregroundColor(Theme.textMuted.opacity(0.6))
                            .frame(width: 52, height: 52)
                            .background(Theme.bgSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("NO SESSIONS")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("NO SESSIONS IN THIS RANGE")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Theme.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 8) {
                            ForEach(loggedList) { entry in
                                sessionRow(entry: entry)
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(Theme.bgDeep)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
        .onAppear {
            loadEntries()
        }
        .sheet(isPresented: $isShowingEditor) {
            EntryEditorPopover(
                entry: $selectedEntryForEdit,
                isPresented: $isShowingEditor,
                onSaved: { loadEntries() },
                onDeleted: { loadEntries() }
            )
        }
    }
    
    private func kpiCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.6)
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func sessionRow(entry: TimesheetEntry) -> some View {
        let isProd = entry.productivity == "productive"
        let prodColor = isProd ? Theme.productive : Theme.wasteful
        
        return HStack(spacing: 12) {
            Circle()
                .fill(prodColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.rawText)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(entry.formattedTimeRange)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    
                    if let cat = entry.category {
                        Text("• \(cat)")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            Text(entry.formattedDuration)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.bgSubtle)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border.opacity(0.6), lineWidth: 1)
        )
        .onTapGesture {
            selectedEntryForEdit = entry
            isShowingEditor = true
        }
    }
    
    private func loadEntries() {
        entries = DatabaseManager.shared.fetchAllEntries()
    }
}
