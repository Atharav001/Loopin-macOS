import Foundation
import Combine

// MARK: - LoggingScheduler
@MainActor
public final class LoggingScheduler: ObservableObject, @unchecked Sendable {
    public static let shared = LoggingScheduler()
    
    @Published public var isRunning: Bool = true
    @Published public var intervalMinutes: Int = 60
    @Published public var secondsRemaining: Int = 60 * 60
    
    // Quiet Hours settings
    @Published public var quietHoursEnabled: Bool = true
    @Published public var quietHoursStartHour: Int = 22
    @Published public var quietHoursStartMinute: Int = 0
    @Published public var quietHoursEndHour: Int = 7
    @Published public var quietHoursEndMinute: Int = 0
    
    public var onTriggerPrompt: (() -> Void)?
    
    public init() {
        // Synchronize with AppState settings
        self.intervalMinutes = AppState.shared.selectedIntervalMinutes
        self.secondsRemaining = AppState.shared.timeRemainingInInterval
    }
    
    public func startTimer() {
        AppState.shared.startIntervalCountdown()
    }
    
    public func updateInterval(minutes: Int) {
        intervalMinutes = minutes
        AppState.shared.setIntervalMinutes(minutes)
    }
    
    public func triggerPrompt() {
        AppState.shared.handleManualIntervalTrigger()
        onTriggerPrompt?()
    }
    
    public func isWithinQuietHours(now: Date) -> Bool {
        let cal = Calendar.current
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute
        let endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute
        
        return Self.evaluateQuietHours(nowMinutes: nowMinutes, startMinutes: startMinutes, endMinutes: endMinutes)
    }
    
    public nonisolated static func evaluateQuietHours(nowMinutes: Int, startMinutes: Int, endMinutes: Int) -> Bool {
        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // Overnight range e.g. 22:00 (1320m) to 07:00 (420m)
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }
}
