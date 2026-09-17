import SwiftUI

public struct CalendarSidebarDrawer: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    @Binding var selectedDate: Date
    var onCreateEvent: () -> Void
    
    @State private var miniCalendarMonth: Date = Date()
    
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
        VStack(alignment: .leading, spacing: 0) {
            // 1. Clean Top Header Bar (Height: 52px to align with calendar top bar)
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    Text("Calendars")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                // Hide / Collapse button for this calendar drawer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        appState.isCalendarSidebarVisible = false
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Hide Calendars Panel")
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            
            Divider().background(Theme.border)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // 2. "+ New Event" Primary Action
                    Button(action: onCreateEvent) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.accent)
                            
                            Text("New Event")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Text("⌘N")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    
                    // 3. Mini Month Calendar Card
                    miniCalendarCard
                        .padding(.horizontal, 12)
                    
                    Divider()
                        .background(Theme.border)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 2)
                    
                    // 4. My Calendars Section (Google & Loopin)
                    VStack(alignment: .leading, spacing: 14) {
                        // MacBook Calendar Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MACBOOK CALENDAR")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                                .padding(.horizontal, 14)
                            
                            calendarToggleRow(
                                id: "mac_calendar",
                                title: "Mac Calendar & Tasks",
                                color: Color(red: 59/255, green: 130/255, blue: 246/255) // Blue
                            )
                        }
                        
                        // Google Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GOOGLE")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                                .padding(.horizontal, 14)
                            
                            calendarToggleRow(
                                id: "google",
                                title: appState.googleUserEmail.isEmpty ? "atharavnarang05@gmail.com" : appState.googleUserEmail,
                                color: Color(red: 79/255, green: 170/255, blue: 189/255) // Teal
                            )
                            
                            calendarToggleRow(
                                id: "holidays_india",
                                title: "Holidays in India",
                                color: Color(red: 52/255, green: 168/255, blue: 83/255) // Green
                            )
                        }
                        
                        // Loopin Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LOOPIN")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.6)
                                .padding(.horizontal, 14)
                            
                            calendarToggleRow(
                                id: "logged",
                                title: "Log Sheet",
                                color: Color(red: 16/255, green: 185/255, blue: 129/255) // Emerald
                            )
                            
                            calendarToggleRow(
                                id: "planned",
                                title: "Pre-planned",
                                color: Color(red: 139/255, green: 92/255, blue: 246/255) // Purple
                            )
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 220)
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
    
    // MARK: - Mini Calendar Card
    private var miniCalendarCard: some View {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let monthTitle = f.string(from: miniCalendarMonth)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Month Header (< Month Year >)
            HStack {
                Button(action: { changeMiniMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { changeMiniMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Days of week header (S M T W T F S)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(daysOfWeek[idx])
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 6-Week Days Grid (42 days with faded boundary days)
            let days = generateDaysInMiniMonth(for: miniCalendarMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { day in
                    let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
                    let isToday = cal.isDateInToday(day)
                    let isCurrentMonth = cal.isDate(day, equalTo: miniCalendarMonth, toGranularity: .month)
                    let dayNum = cal.component(.day, from: day)
                    
                    Button(action: {
                        selectedDate = day
                    }) {
                        Text("\(dayNum)")
                            .font(.system(size: 9.5, weight: isSelected || isToday ? .bold : (isCurrentMonth ? .semibold : .regular)))
                            .foregroundColor(
                                isToday ? Color.white :
                                (isSelected ? Color.white :
                                (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.35)))
                            )
                            .frame(width: 20, height: 20)
                            .background(
                                ZStack {
                                    if isToday {
                                        Circle().fill(Color(red: 235/255, green: 59/255, blue: 50/255))
                                    } else if isSelected {
                                        Circle().fill(Theme.accent)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Interactive Toggle Row (Toggle repeatedly with immediate reactivity)
    private func calendarToggleRow(
        id: String,
        title: String,
        color: Color
    ) -> some View {
        let isChecked = calendarManager.isCalendarVisible(id: id)
        
        return Button(action: {
            calendarManager.toggleCalendarVisibility(id: id)
        }) {
            HStack(spacing: 8) {
                // Square check box matching Apple Calendar design
                ZStack {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(isChecked ? color : Color.clear)
                        .frame(width: 14, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3.5)
                                .stroke(color, lineWidth: 1.5)
                        )
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11.5, weight: isChecked ? .medium : .regular))
                    .foregroundColor(isChecked ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4.5)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
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
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: firstCalendarDay) }
    }
}
