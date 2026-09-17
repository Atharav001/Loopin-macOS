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
        VStack(alignment: .leading, spacing: 16) {
            // 1. "+ Create" Quick Action Button
            Button(action: onCreateEvent) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    Text("New Event")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Text("⌘N")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            
            // 2. Calendar Groups (Styled like Apple Calendar / macOS Calendar)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Group 1: Google
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Google")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, 14)
                        
                        VStack(spacing: 2) {
                            // User's Google Email ID
                            sidebarToggleItem(
                                id: "google",
                                title: appState.googleUserEmail.isEmpty ? "atharavnarang05@gmail.com" : appState.googleUserEmail,
                                color: Color(red: 79/255, green: 170/255, blue: 189/255) // Cyan/Teal matching screenshot
                            )
                            
                            // Holidays in India
                            sidebarToggleItem(
                                id: "holidays_india",
                                title: "Holidays in India",
                                color: Color(red: 52/255, green: 168/255, blue: 83/255) // Emerald Green (#34A853)
                            )
                        }
                    }
                    
                    // Group 2: Loopin
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Loopin")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, 14)
                        
                        VStack(spacing: 2) {
                            // Log Sheet (Actual logged entries)
                            sidebarToggleItem(
                                id: "logged",
                                title: "Log Sheet",
                                color: Color(red: 16/255, green: 185/255, blue: 129/255) // Emerald
                            )
                            
                            // Pre-planned (Planned rails)
                            sidebarToggleItem(
                                id: "planned",
                                title: "Pre-planned",
                                color: Color(red: 139/255, green: 92/255, blue: 246/255) // Purple
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Divider()
                .background(Theme.border)
                .padding(.horizontal, 14)
            
            // 3. Mini Month Calendar (Matching macOS Calendar style with faded boundary days)
            VStack(alignment: .leading, spacing: 8) {
                // Month Header (< Month Year >)
                HStack {
                    Button(action: { changeMiniMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(miniCalendarTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { changeMiniMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                
                // Days of week header (S M T W T F S)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { idx in
                        Text(daysOfWeek[idx])
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Mini Calendar 6-Week Days Grid (with faded boundary days)
                let days = generateDaysInMiniMonth(for: miniCalendarMonth)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 3) {
                    ForEach(days, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(day)
                        let isCurrentMonth = Calendar.current.isDate(day, equalTo: miniCalendarMonth, toGranularity: .month)
                        let dayNum = Calendar.current.component(.day, from: day)
                        
                        Button(action: {
                            selectedDate = day
                        }) {
                            Text("\(dayNum)")
                                .font(.system(size: 10, weight: isSelected || isToday ? .bold : (isCurrentMonth ? .semibold : .regular)))
                                .foregroundColor(
                                    isSelected ? Color.white :
                                    (isToday ? Color.white :
                                    (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.35)))
                                )
                                .frame(width: 20, height: 20)
                                .background(
                                    ZStack {
                                        if isToday {
                                            // Red circle highlight for today as seen in user's Apple Calendar screenshot!
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
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 210)
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
    
    // MARK: - Toggle Item (Can be checked/unchecked repeatedly)
    private func sidebarToggleItem(
        id: String,
        title: String,
        color: Color
    ) -> some View {
        let isChecked = calendarManager.isCalendarVisible(id: id)
        
        return Button(action: {
            calendarManager.toggleCalendarVisibility(id: id)
        }) {
            HStack(spacing: 8) {
                // Square check box matching Apple Calendar screenshot
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
    
    // Generate full 6-week (42 days) view so boundary days complete the week perfectly
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
