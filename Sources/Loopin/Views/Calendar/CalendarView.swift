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
    
    @State private var selectedDate: Date = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var isSidebarVisible: Bool = true
    
    // Event Editor Sheet State
    @State private var selectedEventForEdit: CalendarEvent?
    @State private var isShowingEditor: Bool = false
    @State private var draftRangeStart: Date?
    @State private var draftRangeEnd: Date?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Google Calendar Top Bar
            topNavigationBar
            
            Divider().background(Theme.border)
            
            // 2. Main Body with Sidebar Drawer & Calendar Grid
            HStack(spacing: 0) {
                if isSidebarVisible {
                    CalendarSidebarDrawer(
                        selectedDate: $selectedDate,
                        onCreateEvent: {
                            selectedEventForEdit = nil
                            draftRangeStart = selectedDate
                            draftRangeEnd = selectedDate
                            isShowingEditor = true
                        }
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                // Calendar Grid View (Month or Year)
                ZStack {
                    switch viewMode {
                    case .month:
                        MonthCalendarGrid(
                            monthDate: selectedDate,
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
                            }
                        )
                    case .year:
                        YearCalendarGrid(
                            year: Calendar.current.component(.year, from: selectedDate),
                            onSelectMonth: { monthDate in
                                selectedDate = monthDate
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .month
                                }
                            },
                            onSelectDay: { dayDate in
                                selectedDate = dayDate
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewMode = .month
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
            // Sidebar Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSidebarVisible.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Toggle Calendar Sidebar")
            
            // App Title Icon + "Calendar" (with today's day number in blue box like Google Calendar)
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.accent)
                        .frame(width: 24, height: 24)
                    
                    Text("\(Calendar.current.component(.day, from: Date()))")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("Calendar")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.trailing, 6)
            
            // "Today" Button
            Button(action: {
                withAnimation {
                    selectedDate = Date()
                }
            }) {
                Text("Today")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 11)
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
            
            // Main Month/Year Title (e.g. "September 2026")
            Text(currentFormattedHeaderTitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            // Sync Button (Google Calendar & Local Store Sync)
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
            
            // Google Account Avatar / Badge
            Button(action: {
                appState.selectedTab = .account
            }) {
                HStack(spacing: 6) {
                    if appState.isSignedInWithGoogle {
                        Circle()
                            .fill(Theme.productive)
                            .frame(width: 8, height: 8)
                        
                        Text(appState.googleUserName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                        Text("Google Cal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(Theme.bgSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(appState.isSignedInWithGoogle ? "Connected as \(appState.googleUserEmail)" : "Connect your Google Calendar account")
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
        return f.string(from: selectedDate)
    }
    
    private func navigateDate(by delta: Int) {
        let cal = Calendar.current
        withAnimation(.easeInOut(duration: 0.15)) {
            if viewMode == .month {
                if let next = cal.date(byAdding: .month, value: delta, to: selectedDate) {
                    selectedDate = next
                }
            } else {
                if let next = cal.date(byAdding: .year, value: delta, to: selectedDate) {
                    selectedDate = next
                }
            }
        }
    }
}
