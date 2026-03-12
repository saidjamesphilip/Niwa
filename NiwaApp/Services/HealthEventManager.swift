import Foundation
import SwiftData
import Observation

@Observable
final class HealthEventManager {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private let profileManager: UserProfileManager

    private(set) var todayWaterCount: Int = 0
    private(set) var isStanding: Bool = false
    private(set) var standingStartedAt: Date?

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, profileManager: UserProfileManager) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.profileManager = profileManager
        loadTodayStats()
        resumeStandingSession()
        setupNotificationCallbacks()
        scheduleNextReminders()
    }

    // MARK: - Water

    func confirmWater() {
        let event = HealthEvent(type: .water)
        event.confirmedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        gamificationEngine.awardXP(source: .water, amount: XPConstants.waterConfirm, context: modelContext)
        todayWaterCount += 1
        scheduleNextWaterReminder()
    }

    func snoozeWater() {
        scheduleNextWaterReminder(snoozed: true)
    }

    // MARK: - Standing

    func startStanding() {
        let event = HealthEvent(type: .stand)
        event.standingStartedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        isStanding = true
        standingStartedAt = event.standingStartedAt
    }

    func stopStanding() {
        guard isStanding, let startTime = standingStartedAt else { return }

        // Find the active standing event
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { $0.standingStartedAt != nil && $0.standingDuration == nil }
        )
        if let event = try? modelContext.fetch(descriptor).last {
            event.standingDuration = Date().timeIntervalSince(startTime)
            event.confirmedAt = Date()
            try? modelContext.save()
        }

        gamificationEngine.awardXP(source: .stand, amount: XPConstants.standComplete, context: modelContext)
        isStanding = false
        standingStartedAt = nil
        scheduleNextStandReminder()
    }

    func snoozeStand() {
        scheduleNextStandReminder(snoozed: true)
    }

    // MARK: - Scheduling

    func scheduleNextReminders() {
        scheduleNextWaterReminder()
        scheduleNextStandReminder()
    }

    private func scheduleNextWaterReminder(snoozed: Bool = false) {
        guard let profile = profileManager.profile else { return }

        let snoozedUntil: Date? = snoozed
            ? Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60))
            : nil

        let nextDate = ReminderSchedulingEngine.nextFireDate(
            intervalMinutes: profile.waterIntervalMinutes,
            workStartHour: profile.workHoursStartHour,
            workStartMinute: profile.workHoursStartMinute,
            workEndHour: profile.workHoursEndHour,
            workEndMinute: profile.workHoursEndMinute,
            lunchStartHour: profile.lunchStartHour,
            lunchStartMinute: profile.lunchStartMinute,
            lunchEndHour: profile.lunchEndHour,
            lunchEndMinute: profile.lunchEndMinute,
            snoozedUntil: snoozedUntil
        )

        NotificationManager.shared.scheduleWaterReminder(at: nextDate)
    }

    private func scheduleNextStandReminder(snoozed: Bool = false) {
        guard let profile = profileManager.profile, !isStanding else { return }

        let snoozedUntil: Date? = snoozed
            ? Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60))
            : nil

        let nextDate = ReminderSchedulingEngine.nextFireDate(
            intervalMinutes: profile.standIntervalMinutes,
            workStartHour: profile.workHoursStartHour,
            workStartMinute: profile.workHoursStartMinute,
            workEndHour: profile.workHoursEndHour,
            workEndMinute: profile.workHoursEndMinute,
            lunchStartHour: profile.lunchStartHour,
            lunchStartMinute: profile.lunchStartMinute,
            lunchEndHour: profile.lunchEndHour,
            lunchEndMinute: profile.lunchEndMinute,
            snoozedUntil: snoozedUntil
        )

        NotificationManager.shared.scheduleStandReminder(at: nextDate)
    }

    // MARK: - Load/Resume

    private func loadTodayStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let waterType = HealthEventType.water.rawValue

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.typeRaw == waterType && event.confirmedAt != nil
            }
        )
        if let events = try? modelContext.fetch(descriptor) {
            todayWaterCount = events.filter { event in
                guard let confirmed = event.confirmedAt else { return false }
                return confirmed >= startOfDay
            }.count
        }
    }

    private func resumeStandingSession() {
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { $0.standingStartedAt != nil && $0.standingDuration == nil }
        )
        if let event = try? modelContext.fetch(descriptor).last,
           let startTime = event.standingStartedAt {
            isStanding = true
            standingStartedAt = startTime
        }
    }

    private func setupNotificationCallbacks() {
        let manager = NotificationManager.shared
        manager.onWaterDone = { [weak self] in
            DispatchQueue.main.async { self?.confirmWater() }
        }
        manager.onWaterSnooze = { [weak self] in
            DispatchQueue.main.async { self?.snoozeWater() }
        }
        manager.onStandUp = { [weak self] in
            DispatchQueue.main.async { self?.startStanding() }
        }
        manager.onStandSnooze = { [weak self] in
            DispatchQueue.main.async { self?.snoozeStand() }
        }
        manager.onSitDown = { [weak self] in
            DispatchQueue.main.async { self?.stopStanding() }
        }
    }
}
