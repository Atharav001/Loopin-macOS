import SwiftUI

public enum CalendarViewMode: String, CaseIterable, Identifiable {
    case month = "Month"
    case year = "Year"
    
    public var id: String { rawValue }
}

public struct CalendarView: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    @ObservedObject var googleAuth: GoogleAuthService = .shared
    
    @State private var viewMode: CalendarViewMode = .month
    
    // Event Editor Sheet State
    @State private var selectedEventForEdit: CalendarEvent?
    @State private var isShowingEditor: Bool = false
    @State private var draftRangeStart: Date?
    @State private var draftRangeEnd: Date?
    
    public init() {}
    
    private var cal: Calendar { Calendar.current }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Navigation Bar (Full width, clean spacing)
            topNavigationBar
            
            Divider().background(Theme.border)
            
            // 2. Full Canvas Calendar Grid (Month or Year)
            ZStack {
                switch viewMode {
                case .month:
                    MonthCalendarGrid(
                        monthDate: appState.calendarSelectedDate,
                        onSelectEvent: { event in
                            selectedEventForEdit = event
                            draftRangeStart = nil
                            draftRangeEnd = nil
                            isShowingEditor = true
                        },
                        onSelectRange: { start, end in
                            selectedEventForEdit = nil
                            draftRangeStart = start
                            draftRangeEnd = end
                            isShowingEditor = true
                        },
                        onScrollMonth: { delta in
                            navigateDate(by: delta)
                        }
                    )
                case .year:
                    YearCalendarGrid(
                        year: cal.component(.year, from: appState.calendarSelectedDate),
                        onSelectMonth: { monthDate in
                            appState.calendarSelectedDate = monthDate
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewMode = .month
                            }
                        },
                        onSelectDay: { dayDate in
                            appState.calendarSelectedDate = dayDate
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewMode = .month
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.bgDeep)
        .sheet(isPresented: $isShowingEditor) {
            CalendarEventEditorSheet(
                event: $selectedEventForEdit,
                isPresented: $isShowingEditor,
                initialStartDate: draftRangeStart,
                initialEndDate: draftRangeEnd
            )
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // "Today" Button
            Button(action: {
                withAnimation {
                    appState.calendarSelectedDate = Date()
                }
            }) {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            // Navigation chevrons `<` `>`
            HStack(spacing: 2) {
                Button(action: { navigateDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 26, height: 28)
                }
                .buttonStyle(.plain)
                
                Button(action: { navigateDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 26, height: 28)
                }
                .buttonStyle(.plain)
            }
            
            // Main Month/Year Title with Direct Quick Jump Menu
            Menu {
                // Quick jump to Years
                Section("Select Year") {
                    ForEach([2024, 2025, 2026, 2027, 2028, 2029, 2030], id: \.self) { yr in
                        Button(action: { jumpToYear(yr) }) {
                            Text("\(yr)")
                        }
                    }
                }
                
                // Quick jump to Months
                if viewMode == .month {
                    Section("Select Month") {
                        ForEach(1...12, id: \.self) { m in
                            Button(action: { jumpToMonth(m) }) {
                                Text(monthNameFor(m))
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentFormattedHeaderTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                }
            }
            .menuStyle(.borderlessButton)
            
            // "+ New Event" Button
            Button(action: {
                selectedEventForEdit = nil
                draftRangeStart = appState.calendarSelectedDate
                draftRangeEnd = appState.calendarSelectedDate
                isShowingEditor = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New Event")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Theme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Sync Button
            Button(action: {
                Task {
                    await calendarManager.syncWithGoogleCalendar()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(calendarManager.isSyncing ? 360 : 0))
                        .animation(calendarManager.isSyncing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: calendarManager.isSyncing)
                    
                    Text(calendarManager.isSyncing ? "Syncing..." : "Sync")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundColor(calendarManager.isSyncing ? Theme.accentLight : Theme.textPrimary)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Sync events with Google Calendar")
            
            // View Mode Segmented Switcher (Month / Year)
            Picker("", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            
            // Google Account Pill
            Button(action: {
                appState.selectedTab = .account
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isSignedInWithGoogle ? Theme.productive : Theme.accent)
                        .frame(width: 7, height: 7)
                    
                    Text(appState.googleUserEmail.isEmpty ? "atharavnarang05@gmail.com" : appState.googleUserEmail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Theme.bgSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Google Calendar Account: \(appState.googleUserEmail)")
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Theme.bgDark)
    }
    
    private var currentFormattedHeaderTitle: String {
        let f = DateFormatter()
        if viewMode == .month {
            f.dateFormat = "MMMM yyyy"
        } else {
            f.dateFormat = "yyyy"
        }
        return f.string(from: appState.calendarSelectedDate)
    }
    
    // MARK: - Exact Year/Month Specific Navigation
    private func navigateDate(by delta: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if viewMode == .month {
                var comps = cal.dateComponents([.year, .month], from: appState.calendarSelectedDate)
                comps.day = 1
                if let firstOfMonth = cal.date(from: comps),
                   let next = cal.date(byAdding: .month, value: delta, to: firstOfMonth) {
                    appState.calendarSelectedDate = next
                }
            } else {
                var comps = cal.dateComponents([.year], from: appState.calendarSelectedDate)
                comps.month = cal.component(.month, from: appState.calendarSelectedDate)
                comps.day = 1
                if let first = cal.date(from: comps),
                   let next = cal.date(byAdding: .year, value: delta, to: first) {
                    appState.calendarSelectedDate = next
                }
            }
        }
    }
    
    private func jumpToYear(_ year: Int) {
        var comps = cal.dateComponents([.month, .day], from: appState.calendarSelectedDate)
        comps.year = year
        if let target = cal.date(from: comps) {
            withAnimation { appState.calendarSelectedDate = target }
        }
    }
    
    private func jumpToMonth(_ month: Int) {
        var comps = cal.dateComponents([.year], from: appState.calendarSelectedDate)
        comps.month = month
        comps.day = 1
        if let target = cal.date(from: comps) {
            withAnimation { appState.calendarSelectedDate = target }
        }
    }
    
    private func monthNameFor(_ month: Int) -> String {
        let f = DateFormatter()
        return f.monthSymbols[month - 1]
    }
}
