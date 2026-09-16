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
                
                // 1. User Profile & Real Google Connection Card
                userProfileCard
                
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
        .sheet(isPresented: $showGoogleAuthSheet) {
            googleAuthSheetView
        }
        .sheet(isPresented: $showSetupGuideSheet) {
            GoogleSetupGuideSheetView(onClose: { showSetupGuideSheet = false })
        }
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
                
                // Real OAuth Status Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(connectionStatusColor)
                        .frame(width: 7, height: 7)
                    Text(connectionStatusText)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(connectionStatusColor)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Sign In / Sign Out Button
            if appState.isSignedInWithGoogle {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        authService.disconnect()
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
                
                // Info Button ("i" button requested by user for setup guide)
                Button(action: {
                    showSetupGuideSheet = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("Setup Guide")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Theme.accentLight)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("View Google Cloud Console OAuth setup instructions")
                
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
