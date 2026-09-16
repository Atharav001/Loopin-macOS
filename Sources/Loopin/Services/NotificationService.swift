import Foundation
import UserNotifications
import AppKit

// MARK: - NotificationService
@MainActor
public final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    @Published public var isAuthorized: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    public static let categoryHourlyCheckIn = "HOURLY_CHECKIN"
    public static let actionLogNow = "ACTION_LOG_NOW"
    public static let actionSkip = "ACTION_SKIP"
    
    public override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Setup & Authorization
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            Task { @MainActor in
                self?.isAuthorized = granted
                if granted {
                    self?.registerCategories()
                    print("[NotificationService] Notification authorization granted.")
                } else if let error = error {
                    print("[NotificationService] Authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: Self.actionLogNow,
            title: "Log Activity",
            options: [.foreground]
        )
        let skipAction = UNNotificationAction(
            identifier: Self.actionSkip,
            title: "Skip Interval",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: Self.categoryHourlyCheckIn,
            actions: [logAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([category])
    }
    
    // MARK: - Trigger Hourly Check-In Notification
    public func sendHourlyCheckInNotification(intervalRange: String, startHour: Date, endHour: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Hourly Check-In • \(intervalRange)"
        content.subtitle = "What did you work on?"
        content.body = "Click to record your work from \(intervalRange) in your timesheet."
        content.sound = .default
        content.categoryIdentifier = Self.categoryHourlyCheckIn
        content.userInfo = [
            "start": startHour.timeIntervalSince1970,
            "end": endHour.timeIntervalSince1970,
            "range": intervalRange
        ]
        
        let request = UNNotificationRequest(
            identifier: "Loopin_Hourly_\(Int(endHour.timeIntervalSince1970))",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        center.add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to post notification: \(error)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is active in foreground
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            AppState.shared.showFloatingLoggingPanel = true
        }
        completionHandler()
    }
}
