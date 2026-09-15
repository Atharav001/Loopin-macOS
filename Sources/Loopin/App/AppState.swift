import SwiftUI
import Combine

// MARK: - NavigationTab
public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case weekCalendar = "Week Calendar"
    case rails = "Timesheet Rails"
    case analytics = "Analytics & Reports"
    case dictionary = "Dictionary & Rules"
    case focusPrompts = "Focus & Pomodoro"
    case account = "Account & Cloud"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .weekCalendar: return "calendar"
        case .rails: return "timeline.selection"
        case .analytics: return "chart.bar.xaxis"
        case .dictionary: return "character.book.closed"
        case .focusPrompts: return "timer"
        case .account: return "person.crop.circle.fill"
        case .settings: return "gearshape"
        }
    }
    
    public var shortcutNumber: String {
        switch self {
        case .weekCalendar: return "1"
        case .rails: return "2"
        case .analytics: return "3"
        case .dictionary: return "4"
        case .focusPrompts: return "5"
        case .account: return "6"
        case .settings: return ","
        }
    }
}

// MARK: - AppState
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: NavigationTab = .weekCalendar
    @Published public var isPinnedOnTop: Bool = false
    
    // Multi-Theme Selector (Default: Clockify Dark)
    @Published public var currentTheme: AppTheme = {
        if let saved = UserDefaults.standard.string(forKey: "Logtrackin_AppTheme"),
           let theme = AppTheme(rawValue: saved) {
            return theme
        }
        return .clockifyDark
    }() {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "Logtrackin_AppTheme")
        }
    }
    
    // Interval Prompt state (Default: 1 hour)
    @Published public var selectedIntervalMinutes: Int = 60
    @Published public var timeRemainingInInterval: Int = 60 * 60
    @Published public var isTimerRunning: Bool = true
    @Published public var showFloatingLoggingPanel: Bool = false
    
    // Clock format: 12-hour vs 24-hour clock
    @Published public var use24HourClock: Bool = false
    
    // Week start setting
    @Published public var weekStartsOnMonday: Bool = true
    
    // Pomodoro preferences
    @Published public var autoStartBreaks: Bool = false
    
    // Floating prompt window behavior
    @Published public var intervalPromptFloatOverAllSpaces: Bool = true
    
    // Celebration breathing glow state
    @Published public var triggerCelebrationGlow: Bool = false
    @Published public var celebrationColor: Color = Color(red: 2/255, green: 136/255, blue: 235/255)
    
    // Quiet hours
    @Published public var quietHoursEnabled: Bool = true
    @Published public var quietHoursStart: Date = {
        let cal = Calendar.current
        return cal.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published public var quietHoursEnd: Date = {
        let cal = Calendar.current
        return cal.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    
    // Pomodoro Focus state
    @Published public var pomodoroDurationMinutes: Int = 25
    @Published public var pomodoroBreakMinutes: Int = 5
    @Published public var pomodoroSecondsRemaining: Int = 25 * 60
    @Published public var isPomodoroRunning: Bool = false
    @Published public var isPomodoroBreak: Bool = false
    
    // Sound & Haptics
    @Published public var soundEnabled: Bool = true
    
    // User Profile & Google Authentication
    @Published public var isSignedInWithGoogle: Bool = UserDefaults.standard.bool(forKey: "Logtrackin_GoogleSignedIn") {
        didSet { UserDefaults.standard.set(isSignedInWithGoogle, forKey: "Logtrackin_GoogleSignedIn") }
    }
    @Published public var googleUserName: String = UserDefaults.standard.string(forKey: "Logtrackin_GoogleUserName") ?? "Atharav Narang" {
        didSet { UserDefaults.standard.set(googleUserName, forKey: "Logtrackin_GoogleUserName") }
    }
    @Published public var googleUserEmail: String = UserDefaults.standard.string(forKey: "Logtrackin_GoogleUserEmail") ?? "atharav.narang@gmail.com" {
        didSet { UserDefaults.standard.set(googleUserEmail, forKey: "Logtrackin_GoogleUserEmail") }
    }
    @Published public var googleCalendarSyncEnabled: Bool = UserDefaults.standard.object(forKey: "Logtrackin_GoogleSyncEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(googleCalendarSyncEnabled, forKey: "Logtrackin_GoogleSyncEnabled") }
    }
    @Published public var lastGoogleSyncDate: Date? = Date()
    @Published public var googleAuthToken: String = UserDefaults.standard.string(forKey: "Logtrackin_GoogleAuthToken") ?? "" {
        didSet { UserDefaults.standard.set(googleAuthToken, forKey: "Logtrackin_GoogleAuthToken") }
    }
    
    // Entry editing trigger
    @Published public var editingEntry: TimesheetEntry?
    @Published public var showEntryEditor: Bool = false
    
    private var countdownCancellable: AnyCancellable?
    
    public func triggerCelebration(color: Color? = nil) {
        celebrationColor = color ?? Theme.accent
        triggerCelebrationGlow = true
    }
    
    public init() {
        startIntervalCountdown()
    }
    
    public func startIntervalCountdown() {
        timeRemainingInInterval = selectedIntervalMinutes * 60
        countdownCancellable?.cancel()
        
        countdownCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isTimerRunning else { return }
                
                if self.timeRemainingInInterval > 0 {
                    self.timeRemainingInInterval -= 1
                } else {
                    // Interval reached
                    self.handleIntervalTrigger()
                }
                
                // Also tick pomodoro if running
                if self.isPomodoroRunning {
                    if self.pomodoroSecondsRemaining > 0 {
                        self.pomodoroSecondsRemaining -= 1
                    } else {
                        self.isPomodoroBreak.toggle()
                        self.pomodoroSecondsRemaining = (self.isPomodoroBreak ? self.pomodoroBreakMinutes : self.pomodoroDurationMinutes) * 60
                    }
                }
            }
    }
    
    public func setIntervalMinutes(_ minutes: Int) {
        selectedIntervalMinutes = minutes
        timeRemainingInInterval = minutes * 60
    }
    
    public func handleIntervalTrigger() {
        // Reset timer
        timeRemainingInInterval = selectedIntervalMinutes * 60
        
        // Check quiet hours before opening panel
        if quietHoursEnabled && isWithinQuietHours(now: Date()) {
            print("Prompt skipped due to active quiet hours.")
            return
        }
        
        // Show floating panel
        showFloatingLoggingPanel = true
    }
    
    public func isWithinQuietHours(now: Date) -> Bool {
        let cal = Calendar.current
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let startMinutes = cal.component(.hour, from: quietHoursStart) * 60 + cal.component(.minute, from: quietHoursStart)
        let endMinutes = cal.component(.hour, from: quietHoursEnd) * 60 + cal.component(.minute, from: quietHoursEnd)
        
        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // Overnight range e.g. 22:00 (1320m) to 07:00 (420m)
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }
    
    public var formattedCountdown: String {
        let mins = timeRemainingInInterval / 60
        let secs = timeRemainingInInterval % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
