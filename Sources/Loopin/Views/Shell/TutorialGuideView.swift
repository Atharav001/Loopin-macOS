import SwiftUI
import AppKit

// MARK: - TutorialTab
public enum TutorialTab: String, CaseIterable, Identifiable {
    case appTutorial = "App Tutorial"
    case googleSync = "Google Sync Guide"
    case shortcuts = "Shortcuts"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .appTutorial: return "graduationcap.fill"
        case .googleSync: return "cloud.fill"
        case .shortcuts: return "command"
        }
    }
}

// MARK: - TutorialWindowController
@MainActor
public final class TutorialWindowController: NSObject, ObservableObject, NSWindowDelegate {
    public static let shared = TutorialWindowController()
    
    private var window: NSWindow?
    @Published public var activeTab: TutorialTab = .appTutorial
    
    public override init() {
        super.init()
    }
    
    public func show(tab: TutorialTab = .appTutorial) {
        self.activeTab = tab
        
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func close() {
        window?.orderOut(nil)
    }
    
    private func createWindow() {
        let hostingView = NSHostingView(
            rootView: TutorialGuideContainerView(
                controller: self,
                onClose: { [weak self] in
                    self?.close()
                }
            )
        )
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.title = "Logtrackin Tutorial & Guide"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.backgroundColor = NSColor(red: 12/255, green: 14/255, blue: 18/255, alpha: 1.0)
        win.isOpaque = true
        win.hasShadow = true
        win.appearance = NSAppearance(named: .darkAqua)
        win.delegate = self
        
        win.contentView = hostingView
        self.window = win
    }
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

// MARK: - TutorialGuideContainerView
struct TutorialGuideContainerView: View {
    @ObservedObject var controller: TutorialWindowController
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Dark canvas background
            Color(red: 10/255, green: 12/255, blue: 16/255)
                .ignoresSafeArea()
            
            // Subtle ambient gradient
            LinearGradient(
                colors: [
                    Color(red: 18/255, green: 24/255, blue: 34/255),
                    Color(red: 10/255, green: 12/255, blue: 16/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TutorialGuideView(controller: controller, onClose: onClose)
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - TutorialGuideView
public struct TutorialGuideView: View {
    @ObservedObject var controller: TutorialWindowController
    var onClose: () -> Void
    
    public init(controller: TutorialWindowController, onClose: @escaping () -> Void) {
        self.controller = controller
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar with traffic lights clearance & tab switcher
            headerBar
            
            Divider().background(Color.white.opacity(0.08))
            
            // Body Content based on active tab
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    switch controller.activeTab {
                    case .appTutorial:
                        appTutorialContent
                    case .googleSync:
                        googleSyncGuideContent
                    case .shortcuts:
                        shortcutsContent
                    }
                }
                .padding(24)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Footer with Done button
            footerBar
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            // Spacing for macOS traffic lights
            Spacer()
                .frame(width: 66)
            
            // App Icon & Title
            HStack(spacing: 7) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accentLight)
                Text("Logtrackin Guide")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Segmented Tab Picker
            HStack(spacing: 2) {
                ForEach(TutorialTab.allCases) { tab in
                    let isSelected = controller.activeTab == tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            controller.activeTab = tab
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(isSelected ? Theme.accent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
    }
    
    // MARK: - Tab 1: App Tutorial
    private var appTutorialContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Logtrackin")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Your effortless, distraction-free productivity & timesheet companion for macOS.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            tutorialCard(
                icon: "bell.badge.fill",
                iconColor: Color(red: 2/255, green: 136/255, blue: 235/255),
                title: "1. Hourly Activity Prompts",
                description: "Logtrackin periodically shows a lightweight floating prompt at the top corner of your screen. Simply type a quick summary of what you did and hit Enter — zero focus stealing."
            )
            
            tutorialCard(
                icon: "timeline.selection",
                iconColor: Color(red: 16/255, green: 185/255, blue: 129/255),
                title: "2. Natural Language Timesheet Rails",
                description: "Type entries naturally, e.g. '9am-11am coding frontend' or 'lunch 12-1'. The natural language parser automatically infers time ranges, categories, and tags them as productive or wasteful."
            )
            
            tutorialCard(
                icon: "timer",
                iconColor: Color(red: 245/255, green: 158/255, blue: 11/255),
                title: "3. Pomodoro Focus Timer & Sticky To-Do",
                description: "Click the Pomodoro Timer from the menu bar or press ⌘T. Then click 'Tasks' to open your customizable Sticky Note To-Do list side-by-side. Enter tasks rapidly with ⏎ and star priority items."
            )
            
            tutorialCard(
                icon: "calendar.badge.clock",
                iconColor: Color(red: 139/255, green: 92/255, blue: 246/255),
                title: "4. Multi-View Calendar & Productivity Heatmaps",
                description: "Switch seamlessly between Day, Week, Month, and Year calendar views. Track your daily focus streaks and 12-week GitHub-style activity heatmaps in the Account section."
            )
        }
    }
    
    private func tutorialCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
    
    // MARK: - Tab 2: Google Sync Guide
    private var googleSyncGuideContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Google Cloud 2-Way Sync Setup")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Follow these 4 steps in your Google Cloud Console to sync timesheets with your Google Calendar.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            guideStepRow(
                step: "1",
                title: "Create a Google Cloud Project",
                desc: "Go to console.cloud.google.com and create a free project named 'Logtrackin macOS'.",
                actionTitle: "Open Google Cloud Console",
                urlStr: "https://console.cloud.google.com"
            )
            
            guideStepRow(
                step: "2",
                title: "Enable Google Calendar API",
                desc: "In APIs & Services > Library, search for 'Google Calendar API' and click 'Enable'.",
                actionTitle: "Open Calendar API Library",
                urlStr: "https://console.cloud.google.com/apis/library/calendar-json.googleapis.com"
            )
            
            guideStepRow(
                step: "3",
                title: "Configure OAuth Consent Screen",
                desc: "Select 'External' user type, add your email under Test Users, and add the scope '../auth/calendar'.",
                actionTitle: "Configure OAuth Consent",
                urlStr: "https://console.cloud.google.com/apis/credentials/consent"
            )
            
            guideStepRow(
                step: "4",
                title: "Create OAuth 2.0 Client ID (Desktop App)",
                desc: "In Credentials > Create Credentials > OAuth client ID, choose 'Desktop app'. Copy the generated Client ID and secret into Logtrackin.",
                actionTitle: "Open Credentials Dashboard",
                urlStr: "https://console.cloud.google.com/apis/credentials"
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Google OAuth Scopes Required:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text("• https://www.googleapis.com/auth/calendar (Full 2-way event read & write)\n• https://www.googleapis.com/auth/userinfo.email (User profile identification)\n• https://www.googleapis.com/auth/userinfo.profile (Display name & avatar)")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.65))
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func guideStepRow(step: String, title: String, desc: String, actionTitle: String, urlStr: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Theme.accent)
                .clipShape(Circle())
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.7))
                
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
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Tab 3: Shortcuts
    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Quickly summon windows and navigate your workspace with keystrokes.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                shortcutRow(key: "⌘ T", label: "Open Pomodoro Focus Timer Window")
                shortcutRow(key: "⇧ ⌘ D", label: "Open Sticky Note To-Do Window")
                shortcutRow(key: "⌘ L", label: "Prompt Floating Activity Log Now")
                shortcutRow(key: "⌘ N", label: "Create New Calendar Event / Planned Block")
                shortcutRow(key: "⌘ O", label: "Show Main Logtrackin Window")
                shortcutRow(key: "⌘ 1", label: "Switch to Calendar View")
                shortcutRow(key: "⌘ 2", label: "Switch to Week Planner View")
                shortcutRow(key: "⌘ 3", label: "Switch to Timesheet Rails")
                shortcutRow(key: "⌘ 4", label: "Switch to Analytics & Reports")
                shortcutRow(key: "⌘ 5", label: "Switch to Dictionary & Rules")
                shortcutRow(key: "⌘ 6", label: "Switch to Focus & Pomodoro Settings")
                shortcutRow(key: "⌘ 7", label: "Switch to Account & Cloud")
                shortcutRow(key: "⌘ ,", label: "Open Preferences & Themes")
            }
        }
    }
    
    private func shortcutRow(key: String, label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11.5))
                .foregroundColor(Color.white.opacity(0.85))
            Spacer()
            Text(key)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.accentLight)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack {
            Button(action: {
                if let url = URL(string: "https://github.com/Atharav001/Logtrackin") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "book")
                    Text("GitHub Documentation")
                }
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button("Done") {
                onClose()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 6.5)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
    }
}
