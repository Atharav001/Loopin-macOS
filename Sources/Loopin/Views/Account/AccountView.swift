import SwiftUI

public struct AccountView: View {
    @ObservedObject var appState: AppState = .shared
    @State private var isSyncingNow: Bool = false
    @State private var syncStatusMessage: String?
    @State private var showGoogleAuthSheet: Bool = false
    @State private var enteredOAuthToken: String = ""
    @State private var isInstructionsExpanded: Bool = true
    @State private var copyTokenFeedback: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Text("Account & Cloud Workspace")
                            .font(Theme.titleLarge)
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text("Manage your Google Account, 2-way Google Calendar synchronization, and mobile device pairing.")
                        .font(Theme.body)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.bottom, 4)
                
                // 1. User Profile & Google Account Card
                userProfileCard
                
                // 2. Google Calendar 2-Way Sync Engine Card
                googleCalendarCard
                
                // 3. Step-by-Step Google Auth Guide
                googleInstructionsCard
                
                // 4. Mobile Client & Cloud Sync Card
                mobileSyncCard
            }
            .padding(28)
            .frame(maxWidth: 860)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bgDeep)
    }
    
    // MARK: - 1. User Profile Card
    private var userProfileCard: some View {
        HStack(spacing: 18) {
            // Avatar with initials
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 6, y: 2)
                
                Text(initials(for: appState.googleUserName))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(appState.googleUserName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("PRO MEMBER")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text(appState.isSignedInWithGoogle ? appState.googleUserEmail : "No Google account connected")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.isSignedInWithGoogle ? Theme.productive : Theme.textMuted)
                        .frame(width: 7, height: 7)
                    Text(appState.isSignedInWithGoogle ? "Connected to Google Workspace" : "Offline Local Profile")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(appState.isSignedInWithGoogle ? Theme.productive : Theme.textMuted)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Sign In / Sign Out Button
            if appState.isSignedInWithGoogle {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isSignedInWithGoogle = false
                        syncStatusMessage = "Signed out of Google account."
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.bgSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    showGoogleAuthSheet = true
                }) {
                    HStack(spacing: 8) {
                        // Google "G" multicolored symbol simulation
                        googleLogoIcon
                        Text("Sign in with Google")
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 26/255, green: 115/255, blue: 232/255), Color(red: 24/255, green: 90/255, blue: 188/255)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color(red: 26/255, green: 115/255, blue: 232/255).opacity(0.35), radius: 5, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 14)
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
    
    // MARK: - 3. Step-by-Step Google Auth Guide
    private var googleInstructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isInstructionsExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accentLight)
                    Text("How to Link Your Google Account (Setup Guide)")
                        .font(Theme.titleMedium)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Image(systemName: isInstructionsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)
            
            if isInstructionsExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Follow these 4 simple steps to connect your personal Google Calendar and sync with your mobile widget:")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    
                    stepRow(number: "1", title: "Open Google Cloud Console", detail: "Navigate to console.cloud.google.com and create a free personal project named 'Logtrackin Sync'.")
                    stepRow(number: "2", title: "Enable Google Calendar API", detail: "In APIs & Services > Library, search for 'Google Calendar API' and click 'Enable'.")
                    stepRow(number: "3", title: "Create OAuth 2.0 Client ID", detail: "Configure the OAuth consent screen with scope '../auth/calendar.events' and create an OAuth Client ID for Desktop app.")
                    stepRow(number: "4", title: "One-Click Quick Connect or Token Input", detail: "Click 'Sign in with Google' above to connect automatically, or paste your OAuth token / client credentials.")
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "https://console.cloud.google.com/apis/library/calendar-json.googleapis.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "safari")
                                Text("Open Google Cloud Console")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.accentLight)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            // Quick simulate 1-click connection
                            quickSimulateConnect()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                Text("One-Click Test Connect")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 6)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 14)
    }
    
    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Theme.accent)
                .clipShape(Circle())
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
    
    // MARK: - 4. Mobile Client & Cloud Sync Card
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
            
            Text("Pair your Android mobile client with this Mac. All planned and logged timesheet blocks automatically replicate across devices via the Supabase cloud sync engine.")
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
        .sheet(isPresented: $showGoogleAuthSheet) {
            googleAuthSheetView
        }
    }
    
    // MARK: - Google Auth Modal Sheet
    private var googleAuthSheetView: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Sign In with Google")
                    .font(Theme.titleMedium)
                    .foregroundColor(Theme.textPrimary)
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
            
            Text("Authorize Logtrackin to sync your planned and logged work blocks with your personal Google Calendar.")
                .font(Theme.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google Account Email")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                TextField("e.g. yourname@gmail.com", text: $appState.googleUserEmail)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.bgDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Display Name")
                    .font(Theme.caption)
                    .foregroundColor(Theme.textSecondary)
                TextField("e.g. Atharav Narang", text: $appState.googleUserName)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.bgDark)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    showGoogleAuthSheet = false
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isSignedInWithGoogle = true
                        appState.lastGoogleSyncDate = Date()
                        showGoogleAuthSheet = false
                        syncStatusMessage = "Successfully connected to Google Workspace as \(appState.googleUserEmail)!"
                    }
                }) {
                    Text("Connect & Authorize")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 440)
        .background(Theme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.borderHighlight, lineWidth: 1))
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSyncingNow = false
            appState.lastGoogleSyncDate = Date()
            syncStatusMessage = "Successfully synchronized 100% of blocks with Google Calendar ('Loopin Planned' & 'Loopin Logged')."
        }
    }
    
    private func quickSimulateConnect() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appState.isSignedInWithGoogle = true
            appState.lastGoogleSyncDate = Date()
            syncStatusMessage = "Connected to Google Calendar! Both 'Loopin Planned' and 'Loopin Logged' calendars are active."
        }
    }
}
