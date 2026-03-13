import UserNotifications
import AppKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    // Category identifiers
    static let waterCategory = "waterReminder"
    static let standCategory = "standReminder"
    static let standingActiveCategory = "standingActive"

    // Action identifiers
    static let waterDoneAction = "waterDone"
    static let waterSnoozeAction = "waterSnooze"
    static let standUpAction = "standUp"
    static let standSnoozeAction = "standSnooze"
    static let sitDownAction = "sitDown"

    var onWaterDone: (() -> Void)?
    var onWaterSnooze: (() -> Void)?
    var onStandUp: (() -> Void)?
    var onStandSnooze: (() -> Void)?
    var onSitDown: (() -> Void)?
    // Called when a reminder is dismissed without action — so the next one gets scheduled
    var onWaterDismissed: (() -> Void)?
    var onStandDismissed: (() -> Void)?

    private override init() {
        super.init()
    }

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Define categories
        let waterDone = UNNotificationAction(identifier: Self.waterDoneAction, title: "Done", options: [])
        let waterSnooze = UNNotificationAction(identifier: Self.waterSnoozeAction, title: "Snooze 10 min", options: [])
        let waterCat = UNNotificationCategory(identifier: Self.waterCategory, actions: [waterDone, waterSnooze], intentIdentifiers: [])

        let standUp = UNNotificationAction(identifier: Self.standUpAction, title: "Stand Up", options: [])
        let standSnooze = UNNotificationAction(identifier: Self.standSnoozeAction, title: "Snooze 10 min", options: [])
        let standCat = UNNotificationCategory(identifier: Self.standCategory, actions: [standUp, standSnooze], intentIdentifiers: [])

        let sitDown = UNNotificationAction(identifier: Self.sitDownAction, title: "Sit Down", options: [])
        let standingCat = UNNotificationCategory(identifier: Self.standingActiveCategory, actions: [sitDown], intentIdentifiers: [])

        center.setNotificationCategories([waterCat, standCat, standingCat])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // Stable identifiers — scheduling a new one automatically replaces the old one
    private static let waterRequestID = "niwa-water-reminder"
    private static let standRequestID = "niwa-stand-reminder"

    func scheduleWaterReminder(at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return } // Don't schedule if in the past

        let content = UNMutableNotificationContent()
        content.title = "Time for Water"
        content.body = "Stay hydrated! Have a glass of water."
        content.categoryIdentifier = Self.waterCategory
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        let request = UNNotificationRequest(identifier: Self.waterRequestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStandReminder(at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return } // Don't schedule if in the past

        let content = UNMutableNotificationContent()
        content.title = "Time to Stand"
        content.body = "Take a break and stand up for a few minutes."
        content.categoryIdentifier = Self.standCategory
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        let request = UNNotificationRequest(identifier: Self.standRequestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier

        switch response.actionIdentifier {
        case Self.waterDoneAction: onWaterDone?()
        case Self.waterSnoozeAction: onWaterSnooze?()
        case Self.standUpAction: onStandUp?()
        case Self.standSnoozeAction: onStandSnooze?()
        case Self.sitDownAction: onSitDown?()
        case UNNotificationDefaultActionIdentifier, UNNotificationDismissActionIdentifier:
            // User tapped or dismissed without choosing an action — reschedule next reminder
            if category == Self.waterCategory { onWaterDismissed?() }
            else if category == Self.standCategory { onStandDismissed?() }
        default: break
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
