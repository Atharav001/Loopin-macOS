import Foundation
import Combine

// MARK: - LoggingScheduler
@MainActor
public final class LoggingScheduler: ObservableObject, @unchecked Sendable {
    public static let shared = LoggingScheduler()
    
    @Published public var isRunning: Bool = true
    @Published public var intervalMinutes: Int = 15
    @Published public var secondsRemaining: Int = 15 * 60
    
    // Quiet Hours settings
    @Published public var quietHoursEnabled: Bool = true
    @Published public var quietHoursStartHour: Int = 22
    @Published public var quietHoursStartMinute: Int = 0
    @Published public var quietHoursEndHour: Int = 7
    @Published public var quietHoursEndMinute: Int = 0
    
    public var onTriggerPrompt: (() -> Void)?
    
    private var timer: AnyCancellable?
    
    public init() {
        startTimer()
    }
    
    public func startTimer() {
        secondsRemaining = intervalMinutes * 60
        timer?.cancel()
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                } else {
                    self.triggerPrompt()
                }
            }
    }
    
    public func updateInterval(minutes: Int) {
        intervalMinutes = minutes
        secondsRemaining = minutes * 60
    }
    
    public func triggerPrompt() {
        secondsRemaining = intervalMinutes * 60
        
        let now = Date()
        if quietHoursEnabled && isWithinQuietHours(now: now) {
            print("[LoggingScheduler] Quiet hours active (\(quietHoursStartHour):\(quietHoursStartMinute) to \(quietHoursEndHour):\(quietHoursEndMinute)), skipping prompt.")
            return
        }
        
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
