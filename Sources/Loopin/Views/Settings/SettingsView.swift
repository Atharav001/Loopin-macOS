import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var totalEntriesCount: Int = 0
    @State private var showExportSuccess: Bool = false
    @State private var exportMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Text("Settings & Preferences")
                            .font(Theme.titleLarge)
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text("Customize appearance, tracking intervals, focus tools, and data integrations.")
                        .font(Theme.body)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.bottom, 6)
                
                // 1. Theme & Appearance
                themeSection
                
                // 2. Time & Display Options
                displaySection
                
                // 3. 1-Hour Interval Prompt Window Settings
                intervalSection
                
                // 4. Focus & Pomodoro Settings
                pomodoroSection
                
                // 5. Quiet Hours / Do Not Disturb
                quietHoursSection
                
                // 6. Data Management & Export
                dataSection
            }
            .padding(28)
            .frame(maxWidth: 820)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bgDeep)
        .onAppear {
            loadStats()
        }
    }
    
    // MARK: - 1. Theme Selector
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Appearance & Themes", icon: "paintbrush.fill", subtitle: "Select from 6 Clockify, TickTick, and Neutral color schemes")
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    themeCard(theme)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    private func themeCard(_ theme: AppTheme) -> some View {
        let isSelected = appState.currentTheme == theme
        let isDark = appState.currentTheme.isDark
        
        let cardBg: Color = {
            if isSelected {
                return Theme.accent.opacity(isDark ? 0.22 : 0.08)
            } else {
                return isDark ? Color(red: 24/255, green: 32/255, blue: 47/255) : Color(red: 246/255, green: 248/255, blue: 250/255)
            }
        }()
        
        let cardBorder: Color = {
            if isSelected {
                return Theme.accent
            } else {
                return isDark ? Theme.border : Color.black.opacity(0.08)
            }
        }()
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.currentTheme = theme
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Swatches preview
                HStack(spacing: 6) {
                    Circle()
                        .fill(previewAccent(for: theme))
                        .frame(width: 14, height: 14)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(previewBg(for: theme))
                        .frame(height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? (isDark ? Theme.accentLight : Theme.accent) : Theme.textPrimary)
                    
                    Text(theme.description)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func previewAccent(for theme: AppTheme) -> Color {
        switch theme {
        case .clockifyDark, .clockifyLight: return Color(red: 2/255, green: 136/255, blue: 235/255)
        case .tickTickDark, .tickTickLight: return Color(red: 59/255, green: 104/255, blue: 255/255)
        case .systemDark, .standardLight: return Color(red: 26/255, green: 115/255, blue: 232/255)
        }
    }
    
    private func previewBg(for theme: AppTheme) -> Color {
        switch theme {
        case .clockifyDark: return Color(red: 11/255, green: 15/255, blue: 25/255)
        case .clockifyLight: return Color(red: 244/255, green: 245/255, blue: 247/255)
        case .tickTickDark: return Color(red: 30/255, green: 32/255, blue: 34/255)
        case .tickTickLight: return Color(red: 246/255, green: 247/255, blue: 249/255)
        case .systemDark: return Color(red: 18/255, green: 18/255, blue: 18/255)
        case .standardLight: return Color(red: 255/255, green: 255/255, blue: 255/255)
        }
    }
    
    // MARK: - 2. Time & Display Options
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Time & Display", icon: "clock.fill", subtitle: "Clock format and calendar layout rules")
            
            VStack(spacing: 12) {
                // 12h vs 24h Clock
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clock Time Format")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Choose between 12-hour (AM/PM) and 24-hour military clock display")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Picker("", selection: $appState.use24HourClock) {
                        Text("12-Hour (AM/PM)").tag(false)
                        Text("24-Hour (00:00)").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
                
                Divider().background(Theme.border)
                
                // Week starts on
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Week Starts On")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("First day of the week in calendar and weekly timeline columns")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Picker("", selection: $appState.weekStartsOnMonday) {
                        Text("Monday").tag(true)
                        Text("Sunday").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - 3. Interval Prompt Window Settings
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Interval Prompt Window (Clockify Core)", icon: "bell.badge.fill", subtitle: "Periodic prompt window reminding you to log your tasks")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prompt Interval Frequency")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Default interval for logging activity prompts. Currently set to 1 hour.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach([15, 30, 45, 60], id: \.self) { mins in
                            let isSel = appState.selectedIntervalMinutes == mins
                            Button(action: {
                                appState.setIntervalMinutes(mins)
                            }) {
                                Text(mins == 60 ? "1 Hour" : "\(mins)m")
                                    .font(.system(size: 11, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isSel ? Theme.accent : Theme.bgSubtle)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Theme.border)
                
                Toggle(isOn: $appState.intervalPromptFloatOverAllSpaces) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Float Over Full-Screen Apps & Spaces")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Ensures the prompt appears above full-screen editors and browsers without dismissal")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                
                Divider().background(Theme.border)
                
                Toggle(isOn: $appState.soundEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound Effects & Chimes")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Play gentle acoustic chime when interval triggers and when task is completed")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - 4. Focus & Pomodoro Settings
    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Focus & Pomodoro Timer (TickTick Core)", icon: "timer", subtitle: "Configurable work sprints, rest intervals, and auto-break transitions")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pomodoro Work Duration")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Default: 25 minutes")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Stepper("\(appState.pomodoroDurationMinutes) mins", value: $appState.pomodoroDurationMinutes, in: 5...90, step: 5)
                        .frame(width: 150)
                }
                
                Divider().background(Theme.border)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Short Break Duration")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Default: 5 minutes")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    Stepper("\(appState.pomodoroBreakMinutes) mins", value: $appState.pomodoroBreakMinutes, in: 1...30, step: 1)
                        .frame(width: 150)
                }
                
                Divider().background(Theme.border)
                
                Toggle(isOn: $appState.autoStartBreaks) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Start Break Timers")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Automatically transition into break mode when a work sprint concludes")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - 5. Quiet Hours
    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Quiet Hours / Do Not Disturb", icon: "moon.fill", subtitle: "Mute interval prompt popups during sleep and focus blocks")
            
            VStack(spacing: 12) {
                Toggle(isOn: $appState.quietHoursEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Quiet Hours")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Silences the 1-hour interval prompt during your scheduled quiet hours")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                
                if appState.quietHoursEnabled {
                    Divider().background(Theme.border)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quiet Hours Start")
                                .font(Theme.caption)
                                .foregroundColor(Theme.textSecondary)
                            DatePicker("", selection: $appState.quietHoursStart, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quiet Hours End")
                                .font(Theme.caption)
                                .foregroundColor(Theme.textSecondary)
                            DatePicker("", selection: $appState.quietHoursEnd, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - 6. Data Management & Export
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Data Management & Export", icon: "internaldrive.fill", subtitle: "Offline SQLite database and export capabilities")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Logged Entries")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(totalEntriesCount) activities stored in local SQLite database")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        exportToJSON()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export JSON")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accentLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        exportToCSV()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.text")
                            Text("Export CSV")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accentLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                
                if showExportSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.productive)
                        Text(exportMessage)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.productive)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.productiveBg)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
    
    private func loadStats() {
        let entries = DatabaseManager.shared.fetchForDay(Date())
        totalEntriesCount = entries.count
    }
    
    private func exportToJSON() {
        let entries = DatabaseManager.shared.fetchForDay(Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(entries),
           let jsonString = String(data: data, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(jsonString, forType: .string)
            exportMessage = "Copied JSON export of \(entries.count) entries to clipboard!"
            showExportSuccess = true
        }
    }
    
    private func exportToCSV() {
        let entries = DatabaseManager.shared.fetchForDay(Date())
        var csv = "ID,Kind,Start,End,DurationMinutes,Title,Category,Productivity\n"
        for e in entries {
            csv += "\(e.id),\(e.kind),\(e.startAt),\(e.endAt),\(e.durationMinutes),\"\(e.rawText)\",\"\(e.category ?? "")\",\(e.productivity ?? "")\n"
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(csv, forType: .string)
        exportMessage = "Copied CSV export of \(entries.count) entries to clipboard!"
        showExportSuccess = true
    }
}
