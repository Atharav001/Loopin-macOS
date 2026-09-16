import SwiftUI

public struct AnalyticsView: View {
    @State private var selectedTimeframe: Timeframe = .thisWeek
    @State private var entries: [TimesheetEntry] = []
    
    public enum Timeframe: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case past7Days = "Past 7 Days"
        case thisMonth = "This Month"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    private var totalTrackedMinutes: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var productiveMinutes: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue && $0.productivity == "productive" }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var neutralMinutes: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue && $0.productivity == "neutral" }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var wastefulMinutes: Int {
        entries.filter { $0.kind == EntryKind.logged.rawValue && ($0.productivity == "wasteful" || $0.productivity == "neutral") }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var focusScorePercentage: Int {
        guard totalTrackedMinutes > 0 else { return 0 }
        return Int(round(Double(productiveMinutes) / Double(totalTrackedMinutes) * 100))
    }
    
    private var categoryStats: [CategoryStat] {
        let logged = entries.filter { $0.kind == EntryKind.logged.rawValue }
        var grouped: [String: (minutes: Int, prod: ProductivityType)] = [:]
        
        for entry in logged {
            let cat = entry.category ?? "General"
            let prod = entry.productivityType ?? .productive
            let current = grouped[cat]?.minutes ?? 0
            grouped[cat] = (current + entry.durationMinutes, prod)
        }
        
        let total = max(1, totalTrackedMinutes)
        return grouped.map { cat, val in
            CategoryStat(
                name: cat,
                totalMinutes: val.minutes,
                productivity: val.prod,
                percentage: Double(val.minutes) / Double(total)
            )
        }.sorted { $0.totalMinutes > $1.totalMinutes }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
            
            // Analytics Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // KPI Stat Cards Row
                    kpiCardsRow
                    
                    // Focus Highlights & Executive Insights
                    focusHighlightsRow
                    
                    // 24-Hour Activity Rhythm & Density Map
                    hourlyHeatmapCard
                    
                    // Productivity Ratio Stacked Bar
                    ProductivityStackedBar(
                        productiveMinutes: productiveMinutes,
                        neutralMinutes: 0,
                        wastefulMinutes: wastefulMinutes
                    )
                    
                    // Category Distribution Bar Chart
                    CategoryBarChart(stats: categoryStats)
                }
                .padding(24)
            }
        }
        .background(Theme.bgDeep)
        .onAppear {
            loadEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadEntries()
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(Theme.accentLight)
                Text("Analytics & Reports")
                    .font(Theme.titleMedium)
                    .foregroundColor(Theme.textPrimary)
            }
            
            Spacer()
            
            // Timeframe Segment
            HStack(spacing: 4) {
                ForEach(Timeframe.allCases) { timeframe in
                    let isSelected = selectedTimeframe == timeframe
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTimeframe = timeframe
                            loadEntries()
                        }
                    }) {
                        Text(timeframe.rawValue)
                            .font(Theme.caption)
                            .fontWeight(isSelected ? .semibold : .medium)
                            .foregroundColor(isSelected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? Theme.accent : Theme.bgSubtle)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Theme.bgDark)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - KPI Cards Row
    private var kpiCardsRow: some View {
        HStack(spacing: 16) {
            kpiCard(
                title: "Total Tracked",
                value: formatHoursAndMinutes(totalTrackedMinutes),
                subtitle: "\(entries.count) total entries",
                icon: "clock.fill",
                color: Theme.accentLight
            )
            
            kpiCard(
                title: "Focus Score",
                value: "\(focusScorePercentage)%",
                subtitle: "Productive time ratio",
                icon: "bolt.shield.fill",
                color: Theme.productive
            )
            
            kpiCard(
                title: "Productive Time",
                value: formatHoursAndMinutes(productiveMinutes),
                subtitle: "\(categoryStats.filter { $0.productivity == .productive }.count) categories",
                icon: "checkmark.circle.fill",
                color: Theme.productive
            )
            
            kpiCard(
                title: "Distraction Time",
                value: formatHoursAndMinutes(wastefulMinutes),
                subtitle: "Wasteful activities",
                icon: "flame.fill",
                color: Theme.wasteful
            )
        }
    }
    
    private func kpiCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(Theme.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(Theme.textMuted)
        }
        .padding(14)
        .glassCard(cornerRadius: 12)
    }
    
    // MARK: - Focus Highlights & Executive Insights Row
    private var focusHighlightsRow: some View {
        HStack(spacing: 14) {
            insightTile(
                title: "Top Category",
                value: categoryStats.first?.name ?? "Coding",
                subtitle: categoryStats.first != nil ? "\(Int(categoryStats.first!.percentage * 100))% of tracked time" : "No entries yet",
                icon: "tag.fill",
                color: Theme.accent
            )
            
            insightTile(
                title: "Productivity Ratio",
                value: "\(focusScorePercentage)%",
                subtitle: focusScorePercentage >= 70 ? "High Focus Output" : "Balanced Work Output",
                icon: "sparkles",
                color: Theme.productive
            )
            
            insightTile(
                title: "Logged Activities",
                value: "\(entries.filter { $0.kind == EntryKind.logged.rawValue }.count) Sessions",
                subtitle: "\(formatHoursAndMinutes(totalTrackedMinutes)) total time",
                icon: "checklist",
                color: Theme.accentLight
            )
            
            insightTile(
                title: "Planned Target",
                value: "\(entries.filter { $0.kind == EntryKind.planned.rawValue }.count) Planned",
                subtitle: "Scheduled roadmap blocks",
                icon: "calendar.badge.clock",
                color: Theme.planned
            )
        }
    }
    
    private func insightTile(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9.5))
                    .foregroundColor(Theme.textMuted)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .glassCard(cornerRadius: 10)
    }
    
    // MARK: - 24-Hour Activity Rhythm & Density Map
    private var hourlyHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.accentLight)
                    Text("Daily Activity Rhythm & Density (00:00 – 23:00)")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                    Rectangle().fill(Theme.bgSubtle).frame(width: 10, height: 10).cornerRadius(2)
                    Rectangle().fill(Theme.accent.opacity(0.3)).frame(width: 10, height: 10).cornerRadius(2)
                    Rectangle().fill(Theme.accent.opacity(0.7)).frame(width: 10, height: 10).cornerRadius(2)
                    Rectangle().fill(Theme.accent).frame(width: 10, height: 10).cornerRadius(2)
                    Text("More")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                }
            }
            
            // 24 Hour blocks grid
            let densityMap = computeHourlyDensity()
            HStack(spacing: 4) {
                ForEach(0..<24, id: \.self) { hour in
                    let count = densityMap[hour] ?? 0
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(densityColor(for: count))
                            .frame(height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(count > 0 ? Theme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        
                        if hour % 3 == 0 {
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        } else {
                            Text("")
                                .font(.system(size: 8.5))
                                .frame(height: 10)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    private func computeHourlyDensity() -> [Int: Int] {
        var map: [Int: Int] = [:]
        let cal = Calendar.current
        for entry in entries {
            let hour = cal.component(.hour, from: entry.startAt)
            map[hour, default: 0] += 1
        }
        return map
    }
    
    private func densityColor(for count: Int) -> Color {
        if count == 0 {
            return Theme.bgSubtle
        } else if count == 1 {
            return Theme.accent.opacity(0.35)
        } else if count == 2 {
            return Theme.accent.opacity(0.65)
        } else {
            return Theme.accent
        }
    }
    
    private func formatHoursAndMinutes(_ totalMinutes: Int) -> String {
        let hrs = totalMinutes / 60
        let mins = totalMinutes % 60
        if hrs == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hrs)h"
        } else {
            return "\(hrs)h \(mins)m"
        }
    }
    
    private func loadEntries() {
        let cal = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .today:
            entries = DatabaseManager.shared.fetchForDay(now)
        case .thisWeek:
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            comps.weekday = 2
            let weekStart = cal.date(from: comps) ?? now
            entries = DatabaseManager.shared.fetchForWeek(weekStart)
        case .past7Days:
            let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
            entries = DatabaseManager.shared.fetchEntriesInRange(start: start, end: now)
        case .thisMonth:
            let comps = cal.dateComponents([.year, .month], from: now)
            let monthStart = cal.date(from: comps) ?? now
            let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
            entries = DatabaseManager.shared.fetchEntriesInRange(start: monthStart, end: monthEnd)
        }
    }
}
