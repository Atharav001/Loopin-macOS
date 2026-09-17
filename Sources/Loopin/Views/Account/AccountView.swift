import SwiftUI

public struct AccountView: View {
    @ObservedObject var appState: AppState = .shared
    @ObservedObject var gcalConfig: GoogleCalendarConfig = .shared
    @ObservedObject var gcalService: GoogleCalendarService = .shared
    @ObservedObject var authService: GoogleAuthService = .shared
    
    @State private var isSyncingNow: Bool = false
    @State private var syncStatusMessage: String?
    @State private var showGoogleAuthSheet: Bool = false
    @State private var showSetupGuideSheet: Bool = false
    @State private var enteredOAuthToken: String = ""
    @State private var enteredClientId: String = ""
    @State private var isVerifyingToken: Bool = false
    @State private var verificationError: String?
    @State private var copyTokenFeedback: Bool = false
    
    // Tocklog Features & History State
    @State private var allEntries: [TimesheetEntry] = []
    @State private var showHistorySheet: Bool = false
    @State private var streakCopyFeedback: Bool = false
    @State private var hoveredCellInfo: String? = nil
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 22) {
                // Tocklog Profile Hero Header & 3-KPI Cards
                tocklogHeroProfileSection
                
                // Tocklog 12-Week Activity Heatmap Grid
                tocklogActivity12WeeksCard
                
                // Tocklog Share Progress & Upgrade Cards
                HStack(spacing: 16) {
                    tocklogShareProgressCard
                    tocklogUpgradePlanCard
                }
                
                // Tocklog Account Navigation (Settings, History)
                tocklogAccountNavCard
                
                Divider()
                    .padding(.vertical, 4)
                
                // Cloud Workspace & Google Sync Section Header
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.accentLight)
                        Text("CLOUD WORKSPACE & SYNC")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(Theme.textMuted)
                    }
                    Text("2-way Google Calendar synchronization and cross-device mobile pairing.")
                        .font(.system(size: 11.5))
                        .foregroundColor(Theme.textSecondary)
                }
                
                // 2. Google Calendar 2-Way Sync Engine Card (with "i" Setup Guide button)
                googleCalendarCard
                
                // 3. Mobile Client & Cloud Sync Card
                mobileSyncCard
            }
            .padding(28)
            .frame(maxWidth: 860)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bgDeep)
        .onAppear {
            loadAllEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: DatabaseManager.didChangeNotification)) { _ in
            loadAllEntries()
        }
        .sheet(isPresented: $showHistorySheet) {
            HistorySheetView(onClose: { showHistorySheet = false })
        }
        .sheet(isPresented: $showGoogleAuthSheet) {
            googleAuthSheetView
        }
        .sheet(isPresented: $showSetupGuideSheet) {
            GoogleSetupGuideSheetView(onClose: { showSetupGuideSheet = false })
        }
    }
    
    // MARK: - 1. Tocklog Mobile Profile & Activity Suite
    private var totalSessionsCount: Int {
        allEntries.filter { $0.kind == EntryKind.logged.rawValue }.count
    }
    
    private var totalFocusHoursCount: Double {
        let mins = allEntries.filter { $0.kind == EntryKind.logged.rawValue && $0.productivity == "productive" }.reduce(0) { $0 + $1.durationMinutes }
        return Double(mins) / 60.0
    }
    
    private var currentStreakCount: Int {
        computeStreak(entries: allEntries)
    }
    
    private var tocklogHeroProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("PROFILE")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.0)
                .foregroundColor(Theme.textMuted)
            
            // User identity row
            HStack(spacing: 16) {
                // Large Avatar Circle with initial
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                        .frame(width: 58, height: 58)
                    
                    Text(String(appState.googleUserName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.googleUserName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .tracking(1.0)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(appState.googleUserEmail)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                    
                    Text("FREE")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Sign In / Sign Out button
                if appState.isSignedInWithGoogle {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            authService.disconnect()
                            syncStatusMessage = "Signed out."
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.bgSubtle)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        showGoogleAuthSheet = true
                    }) {
                        HStack(spacing: 6) {
                            googleLogoIcon
                            Text("Connect Google")
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6.5)
                        .background(Color(red: 26/255, green: 115/255, blue: 232/255))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 2)
            
            // 3 KPI Metrics Row (SESSIONS | FOCUS HRS | STREAK)
            HStack(spacing: 16) {
                tocklogMetricPill(value: "\(totalSessionsCount)", label: "SESSIONS")
                
                Rectangle()
                    .fill(Theme.border.opacity(0.5))
                    .frame(width: 1, height: 32)
                
                tocklogMetricPill(value: String(format: "%.1f", totalFocusHoursCount), label: "FOCUS HRS")
                
                Rectangle()
                    .fill(Theme.border.opacity(0.5))
                    .frame(width: 1, height: 32)
                
                HStack(spacing: 4) {
                    VStack(spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 255/255, green: 87/255, blue: 34/255))
                            Text(currentStreakCount > 0 ? "\(currentStreakCount)" : "—")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        HStack(spacing: 3) {
                            Text("STREAK")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.0)
                                .foregroundColor(Theme.textMuted)
                            Image(systemName: "info.circle")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.textMuted.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Theme.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
        }
    }
    
    private func tocklogMetricPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.0)
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 12-Week Activity Heatmap Card
    private var tocklogActivity12WeeksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVITY")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textPrimary)
                Text("12 WEEKS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundColor(Theme.textMuted)
                
                Spacer()
                
                if let info = hoveredCellInfo {
                    Text(info)
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.accentLight)
                        .transition(.opacity)
                }
            }
            
            // Month labels row
            HStack(spacing: 0) {
                Spacer().frame(width: 18) // space for weekday labels
                let months = computeMonthLabels()
                HStack {
                    ForEach(months, id: \.title) { item in
                        Text(item.title)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(Theme.textMuted)
                        Spacer()
                    }
                }
            }
            
            // Grid of 7 rows (M, T, W, T, F, S, S) by 12 columns
            let grid = compute12WeeksGrid(entries: allEntries)
            let dayNames = ["M", "T", "W", "T", "F", "S", "S"]
            
            VStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { dayIdx in
                    HStack(spacing: 4) {
                        Text(dayNames[dayIdx])
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                            .frame(width: 14, alignment: .leading)
                        
                        ForEach(0..<12, id: \.self) { weekIdx in
                            let cell = grid[weekIdx][dayIdx]
                            heatmapSquare(cell: cell)
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("LESS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Theme.textMuted)
                
                heatmapLegendSquare(level: 0)
                heatmapLegendSquare(level: 1)
                heatmapLegendSquare(level: 2)
                heatmapLegendSquare(level: 3)
                heatmapLegendSquare(level: 4)
                
                Text("MORE")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    // MARK: - Share Progress & Upgrade Plan Cards
    private var tocklogShareProgressCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("SHARE YOUR PROGRESS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(Theme.textPrimary)
                Text(streakCopyFeedback ? "Copied streak to clipboard!" : "Post your streak to social media.")
                    .font(.system(size: 10.5))
                    .foregroundColor(streakCopyFeedback ? Theme.productive : Theme.textMuted)
            }
            
            Spacer()
            
            Button(action: {
                copyStreakToClipboard()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 255/255, green: 87/255, blue: 34/255))
                    Text(currentStreakCount > 0 ? "\(currentStreakCount)d" : "—")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
    }
    
    private var tocklogUpgradePlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("UPGRADE YOUR PLAN")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(Theme.textPrimary)
                Text("Unlock AI analysis, cloud sync and advanced history.")
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textMuted)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
    }
    
    // MARK: - Account Navigation Card
    private var tocklogAccountNavCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCOUNT")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textMuted)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                Button(action: {
                    appState.selectedTab = .settings
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SETTINGS")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.textPrimary)
                            Text("Notifications, interval, work hours")
                                .font(.system(size: 10.5))
                                .foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(14)
                    .background(Theme.bgCard)
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(Theme.border)
                
                Button(action: {
                    showHistorySheet = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HISTORY")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.textPrimary)
                            Text("Browse past sessions")
                                .font(.system(size: 10.5))
                                .foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(14)
                    .background(Theme.bgCard)
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
        }
    }
    
    private var connectionStatusColor: Color {
        if gcalConfig.isConnected {
            return Theme.productive
        } else if appState.isSignedInWithGoogle {
            return Theme.planned
        } else {
            return Theme.textMuted
        }
    }
    
    private var connectionStatusText: String {
        if gcalConfig.isConnected {
            return "Connected & Authorized with Google Calendar API"
        } else if appState.isSignedInWithGoogle {
            return "Local Profile Connected (OAuth Token Needed for Cloud Sync)"
        } else {
            return "Offline Local Mode (Not Connected)"
        }
    }
    
    // MARK: - 2. Google Calendar 2-Way Sync Engine Card
    private var googleCalendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 26/255, green: 115/255, blue: 232/255))
                    Text("Google Calendar 2-Way Synchronization")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                // Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.googleCalendarSyncEnabled ? Theme.productive : Theme.textMuted)
                        .frame(width: 7, height: 7)
                    Text(appState.googleCalendarSyncEnabled ? "Auto-Sync ON" : "Sync Paused")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(appState.googleCalendarSyncEnabled ? Theme.productive : Theme.textMuted)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(appState.googleCalendarSyncEnabled ? Theme.productiveBg : Theme.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text("Automatically creates and synchronizes two dedicated Google Calendars: 'Loopin Planned' for scheduled timeblocks and 'Loopin Logged' for completed timesheets. Displays seamlessly on your phone's native Google Calendar widget.")
                .font(Theme.body)
                .foregroundColor(Theme.textSecondary)
            
            // Dedicated Calendars List
            HStack(spacing: 12) {
                calendarChannelCard(
                    title: "Loopin Planned",
                    subtitle: "Upcoming scheduled focus tasks",
                    color: Theme.planned,
                    icon: "calendar.badge.plus"
                )
                
                calendarChannelCard(
                    title: "Loopin Logged",
                    subtitle: "Recorded timesheets & focus intervals",
                    color: Theme.productive,
                    icon: "calendar.badge.checkmark"
                )
            }
            
            Divider().background(Theme.border)
            
            // Controls & Sync Action
            HStack {
                Toggle(isOn: $appState.googleCalendarSyncEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Real-Time Calendar Sync")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        Text("Push changes immediately when adding or editing blocks")
                            .font(.system(size: 10.5))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                
                Spacer()
                
                Button(action: {
                    triggerManualSync()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isSyncingNow ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(isSyncingNow ? 360 : 0))
                            .animation(isSyncingNow ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncingNow)
                        Text(isSyncingNow ? "Syncing..." : "Sync Now")
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Theme.accentLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Theme.accent.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSyncingNow)
            }
            
            if let msg = syncStatusMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.productive)
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.productive)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.productiveBg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 14)
    }
    
    private func calendarChannelCard(title: String, subtitle: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.bgSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    // MARK: - 3. Mobile Client & Cloud Sync Card
    private var mobileSyncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accentLight)
                    Text("Android Mobile Client & Real-Time Cloud Sync")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
            }
            
            Text("Pair your Android mobile client with this Mac. All planned and logged timesheet blocks automatically replicate across devices via the cloud sync engine.")
                .font(Theme.body)
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Device ID")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                    Text("macOS-desktop-\(Host.current().localizedName ?? "primary")")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("loopin-cloud-sync-key-mac-\(UUID().uuidString.prefix(8))", forType: .string)
                    copyTokenFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        copyTokenFeedback = false
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: copyTokenFeedback ? "checkmark" : "doc.on.doc")
                        Text(copyTokenFeedback ? "Copied Pairing Key!" : "Copy Mobile Pairing Key")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(copyTokenFeedback ? Theme.productive : Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(copyTokenFeedback ? Theme.productiveBg : Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .glassCard(cornerRadius: 14)
    }
    
    // MARK: - Google Auth Modal Sheet
    private var googleAuthSheetView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    googleLogoIcon
                    Text("Connect with Google")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Button(action: { showGoogleAuthSheet = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.textMuted)
                        .padding(5)
                        .background(Theme.bgSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Theme.border)
            
            // Method 1: System Browser OAuth 2.0
            VStack(alignment: .leading, spacing: 8) {
                Text("METHOD 1: OFFICIAL GOOGLE OAUTH 2.0 (BROWSER)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentLight)
                
                Text("Open Google's official authorization page in Safari/Chrome to grant calendar permissions.")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Button(action: {
                    authService.openGoogleOAuthInBrowser(clientId: enteredClientId)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "safari")
                        Text("Open Google Sign-In in Browser")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 26/255, green: 115/255, blue: 232/255))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Method 2: Paste OAuth Access Token & Verify
            VStack(alignment: .leading, spacing: 8) {
                Text("METHOD 2: PASTE GOOGLE ACCESS TOKEN / OAUTH CODE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentLight)
                
                Text("Paste your OAuth access token (starts with ya29...) to directly authorize the Google Calendar API.")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("Paste OAuth Bearer Token (ya29...)", text: $enteredOAuthToken)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(8)
                    .background(Theme.bgDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                
                if let err = verificationError {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.wasteful)
                        Text(err)
                            .font(.system(size: 10.5))
                            .foregroundColor(Theme.wasteful)
                    }
                }
                
                Button(action: {
                    verifyAndConnectToken()
                }) {
                    HStack(spacing: 6) {
                        if isVerifyingToken {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                        }
                        Text(isVerifyingToken ? "Verifying with Google..." : "Verify & Connect with Google")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(enteredOAuthToken.isEmpty ? Theme.textMuted : Theme.productive)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(enteredOAuthToken.isEmpty || isVerifyingToken)
            }
            .padding(12)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Method 3: Offline Local Profile
            VStack(alignment: .leading, spacing: 6) {
                Text("METHOD 3: OFFLINE LOCAL PROFILE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                
                Text("Use Loopin entirely locally without Google Cloud credentials:")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 8) {
                    TextField("Display Name", text: $appState.googleUserName)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Theme.bgDark)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    
                    TextField("Email", text: $appState.googleUserEmail)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Theme.bgDark)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    
                    Button("Save Local") {
                        appState.isSignedInWithGoogle = true
                        showGoogleAuthSheet = false
                        syncStatusMessage = "Saved local offline profile."
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Theme.bgSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(24)
        .frame(width: 520)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.borderHighlight, lineWidth: 1))
    }
    
    private func verifyAndConnectToken() {
        isVerifyingToken = true
        verificationError = nil
        
        Task {
            let result = await authService.verifyTokenAndFetchProfile(token: enteredOAuthToken)
            isVerifyingToken = false
            switch result {
            case .success(let profile):
                showGoogleAuthSheet = false
                syncStatusMessage = "Verified! Connected as \(profile.name ?? profile.email ?? "Google User")."
            case .failure(let err):
                verificationError = err.localizedDescription
            }
        }
    }
    
    // MARK: - Helpers
    private var googleLogoIcon: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
            Text("G")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 26/255, green: 115/255, blue: 232/255))
        }
    }
    
    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AN"
    }
    
    private func triggerManualSync() {
        isSyncingNow = true
        syncStatusMessage = nil
        
        Task {
            await gcalService.syncAll()
            isSyncingNow = false
            appState.lastGoogleSyncDate = Date()
            syncStatusMessage = gcalService.statusMessage
        }
    }
    
    // MARK: - Activity Heatmap & Metrics Computation
    private func loadAllEntries() {
        allEntries = DatabaseManager.shared.fetchAllEntries()
    }
    
    private func computeStreak(entries: [TimesheetEntry]) -> Int {
        let logged = entries.filter { $0.kind == EntryKind.logged.rawValue && $0.productivity == "productive" }
        let calendar = Calendar.current
        var activeDates = Set<String>()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        for e in logged {
            activeDates.insert(fmt.string(from: e.startAt))
        }
        
        var streak = 0
        var checkDate = Date()
        let todayStr = fmt.string(from: checkDate)
        
        if !activeDates.contains(todayStr) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                let yestStr = fmt.string(from: yesterday)
                if activeDates.contains(yestStr) {
                    checkDate = yesterday
                } else {
                    return 0
                }
            } else {
                return 0
            }
        }
        
        while true {
            let str = fmt.string(from: checkDate)
            if activeDates.contains(str) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }
    
    private struct HeatmapDayCell: Identifiable {
        let id = UUID()
        let date: Date
        let dateString: String
        let minutes: Int
        let count: Int
        let level: Int
        let isToday: Bool
    }
    
    private func compute12WeeksGrid(entries: [TimesheetEntry]) -> [[HeatmapDayCell]] {
        let calendar = Calendar.current
        let today = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        
        var currentWeekMonday = today
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1) ? 6 : (weekday - 2)
        if let mon = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) {
            currentWeekMonday = mon
        }
        
        let startMonday = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekMonday) ?? currentWeekMonday
        
        var dailyMinutes: [String: Int] = [:]
        var dailyCount: [String: Int] = [:]
        for e in entries where e.kind == EntryKind.logged.rawValue && e.productivity == "productive" {
            let key = fmt.string(from: e.startAt)
            dailyMinutes[key, default: 0] += e.durationMinutes
            dailyCount[key, default: 0] += 1
        }
        
        var columns: [[HeatmapDayCell]] = []
        for week in 0..<12 {
            var weekDays: [HeatmapDayCell] = []
            for day in 0..<7 {
                let dayOffset = week * 7 + day
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startMonday) ?? startMonday
                let dateStr = fmt.string(from: date)
                let mins = dailyMinutes[dateStr] ?? 0
                let count = dailyCount[dateStr] ?? 0
                
                let level: Int
                if mins == 0 {
                    level = 0
                } else if mins < 60 {
                    level = 1
                } else if mins < 180 {
                    level = 2
                } else if mins < 300 {
                    level = 3
                } else {
                    level = 4
                }
                
                let isToday = calendar.isDateInToday(date)
                weekDays.append(HeatmapDayCell(date: date, dateString: dateStr, minutes: mins, count: count, level: level, isToday: isToday))
            }
            columns.append(weekDays)
        }
        return columns
    }
    
    private func computeMonthLabels() -> [(title: String, offset: CGFloat)] {
        let calendar = Calendar.current
        let today = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        
        let m1 = calendar.date(byAdding: .month, value: -2, to: today) ?? today
        let m2 = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        let m3 = today
        
        return [
            (title: fmt.string(from: m1).uppercased(), offset: 0),
            (title: fmt.string(from: m2).uppercased(), offset: 0),
            (title: fmt.string(from: m3).uppercased(), offset: 0)
        ]
    }
    
    private func heatmapSquare(cell: HeatmapDayCell) -> some View {
        let color: Color = {
            switch cell.level {
            case 1: return Theme.productive.opacity(0.35)
            case 2: return Theme.productive.opacity(0.60)
            case 3: return Theme.productive.opacity(0.85)
            case 4: return Color(red: 255/255, green: 87/255, blue: 34/255)
            default: return Color.white.opacity(0.06)
            }
        }()
        
        return RoundedRectangle(cornerRadius: 2.5)
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(cell.isToday ? Color.white : Color.white.opacity(0.1), lineWidth: cell.isToday ? 1.5 : 0.6)
            )
            .onHover { isHovered in
                if isHovered {
                    hoveredCellInfo = "\(cell.dateString): \(cell.minutes)m focus (\(cell.count) sessions)"
                } else {
                    if hoveredCellInfo?.contains(cell.dateString) == true {
                        hoveredCellInfo = nil
                    }
                }
            }
    }
    
    private func heatmapLegendSquare(level: Int) -> some View {
        let color: Color = {
            switch level {
            case 1: return Theme.productive.opacity(0.35)
            case 2: return Theme.productive.opacity(0.60)
            case 3: return Theme.productive.opacity(0.85)
            case 4: return Color(red: 255/255, green: 87/255, blue: 34/255)
            default: return Color.white.opacity(0.06)
            }
        }()
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
    }
    
    private func copyStreakToClipboard() {
        let text = "🔥 Loopin Streak: \(currentStreakCount) days! Tracked \(totalSessionsCount) sessions & \(String(format: "%.1f", totalFocusHoursCount)) hrs of deep focus. #Loopin #DeepWork"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        streakCopyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            streakCopyFeedback = false
        }
    }
}

