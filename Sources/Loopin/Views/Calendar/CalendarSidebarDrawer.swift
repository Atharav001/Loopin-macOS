import SwiftUI

public struct CalendarSidebarDrawer: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    @ObservedObject var googleAuth: GoogleAuthService = .shared
    
    @Binding var selectedDate: Date
    var onCreateEvent: () -> Void
    
    @State private var miniCalendarMonth: Date = Date()
    @State private var isCalendarsExpanded: Bool = true
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    public init(
        selectedDate: Binding<Date>,
        onCreateEvent: @escaping () -> Void
    ) {
        self._selectedDate = selectedDate
        self.onCreateEvent = onCreateEvent
        self._miniCalendarMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. "+ Create" Button (Google Calendar Style)
            Button(action: onCreateEvent) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    Text("Create Event")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text("⌘N")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // 2. Mini Calendar Date Picker
            VStack(alignment: .leading, spacing: 8) {
                // Mini Month Header with Navigation
                HStack {
                    Text(miniCalendarTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Button(action: {
                            changeMiniMonth(by: -1)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 20, height: 20)
                                .background(Theme.bgSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            changeMiniMonth(by: 1)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 20, height: 20)
                                .background(Theme.bgSubtle)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                
                // Days of week header (S M T W T F S)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { idx in
                        Text(daysOfWeek[idx])
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Mini Calendar Days Grid
                let days = generateDaysInMiniMonth(for: miniCalendarMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(day)
                        let isCurrentMonth = Calendar.current.isDate(day, equalTo: miniCalendarMonth, toGranularity: .month)
                        
                        Button(action: {
                            selectedDate = day
                        }) {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.system(size: 10.5, weight: isSelected || isToday ? .bold : .regular))
                                .foregroundColor(
                                    isSelected ? Color.white : (isToday ? Theme.accent : (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.3)))
                                )
                                .frame(width: 22, height: 22)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            Circle().fill(Theme.accent)
                                        } else if isToday {
                                            Circle().stroke(Theme.accent, lineWidth: 1.5)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(10)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)
            
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 14)
            
            // 3. Consolidated Real Calendars Section (Toggleable to plan simultaneously)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("MY CALENDARS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                    
                    Spacer()
                    
                    Text("\(calendarManager.visibleCalendarIds.count)/4 active")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    // 1. Loopin Actual Logged
                    calendarToggleRow(
                        id: "logged",
                        title: "Actual Logged",
                        subtitle: "Tracked hours in Loopin",
                        color: Theme.productive,
                        icon: "bolt.fill"
                    )
                    
                    // 2. Loopin Planned Rails
                    calendarToggleRow(
                        id: "planned",
                        title: "Planned Blocks",
                        subtitle: "Planned rails & tasks",
                        color: Color(hex: "#8B5CF6"),
                        icon: "calendar.badge.clock"
                    )
                    
                    // 3. Google Calendar
                    calendarToggleRow(
                        id: "google",
                        title: appState.isSignedInWithGoogle ? "Google (\(appState.googleUserName))" : "Google Calendar",
                        subtitle: appState.isSignedInWithGoogle ? "Synced with account" : "Click to connect",
                        color: Theme.accent,
                        icon: "globe"
                    )
                    
                    // 4. Holidays in India
                    calendarToggleRow(
                        id: "holidays_india",
                        title: "Holidays in India",
                        subtitle: "National & cultural festivals",
                        color: Color(hex: "#34A853"),
                        icon: "flag.fill"
                    )
                }
                .padding(.horizontal, 14)
            }
            
            Spacer()
            
            // 4. Bottom Sync Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.isSignedInWithGoogle ? Theme.productive : Theme.accent)
                    .frame(width: 7, height: 7)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(appState.isSignedInWithGoogle ? "Google Connected" : "Local Sync Mode")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(calendarManager.syncStatusMessage)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(14)
        }
        .frame(width: 230)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
        .onChange(of: selectedDate) { _, newDate in
            if !Calendar.current.isDate(newDate, equalTo: miniCalendarMonth, toGranularity: .month) {
                miniCalendarMonth = newDate
            }
        }
    }
    
    private func calendarToggleRow(
        id: String,
        title: String,
        subtitle: String,
        color: Color,
        icon: String
    ) -> some View {
        let isChecked = calendarManager.isCalendarVisible(id: id)
        
        return Button(action: {
            calendarManager.toggleCalendarVisibility(id: id)
        }) {
            HStack(spacing: 9) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked ? color : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(color, lineWidth: 1.5)
                        )
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11.5, weight: isChecked ? .semibold : .medium))
                        .foregroundColor(isChecked ? Theme.textPrimary : Theme.textSecondary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isChecked ? color.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private var miniCalendarTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: miniCalendarMonth)
    }
    
    private func changeMiniMonth(by delta: Int) {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: miniCalendarMonth)
        comps.day = 1
        if let first = cal.date(from: comps),
           let next = cal.date(byAdding: .month, value: delta, to: first) {
            miniCalendarMonth = next
        }
    }
    
    private func generateDaysInMiniMonth(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: date) else { return [] }
        
        let startOfMonth = monthInterval.start
        let weekday = cal.component(.weekday, from: startOfMonth)
        let daysToPrepend = weekday - 1
        
        let firstCalendarDay = cal.date(byAdding: .day, value: -daysToPrepend, to: startOfMonth) ?? startOfMonth
        return (0..<35).compactMap { cal.date(byAdding: .day, value: $0, to: firstCalendarDay) }
    }
}
