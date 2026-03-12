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

    func scheduleWaterReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for Water"
        content.body = "Stay hydrated! Have a glass of water."
        content.categoryIdentifier = Self.waterCategory
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "water-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleStandReminder(at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Stand"
        content.body = "Take a break and stand up for a few minutes."
        content.categoryIdentifier = Self.standCategory
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "stand-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case Self.waterDoneAction: onWaterDone?()
        case Self.waterSnoozeAction: onWaterSnooze?()
        case Self.standUpAction: onStandUp?()
        case Self.standSnoozeAction: onStandSnooze?()
        case Self.sitDownAction: onSitDown?()
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
