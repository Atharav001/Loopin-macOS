import SwiftUI

public struct SidebarView: View {
    @ObservedObject var appState: AppState = .shared
    @Binding var isPinnedOnTop: Bool
    var onTogglePin: (() -> Void)?
    var onNewEntry: (() -> Void)?
    
    @State private var hoveredTab: NavigationTab?
    
    public init(
        isPinnedOnTop: Binding<Bool>,
        onTogglePin: (() -> Void)? = nil,
        onNewEntry: (() -> Void)? = nil
    ) {
        self._isPinnedOnTop = isPinnedOnTop
        self.onTogglePin = onTogglePin
        self.onNewEntry = onNewEntry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Top Traffic Light Header Area with Window Dragging
            ZStack(alignment: .leading) {
                WindowDragArea()
                
                HStack(spacing: 8) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.accent)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Logtrackin")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .tracking(0.3)
                        
                        Text("Workspace")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .padding(.leading, 78) // Generous offset for macOS traffic lights
            }
            .frame(height: 52)
            
            // Workspace / Profile Quick Pill
            Button(action: {
                appState.selectedTab = .account
            }) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(appState.isSignedInWithGoogle ? Theme.productive : Theme.accent)
                        .frame(width: 7, height: 7)
                    
                    Text(appState.isSignedInWithGoogle ? appState.googleUserName : "Personal Workspace")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 2)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            
            // 2. Quick "+ New Entry" Action Button
            Button(action: {
                onNewEntry?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New Entry")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text("⌘N")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Theme.accent.opacity(0.3), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 16)
            
            // 3. Navigation Items & Calendar Accounts (Scrollable when window height is compact)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MAIN VIEWS")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    sidebarButton(for: .calendar)
                    
                    if appState.selectedTab == .calendar {
                        calendarAccountsSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    sidebarButton(for: .weekCalendar)
                    sidebarButton(for: .rails)
                    sidebarButton(for: .analytics)
                    sidebarButton(for: .dictionary)
                    sidebarButton(for: .focusPrompts)
                    sidebarButton(for: .account)
                    
                    Divider()
                        .background(Theme.border)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    
                    Text("PREFERENCES")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    sidebarButton(for: .settings)
                    
                    // Mini Calendar when on Calendar Tab
                    if appState.selectedTab == .calendar {
                        sidebarMiniCalendar
                            .padding(.horizontal, 10)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                            .transition(.opacity)
                    }
                }
            }
            
            Spacer(minLength: 4)
            
            // 4. Bottom Footer: Live Interval Status, Dropdown Theme Switcher & Window Pin
            VStack(spacing: 8) {
                // Quick Theme Dropdown Switcher
                ThemeDropdownPicker(compact: true)
                
                // Live Interval Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 7, height: 7)
                        Text(appState.selectedIntervalMinutes == 60 ? "1-Hour Interval" : "\(appState.selectedIntervalMinutes)m Interval")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text(appState.formattedCountdown)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentLight)
                    }
                    
                    Button(action: {
                        appState.showFloatingLoggingPanel = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10))
                            Text("Log Interval Now")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundColor(Theme.accentLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.5)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.border, lineWidth: 1)
                )
                
                // Pin on top toggle
                HStack {
                    Button(action: {
                        onTogglePin?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isPinnedOnTop ? "pin.fill" : "pin")
                                .font(.system(size: 11))
                                .foregroundColor(isPinnedOnTop ? Theme.accentLight : Theme.textSecondary)
                            Text(isPinnedOnTop ? "Pinned on Top" : "Pin on Top")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isPinnedOnTop ? Theme.textPrimary : Theme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)
            }
            .padding(12)
        }
        .frame(width: 220)
        .background(Theme.bgDark)
        .overlay(
            Rectangle()
                .fill(Theme.border)
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private func sidebarButton(for tab: NavigationTab) -> some View {
        let isSelected = appState.selectedTab == tab
        let isHovered = hoveredTab == tab
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appState.selectedTab = tab
            }
        }) {
            HStack(spacing: 9) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.accentLight : (isHovered ? Theme.textPrimary : Theme.textSecondary))
                    .frame(width: 18)
                
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Theme.textPrimary : (isHovered ? Theme.textPrimary : Theme.textSecondary))
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.accent.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Theme.bgSubtle)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .onHover { hovering in
            hoveredTab = hovering ? tab : nil
        }
    }
    
    // MARK: - Apple Calendar Style Accounts Section
    private var calendarAccountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Group 1: Google
            VStack(alignment: .leading, spacing: 4) {
                Text("Google")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 16)
                
                calendarToggleRow(
                    id: "google",
                    title: appState.googleUserEmail.isEmpty ? "atharavnarang05@gmail.com" : appState.googleUserEmail,
                    color: Color(red: 79/255, green: 170/255, blue: 189/255)
                )
                
                calendarToggleRow(
                    id: "holidays_india",
                    title: "Holidays in India",
                    color: Color(red: 52/255, green: 168/255, blue: 83/255)
                )
            }
            
            // Group 2: Loopin
            VStack(alignment: .leading, spacing: 4) {
                Text("Loopin")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 16)
                
                calendarToggleRow(
                    id: "logged",
                    title: "Log Sheet",
                    color: Color(red: 16/255, green: 185/255, blue: 129/255)
                )
                
                calendarToggleRow(
                    id: "planned",
                    title: "Pre-planned",
                    color: Color(red: 139/255, green: 92/255, blue: 246/255)
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    private func calendarToggleRow(id: String, title: String, color: Color) -> some View {
        let isChecked = CalendarManager.shared.isCalendarVisible(id: id)
        
        return Button(action: {
            CalendarManager.shared.toggleCalendarVisibility(id: id)
        }) {
            HStack(spacing: 8) {
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
                    .font(.system(size: 11, weight: isChecked ? .medium : .regular))
                    .foregroundColor(isChecked ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Mini Calendar in Sidebar
    private var sidebarMiniCalendar: some View {
        let cal = Calendar.current
        let monthDate = appState.calendarSelectedDate
        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
        
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        let monthTitle = f.string(from: monthDate)
        
        return VStack(alignment: .leading, spacing: 6) {
            // Month Header (< Month Year >)
            HStack {
                Button(action: {
                    var comps = cal.dateComponents([.year, .month], from: appState.calendarSelectedDate)
                    comps.day = 1
                    if let first = cal.date(from: comps),
                       let prev = cal.date(byAdding: .month, value: -1, to: first) {
                        appState.calendarSelectedDate = prev
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    var comps = cal.dateComponents([.year, .month], from: appState.calendarSelectedDate)
                    comps.day = 1
                    if let first = cal.date(from: comps),
                       let next = cal.date(byAdding: .month, value: 1, to: first) {
                        appState.calendarSelectedDate = next
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Days of Week Header (S M T W T F S)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    Text(daysOfWeek[idx])
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid (6 Weeks with faded boundary days)
            let days = generateMiniDays(for: monthDate)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { day in
                    let isSelected = cal.isDate(day, inSameDayAs: appState.calendarSelectedDate)
                    let isToday = cal.isDateInToday(day)
                    let isCurrentMonth = cal.isDate(day, equalTo: monthDate, toGranularity: .month)
                    let dayNum = cal.component(.day, from: day)
                    
                    Button(action: {
                        appState.calendarSelectedDate = day
                    }) {
                        Text("\(dayNum)")
                            .font(.system(size: 9.5, weight: isSelected || isToday ? .bold : (isCurrentMonth ? .semibold : .regular)))
                            .foregroundColor(
                                isToday ? Color.white :
                                (isSelected ? Color.white :
                                (isCurrentMonth ? Theme.textPrimary : Theme.textMuted.opacity(0.35)))
                            )
                            .frame(width: 19, height: 19)
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
        .padding(8)
        .background(Theme.bgSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func generateMiniDays(for date: Date) -> [Date] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: date) else { return [] }
        let startOfMonth = monthInterval.start
        let weekday = cal.component(.weekday, from: startOfMonth)
        let daysToPrepend = weekday - 1
        let firstCalendarDay = cal.date(byAdding: .day, value: -daysToPrepend, to: startOfMonth) ?? startOfMonth
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: firstCalendarDay) }
    }
}
