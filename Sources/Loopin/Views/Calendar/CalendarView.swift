import SwiftUI

public enum CalendarViewMode: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    public var id: String { rawValue }
}

public struct CalendarView: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    @ObservedObject var googleAuth: GoogleAuthService = .shared
    @ObservedObject var macCalendar: MacCalendarService = .shared
    
    @State private var viewMode: CalendarViewMode = .month
    
    // Event Editor Sheet State
    @State private var selectedEventForEdit: CalendarEvent?
    @State private var isShowingEditor: Bool = false
    @State private var draftRangeStart: Date?
    @State private var draftRangeEnd: Date?
    
    public init() {}
    
    private var cal: Calendar { Calendar.current }
    
    public var body: some View {
        HStack(spacing: 0) {
            // 1. Dedicated Calendar Secondary Sidebar
            if appState.isCalendarSidebarVisible {
                CalendarSidebarDrawer(
                    selectedDate: $appState.calendarSelectedDate,
                    onCreateEvent: {
                        selectedEventForEdit = nil
                        draftRangeStart = appState.calendarSelectedDate
                        draftRangeEnd = appState.calendarSelectedDate
                        isShowingEditor = true
                    }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // 2. Main Calendar Canvas
            VStack(spacing: 0) {
                // Top Navigation Bar matching macOS Calendar
                topBar
                
                // Subheader with Month Year and < Today > navigation
                subHeaderBar
                
                // Full Canvas Calendar Grid
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
                    case .week:
                        WeekCalendarView()
                    case .day:
                        let dayEntries = DatabaseManager.shared.fetchForDay(appState.calendarSelectedDate)
                        DayColumnView(
                            date: appState.calendarSelectedDate,
                            entries: dayEntries,
                            isToday: cal.isDateInToday(appState.calendarSelectedDate),
                            onSelectEntry: { entry in
                                appState.editingEntry = entry
                                appState.showEntryEditor = true
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
        }
        .background(Color(red: 27/255, green: 28/255, blue: 30/255))
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: appState.isCalendarSidebarVisible)
        .sheet(isPresented: $isShowingEditor) {
            CalendarEventEditorSheet(
                event: $selectedEventForEdit,
                isPresented: $isShowingEditor,
                initialStartDate: draftRangeStart,
                initialEndDate: draftRangeEnd
            )
        }
    }
    
    // MARK: - Top Bar (matching uploaded screenshot: + on left, Day|Week|Month|Year in middle, search on right)
    private var topBar: some View {
        HStack {
            // Far Left: Circular "+" Button
            Button(action: {
                selectedEventForEdit = nil
                draftRangeStart = appState.calendarSelectedDate
                draftRangeEnd = appState.calendarSelectedDate
                isShowingEditor = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(white: 0.85))
                    .frame(width: 28, height: 28)
                    .background(Color(white: 0.16))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.25), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .help("New Event (+)")
            
            Spacer()
            
            // Center: Segmented Capsule Control (Day | Week | Month | Year)
            HStack(spacing: 2) {
                ForEach(CalendarViewMode.allCases) { mode in
                    let isSelected = viewMode == mode
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewMode = mode
                        }
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? .white : Color(white: 0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                            .background(
                                isSelected ? Color(white: 0.28) : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color(white: 0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(white: 0.22), lineWidth: 0.8)
            )
            
            Spacer()
            
            // Far Right: Circular Search Button
            Button(action: {
                // Toggle sidebar or quick search
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    appState.isCalendarSidebarVisible.toggle()
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.85))
                    .frame(width: 28, height: 28)
                    .background(Color(white: 0.16))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.25), lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .help("Search & Calendars")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color(red: 25/255, green: 26/255, blue: 28/255))
    }
    
    // MARK: - Subheader Bar (Month Year on left, < Today > on right)
    private var subHeaderBar: some View {
        HStack {
            // Left: Large Month & Year Title
            Menu {
                Section("Select Year") {
                    ForEach([2024, 2025, 2026, 2027, 2028, 2029, 2030], id: \.self) { yr in
                        Button(action: { jumpToYear(yr) }) {
                            Text("\(yr)")
                        }
                    }
                }
                
                Section("Select Month") {
                    ForEach(1...12, id: \.self) { m in
                        Button(action: { jumpToMonth(m) }) {
                            Text(monthNameFor(m))
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentFormattedHeaderTitle)
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(Color(white: 0.94))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(white: 0.45))
                }
            }
            .menuStyle(.borderlessButton)
            
            Spacer()
            
            // Right: Sync & Navigation controls
            HStack(spacing: 10) {
                // Sync button
                Button(action: {
                    Task {
                        await calendarManager.syncAllCalendars(year: cal.component(.year, from: appState.calendarSelectedDate))
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(calendarManager.isSyncing ? 360 : 0))
                            .animation(calendarManager.isSyncing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: calendarManager.isSyncing)
                        
                        Text(calendarManager.isSyncing ? "Syncing..." : "Sync")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Color(white: 0.75))
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(Color(white: 0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color(white: 0.22), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Sync Mac & Google Calendars")
                
                // < Today > Navigation Group
                HStack(spacing: 1) {
                    Button(action: { navigateDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.75))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation {
                            appState.calendarSelectedDate = Date()
                        }
                    }) {
                        Text("Today")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(white: 0.9))
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { navigateDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(white: 0.75))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(white: 0.14))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(white: 0.22), lineWidth: 0.8)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(Color(red: 25/255, green: 26/255, blue: 28/255))
    }
    
    private var currentFormattedHeaderTitle: String {
        let f = DateFormatter()
        if viewMode == .month || viewMode == .week || viewMode == .day {
            f.dateFormat = "MMMM yyyy"
        } else {
            f.dateFormat = "yyyy"
        }
        return f.string(from: appState.calendarSelectedDate)
    }
    
    // MARK: - Navigation helpers
    private func navigateDate(by delta: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if viewMode == .month {
                var comps = cal.dateComponents([.year, .month], from: appState.calendarSelectedDate)
                comps.day = 1
                if let firstOfMonth = cal.date(from: comps),
                   let next = cal.date(byAdding: .month, value: delta, to: firstOfMonth) {
                    appState.calendarSelectedDate = next
                }
            } else if viewMode == .week {
                if let next = cal.date(byAdding: .weekOfYear, value: delta, to: appState.calendarSelectedDate) {
                    appState.calendarSelectedDate = next
                }
            } else if viewMode == .day {
                if let next = cal.date(byAdding: .day, value: delta, to: appState.calendarSelectedDate) {
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
