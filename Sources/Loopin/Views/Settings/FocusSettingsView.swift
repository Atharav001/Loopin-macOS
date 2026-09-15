import SwiftUI

public struct FocusSettingsView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var showResetConfirmation: Bool = false
    @State private var feedbackMessage: String?
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Theme.accentLight)
                        Text("Focus & Prompts Settings")
                            .font(Theme.titleMedium)
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                }
                
                // Interval Prompt Section
                intervalPromptCard
                
                // Quiet Hours Section
                quietHoursCard
                
                // Pomodoro Focus Timer Section
                PomodoroView()
                
                // Cloud & Multi-Device Sync Section
                cloudSyncCard
                
                // Google Calendar 2-Way Sync Section
                googleCalendarCard
                
                // Sound & Feedback Section
                soundOptionsCard
                
                // Database & Storage Section
                databaseManagementCard
            }
            .padding(24)
        }
        .background(Theme.bgDeep)
    }
    
    // MARK: - Interval Prompt Card
    private var intervalPromptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(Theme.accentLight)
                    Text("Interval Logging Prompts")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text("Next prompt: \(appState.formattedCountdown)")
                    .font(Theme.monoBold)
                    .foregroundColor(Theme.accentLight)
            }
            
            Text("Loopin periodically surfaces a lightweight, floating prompt asking what you've been working on, without stealing your keyboard focus.")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                Text("Frequency:")
                    .font(Theme.bodyMedium)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 6) {
                    ForEach([5, 10, 15, 25], id: \.self) { mins in
                        let isSel = appState.selectedIntervalMinutes == mins
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                appState.setIntervalMinutes(mins)
                            }
                        }) {
                            Text("Every \(mins)m")
                                .font(Theme.caption)
                                .fontWeight(isSel ? .bold : .medium)
                                .foregroundColor(isSel ? .white : Theme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSel ? Theme.accent : Theme.bgSubtle)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSel ? Theme.accentLight : Theme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    appState.showFloatingLoggingPanel = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("Test Prompt")
                    }
                    .font(Theme.caption)
                    .foregroundColor(Theme.accentLight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Quiet Hours Card
    private var quietHoursCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(Theme.neutral)
                    Text("Quiet Hours")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                let isQuietNow = appState.quietHoursEnabled && appState.isWithinQuietHours(now: Date())
                HStack(spacing: 4) {
                    Circle()
                        .fill(isQuietNow ? Theme.neutral : Theme.productive)
                        .frame(width: 6, height: 6)
                    Text(isQuietNow ? "Currently Muting Prompts" : "Prompts Active")
                        .font(Theme.caption)
                        .foregroundColor(isQuietNow ? Theme.neutral : Theme.productive)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((isQuietNow ? Theme.neutral : Theme.productive).opacity(0.12))
                .cornerRadius(6)
                
                Toggle("", isOn: $appState.quietHoursEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            Text("During quiet hours, interval logging panels will not pop up. Supports overnight schedules (e.g. 22:00 to 07:00).")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
            
            if appState.quietHoursEnabled {
                HStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Text("From:")
                            .font(Theme.bodyMedium)
                            .foregroundColor(Theme.textSecondary)
                        DatePicker("", selection: $appState.quietHoursStart, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }
                    
                    HStack(spacing: 8) {
                        Text("To:")
                            .font(Theme.bodyMedium)
                            .foregroundColor(Theme.textSecondary)
                        DatePicker("", selection: $appState.quietHoursEnd, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Cloud Sync Card
    private var cloudSyncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(Theme.accentLight)
                    Text("Supabase Cloud & Multi-Device Sync")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(SyncEngine.shared.syncStatus == .unconfigured ? Color.gray : Theme.productive)
                        .frame(width: 7, height: 7)
                    Text(SyncEngine.shared.syncStatus.displayText)
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.bgDark)
                .cornerRadius(6)
            }
            
            Text("Syncs planned and logged timesheets across Mac, Android, and web with real-time PostgreSQL + RLS.")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Text("Project URL:")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("https://your-project.supabase.co", text: Binding(
                        get: { SupabaseConfig.shared.projectUrl },
                        set: { SupabaseConfig.shared.projectUrl = $0; SyncEngine.shared.checkConfiguration() }
                    ))
                    .textFieldStyle(.plain)
                    .font(Theme.body)
                    .padding(6)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
                
                HStack(spacing: 10) {
                    Text("Anon Key:")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    SecureField("Supabase anon/public API key", text: Binding(
                        get: { SupabaseConfig.shared.anonApiKey },
                        set: { SupabaseConfig.shared.anonApiKey = $0; SyncEngine.shared.checkConfiguration() }
                    ))
                    .textFieldStyle(.plain)
                    .font(Theme.body)
                    .padding(6)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
            }
            
            HStack(spacing: 16) {
                Toggle("Enable Background Auto-Sync", isOn: Binding(
                    get: { SupabaseConfig.shared.isAutoSyncEnabled },
                    set: { enabled in
                        SupabaseConfig.shared.isAutoSyncEnabled = enabled
                        if enabled {
                            SyncEngine.shared.startAutoSync()
                        } else {
                            SyncEngine.shared.stopAutoSync()
                        }
                    }
                ))
                .font(Theme.caption)
                .toggleStyle(.switch)
                
                Spacer()
                
                if SyncEngine.shared.pendingCount > 0 {
                    Text("\(SyncEngine.shared.pendingCount) pending")
                        .font(Theme.caption)
                        .foregroundColor(Theme.neutral)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.neutralBg)
                        .cornerRadius(4)
                }
                
                Button(action: {
                    Task {
                        await SyncEngine.shared.syncNow()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .font(Theme.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accent)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Google Calendar 2-Way Sync Card
    private var googleCalendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(Theme.productive)
                    Text("Google Calendar 2-Way Sync")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                let isConnected = GoogleCalendarConfig.shared.isConnected
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? Theme.productive : Color.gray)
                        .frame(width: 7, height: 7)
                    Text(isConnected ? "Connected to Google" : "Local / Offline")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.bgDark)
                .cornerRadius(6)
            }
            
            Text("Syncs your planned and logged timesheets with two dedicated Google Calendars ('Loopin Planned' and 'Loopin Logged'). Your mobile Google Calendar widgets will automatically display everything you track!")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
            
            // Dedicated Calendars Preview Pills
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle().fill(Theme.planned).frame(width: 8, height: 8)
                    Text("Loopin Planned")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.plannedBg)
                .cornerRadius(6)
                
                HStack(spacing: 6) {
                    Circle().fill(Theme.productive).frame(width: 8, height: 8)
                    Text("Loopin Logged")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.productiveBg)
                .cornerRadius(6)
                
                Spacer()
            }
            
            // Credentials & Actions
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Text("Client ID:")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    TextField("Google OAuth Client ID", text: Binding(
                        get: { GoogleCalendarConfig.shared.clientId },
                        set: { GoogleCalendarConfig.shared.clientId = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(Theme.body)
                    .padding(6)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
                
                HStack(spacing: 10) {
                    Text("Client Secret:")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    
                    SecureField("Google OAuth Client Secret", text: Binding(
                        get: { GoogleCalendarConfig.shared.clientSecret },
                        set: { GoogleCalendarConfig.shared.clientSecret = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(Theme.body)
                    .padding(6)
                    .background(Theme.bgDark)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
            }
            
            HStack(spacing: 12) {
                if GoogleCalendarConfig.shared.isConnected {
                    Button(action: {
                        GoogleCalendarConfig.shared.disconnect()
                    }) {
                        Text("Disconnect")
                            .font(Theme.caption)
                            .foregroundColor(Theme.wasteful)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.wastefulBg)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        // Simulated connection for testing
                        GoogleCalendarConfig.shared.accessToken = "mock_gcal_token_\(UUID().uuidString.prefix(8))"
                        GoogleCalendarConfig.shared.plannedCalendarId = "loopin_planned_cal_id"
                        GoogleCalendarConfig.shared.loggedCalendarId = "loopin_logged_cal_id"
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                            Text("Connect Google Calendar")
                        }
                        .font(Theme.caption)
                        .foregroundColor(Theme.accentLight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await GoogleCalendarService.shared.syncAll()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Calendars")
                    }
                    .font(Theme.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.productive)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            if !GoogleCalendarService.shared.statusMessage.isEmpty {
                Text(GoogleCalendarService.shared.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Sound Options Card
    private var soundOptionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Theme.accentLight)
                    Text("Sound & Notifications")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Toggle("", isOn: $appState.soundEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            Text("Play subtle system sound cues when prompts fire or Pomodoro timers complete.")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Database Management Card
    private var databaseManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cylinder.split.1x2.fill")
                        .foregroundColor(Theme.textSecondary)
                    Text("Local SQLite Storage")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text("Zero Cloud • 100% On-Device")
                    .font(Theme.caption)
                    .foregroundColor(Theme.productive)
            }
            
            Text("Your data is stored locally in ~/Library/Application Support/Loopin/loopin.sqlite with typed SQLite schema.")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                Button(action: {
                    SampleDataSeeder.seedSampleEntries()
                    feedbackMessage = "Sample entries seeded successfully!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { feedbackMessage = nil }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Seed Demo Entries")
                    }
                    .font(Theme.caption)
                    .foregroundColor(Theme.accentLight)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear All Data")
                    }
                    .font(Theme.caption)
                    .foregroundColor(Theme.wasteful)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.wastefulBg)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                if let msg = feedbackMessage {
                    Text(msg)
                        .font(Theme.caption)
                        .foregroundColor(Theme.productive)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
        .confirmationDialog("Are you sure you want to clear all data?", isPresented: $showResetConfirmation) {
            Button("Clear All Data", role: .destructive) {
                DatabaseManager.shared.clearAllData()
                SampleDataSeeder.seedDefaultRulesIfNeeded()
            }
        } message: {
            Text("This will delete all timesheet entries and restore default classification rules.")
        }
    }
}
