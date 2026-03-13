import Foundation
import Observation

@MainActor
@Observable
final class ReminderTimerManager {
    private let profileManager: UserProfileManager
    private let healthManager: HealthEventManager
    private var timer: Timer?

    // Persisted via UserDefaults
    private let defaults = UserDefaults.standard
    private let waterActionKey = "niwa.lastWaterActionDate"
    private let standActionKey = "niwa.lastStandActionDate"
    private let waterNotifKey = "niwa.lastWaterNotificationDate"
    private let standNotifKey = "niwa.lastStandNotificationDate"
    private let waterSnoozeKey = "niwa.snoozedWaterUntil"
    private let standSnoozeKey = "niwa.snoozedStandUntil"

    var lastWaterActionDate: Date {
        get { defaults.object(forKey: waterActionKey) as? Date ?? Date() }
        set { defaults.set(newValue, forKey: waterActionKey) }
    }

    var lastStandActionDate: Date {
        get { defaults.object(forKey: standActionKey) as? Date ?? Date() }
        set { defaults.set(newValue, forKey: standActionKey) }
    }

    private var lastWaterNotificationDate: Date? {
        get { defaults.object(forKey: waterNotifKey) as? Date }
        set { defaults.set(newValue, forKey: waterNotifKey) }
    }

    private var lastStandNotificationDate: Date? {
        get { defaults.object(forKey: standNotifKey) as? Date }
        set { defaults.set(newValue, forKey: standNotifKey) }
    }

    private var snoozedWaterUntil: Date? {
        get { defaults.object(forKey: waterSnoozeKey) as? Date }
        set { defaults.set(newValue, forKey: waterSnoozeKey) }
    }

    private var snoozedStandUntil: Date? {
        get { defaults.object(forKey: standSnoozeKey) as? Date }
        set { defaults.set(newValue, forKey: standSnoozeKey) }
    }

    init(profileManager: UserProfileManager, healthManager: HealthEventManager) {
        self.profileManager = profileManager
        self.healthManager = healthManager
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Called by notification action callbacks
    func waterDone() { lastWaterActionDate = Date(); lastWaterNotificationDate = nil; snoozedWaterUntil = nil }
    func waterSnoozed() { snoozedWaterUntil = Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60)) }
    func waterDismissed() { lastWaterActionDate = Date(); lastWaterNotificationDate = nil; snoozedWaterUntil = nil }
    func standDone() { lastStandActionDate = Date(); lastStandNotificationDate = nil; snoozedStandUntil = nil }
    func standSnoozed() { snoozedStandUntil = Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60)) }
    func standDismissed() { lastStandActionDate = Date(); lastStandNotificationDate = nil; snoozedStandUntil = nil }

    // MARK: - Timer Tick

    private func tick() {
        guard profileManager.profile?.healthRemindersEnabled == true else { return }
        let now = Date()

        if shouldFireWater(now: now) {
            NotificationManager.shared.showWaterReminder()
            lastWaterNotificationDate = now
        }

        if shouldFireStand(now: now) {
            NotificationManager.shared.showStandReminder()
            lastStandNotificationDate = now
        }
    }

    private func shouldFireWater(now: Date) -> Bool {
        if let snoozeUntil = snoozedWaterUntil {
            if now < snoozeUntil { return false }
            snoozedWaterUntil = nil
        }

        guard isWithinWorkHours(date: now), !isDuringLunch(date: now) else { return false }

        guard let profile = profileManager.profile else { return false }
        let elapsed = now.timeIntervalSince(lastWaterActionDate)
        guard elapsed >= Double(profile.waterIntervalMinutes * 60) else { return false }

        if let lastNotif = lastWaterNotificationDate, lastNotif > lastWaterActionDate { return false }

        return true
    }

    private func shouldFireStand(now: Date) -> Bool {
        guard !healthManager.isStanding else { return false }

        if let snoozeUntil = snoozedStandUntil {
            if now < snoozeUntil { return false }
            snoozedStandUntil = nil
        }

        guard isWithinWorkHours(date: now), !isDuringLunch(date: now) else { return false }

        guard let profile = profileManager.profile else { return false }
        let elapsed = now.timeIntervalSince(lastStandActionDate)
        guard elapsed >= Double(profile.standIntervalMinutes * 60) else { return false }

        if let lastNotif = lastStandNotificationDate, lastNotif > lastStandActionDate { return false }

        return true
    }

    // MARK: - Time Checks (delegate to UserProfileManager)

    private func isWithinWorkHours(date: Date) -> Bool {
        profileManager.isWithinWorkHours(date: date)
    }

    private func isDuringLunch(date: Date) -> Bool {
        profileManager.isLunchTime(date: date)
    }
}
