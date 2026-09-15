import SwiftUI

public struct RailsView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var entries: [TimesheetEntry] = []
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Today's Executive Summary Header
                todaySummaryCard
                
                // Quick-plan natural language input
                QuickPlanInputView(onAdded: {
                    loadEntries()
                })
                
                // Interval banner with live countdown
                IntervalBannerView()
                
                // Dual Timesheet Rails (Planned & Logged)
                TimesheetRailsView(entries: entries, onSelectEntry: { entry in
                    appState.editingEntry = entry
                    appState.showEntryEditor = true
                })
                
                // Today's blocks breakdown list
                TodayBlocksListView(
                    entries: entries,
                    onEdit: { entry in
                        appState.editingEntry = entry
                        appState.showEntryEditor = true
                    },
                    onDelete: { entry in
                        DatabaseManager.shared.deleteEntry(id: entry.id)
                        loadEntries()
                    },
                    onAddSample: {
                        SampleDataSeeder.seedSampleEntries()
                        loadEntries()
                    }
                )
            }
            .padding(24)
        }
        .onAppear {
            loadEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadEntries()
        }
    }
    
    private var totalMinutesToday: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var plannedMinutesToday: Int {
        entries.filter { $0.kind == EntryKind.planned.rawValue }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var productiveMinutesToday: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue && $0.productivity == "productive" }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var todaySummaryCard: some View {
        let dailyGoalMinutes = 8 * 60
        let progress = min(1.0, Double(totalMinutesToday) / Double(dailyGoalMinutes))
        let focusScore = totalMinutesToday > 0 ? Int(round(Double(productiveMinutesToday) / Double(totalMinutesToday) * 100)) : 0
        
        return HStack(spacing: 20) {
            // Left: Date & Time Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text(formattedTodayDate())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Text("\(entries.count) total blocks recorded today • \(formatDuration(plannedMinutesToday)) planned")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            // Middle: Target Goal Progress
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Theme.bgSubtle, lineWidth: 5)
                        .frame(width: 42, height: 42)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progress))
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Goal: 8h")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(formatDuration(totalMinutesToday)) Logged")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accentLight)
                }
            }
            
            Divider().background(Theme.border)
                .frame(height: 36)
            
            // Right: Focus Score & Fast Action
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus Score")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.productive)
                        Text("\(focusScore)%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.productive)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 14)
    }
    
    private func formattedTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func formatDuration(_ mins: Int) -> String {
        let h = mins / 60
        let m = mins % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
    
    private func loadEntries() {
        entries = DatabaseManager.shared.fetchForDay(Date())
    }
}