// MARK: - Google Setup Guide Modal Sheet (Dedicated "i" Button Target)
public struct GoogleSetupGuideSheetView: View {
    var onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 18))
                    Text("Google Cloud OAuth Setup Guide")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.textMuted)
                        .padding(5)
                        .background(Theme.bgSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Theme.border)
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Follow these 4 steps in your Google Cloud Console to enable 2-way Google Calendar synchronization:")
                        .font(Theme.body)
                        .foregroundColor(Theme.textSecondary)
                    
                    guideStep(
                        step: "1",
                        title: "Create a Google Cloud Project",
                        desc: "Go to console.cloud.google.com and create a free project named 'Loopin macOS'.",
                        actionTitle: "Open Google Cloud Console",
                        urlStr: "https://console.cloud.google.com"
                    )
                    
                    guideStep(
                        step: "2",
                        title: "Enable Google Calendar API",
                        desc: "In APIs & Services > Library, search for 'Google Calendar API' and click 'Enable'.",
                        actionTitle: "Open Calendar API Library",
                        urlStr: "https://console.cloud.google.com/apis/library/calendar-json.googleapis.com"
                    )
                    
                    guideStep(
                        step: "3",
                        title: "Configure OAuth Consent Screen",
                        desc: "Select 'External' user type, add your own email under Test Users, and add the scope '../auth/calendar'.",
                        actionTitle: "Configure OAuth Consent",
                        urlStr: "https://console.cloud.google.com/apis/credentials/consent"
                    )
                    
                    guideStep(
                        step: "4",
                        title: "Create OAuth 2.0 Client ID (Desktop App)",
                        desc: "In Credentials > Create Credentials > OAuth client ID, choose 'Desktop app'. Copy the generated Client ID and secret into Loopin.",
                        actionTitle: "Open Credentials Dashboard",
                        urlStr: "https://console.cloud.google.com/apis/credentials"
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Google OAuth Scopes Required:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("• https://www.googleapis.com/auth/calendar (Full 2-way event read & write)\n• https://www.googleapis.com/auth/userinfo.email (User profile identification)\n• https://www.googleapis.com/auth/userinfo.profile (Display name & avatar)")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(10)
                    .background(Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 460)
            
            HStack {
                Spacer()
                Button("Done") {
                    onClose()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(width: 580)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.borderHighlight, lineWidth: 1))
    }
    
    private func guideStep(step: String, title: String, desc: String, actionTitle: String, urlStr: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Theme.accent)
                .clipShape(Circle())
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                
                Button(action: {
                    if let u = URL(string: urlStr) {
                        NSWorkspace.shared.open(u)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text(actionTitle)
                    }
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Theme.accentLight)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }
}
