import SwiftUI
import Combine

// MARK: - NavigationTab
public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case rails = "Rails"
    case weekCalendar = "Week Calendar"
    case analytics = "Analytics & Reports"
    case dictionary = "Dictionary"
    case focusPrompts = "Focus & Prompts"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .rails: return "timeline.selection"
        case .weekCalendar: return "calendar"
        case .analytics: return "chart.bar.xaxis"
        case .dictionary: return "character.book.closed"
        case .focusPrompts: return "slider.horizontal.3"
        }
    }
    
    public var shortcutNumber: String {
        switch self {
        case .rails: return "1"
        case .weekCalendar: return "2"
        case .analytics: return "3"
        case .dictionary: return "4"
        case .focusPrompts: return "5"
        }
    }
}

// MARK: - AppState
@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedTab: NavigationTab = .rails
    @Published public var isPinnedOnTop: Bool = false
    
    // Interval Prompt state
    @Published public var selectedIntervalMinutes: Int = 15
    @Published public var timeRemainingInInterval: Int = 15 * 60
    @Published public var isTimerRunning: Bool = true
    @Published public var showFloatingLoggingPanel: Bool = false
    
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
    
    // Entry editing trigger
    @Published public var editingEntry: TimesheetEntry?
    @Published public var showEntryEditor: Bool = false
    
    private var countdownCancellable: AnyCancellable?
    
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
