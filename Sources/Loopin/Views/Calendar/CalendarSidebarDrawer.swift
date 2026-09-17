import SwiftUI

public struct CalendarSidebarDrawer: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var calendarManager: CalendarManager = .shared
    
    @Binding var selectedDate: Date
    var onCreateEvent: () -> Void
    
    @State private var miniCalendarMonth: Date = Date()
    @State private var isMyCalendarsExpanded: Bool = true
    @State private var isOtherCalendarsExpanded: Bool = true
    
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
                    
                    Text("Create")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // 2. Mini Calendar Date Picker
            VStack(alignment: .leading, spacing: 8) {
                // Mini Month Header
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
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            changeMiniMonth(by: 1)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 18, height: 18)
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
                                    isSelected ? Color.white : (isToday ? Theme.accent : (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.4)))
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
            
            // 3. Search for People / Filters
            HStack(spacing: 8) {
                Image(systemName: "person.2")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textMuted)
                Text("Search calendars...")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 14)
            
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 14)
            
            // 4. "My calendars" Section
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    withAnimation { isMyCalendarsExpanded.toggle() }
                }) {
                    HStack {
                        Text("My calendars")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: isMyCalendarsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .buttonStyle(.plain)
                
                if isMyCalendarsExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        calendarToggleRow(
                            id: "primary",
                            title: appState.isSignedInWithGoogle ? appState.googleUserName : "Atharav Narang",
                            color: Theme.accent
                        )
                        
                        calendarToggleRow(
                            id: "birthdays",
                            title: "Birthdays",
                            color: Color(hex: "#FBBC04")
                        )
                        
                        calendarToggleRow(
                            id: "tasks",
                            title: "Tasks & Loopin Logs",
                            color: Theme.productive
                        )
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            
            // 5. "Other calendars" Section
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    withAnimation { isOtherCalendarsExpanded.toggle() }
                }) {
                    HStack {
                        Text("Other calendars")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: isOtherCalendarsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .buttonStyle(.plain)
                
                if isOtherCalendarsExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        calendarToggleRow(
                            id: "holidays_india",
                            title: "Holidays in India",
                            color: Color(hex: "#34A853") // Green pill matching Google Calendar screenshot
                        )
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
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
            // Keep mini calendar month synced if user navigated far
            if !Calendar.current.isDate(newDate, equalTo: miniCalendarMonth, toGranularity: .month) {
                miniCalendarMonth = newDate
            }
        }
    }
    
    private func calendarToggleRow(id: String, title: String, color: Color) -> some View {
        let isChecked = calendarManager.isCalendarVisible(id: id)
        
        return Button(action: {
            calendarManager.toggleCalendarVisibility(id: id)
        }) {
            HStack(spacing: 8) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(isChecked ? color : Color.clear)
                        .frame(width: 15, height: 15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3.5)
                                .stroke(color, lineWidth: 1.5)
                        )
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
    }
    
    private var miniCalendarTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: miniCalendarMonth)
    }
    
    private func changeMiniMonth(by delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: miniCalendarMonth) {
            miniCalendarMonth = next
        }
    }
    
    private func generateDaysInMiniMonth(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: date) else { return [] }
        
        let startOfMonth = monthInterval.start
        let weekday = cal.component(.weekday, from: startOfMonth) // 1 = Sunday, 7 = Saturday
        let daysToPrepend = weekday - 1
        
        let firstCalendarDay = cal.date(byAdding: .day, value: -daysToPrepend, to: startOfMonth) ?? startOfMonth
        
        return (0..<35).compactMap { cal.date(byAdding: .day, value: $0, to: firstCalendarDay) }
    }
}
