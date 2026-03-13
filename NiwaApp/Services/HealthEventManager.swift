import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class HealthEventManager {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private let profileManager: UserProfileManager

    private(set) var todayWaterCount: Int = 0
    private(set) var isStanding: Bool = false
    private(set) var standingStartedAt: Date?
    private(set) var todayCreatineLogged: Bool = false
    private(set) var todayGymLogged: Bool = false

    // Track when the last reminder-triggering action happened
    // so we schedule the next one at lastAction + interval, not now + interval
    private var lastWaterActionDate: Date?
    private var lastStandActionDate: Date?

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
        lastWaterActionDate = Date()
        scheduleNextWaterReminder()
    }

    func snoozeWater() {
        lastWaterActionDate = Date()
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
        lastStandActionDate = Date()
        scheduleNextStandReminder()
    }

    func snoozeStand() {
        lastStandActionDate = Date()
        scheduleNextStandReminder(snoozed: true)
    }

    // MARK: - Creatine (once daily)

    func confirmCreatine() {
        guard !todayCreatineLogged else { return }
        let event = HealthEvent(type: .creatine)
        event.confirmedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        gamificationEngine.awardXP(source: .creatine, amount: XPConstants.creatineConfirm, context: modelContext)
        todayCreatineLogged = true
    }

    // MARK: - Gym (once daily)

    func confirmGym() {
        guard !todayGymLogged else { return }
        let event = HealthEvent(type: .gym)
        event.confirmedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        gamificationEngine.awardXP(source: .gym, amount: XPConstants.gymConfirm, context: modelContext)
        todayGymLogged = true
    }

    // MARK: - Scheduling

    func scheduleNextReminders() {
        // Cancel any existing pending notifications first
        NotificationManager.shared.cancelAllPending()

        guard profileManager.profile?.healthRemindersEnabled == true else { return }

        scheduleNextWaterReminder()
        scheduleNextStandReminder()
    }

    private func scheduleNextWaterReminder(snoozed: Bool = false) {
        guard let profile = profileManager.profile else { return }

        let snoozedUntil: Date? = snoozed
            ? Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60))
            : nil

        // Use last action time as the base so the full interval is respected
        let baseTime = lastWaterActionDate ?? Date()

        let nextDate = ReminderSchedulingEngine.nextFireDate(
            now: baseTime,
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

        // Only schedule if the fire date is in the future
        guard nextDate > Date() else {
            // If the computed date is in the past (e.g. app was closed for a while),
            // schedule from now instead
            let fallback = ReminderSchedulingEngine.nextFireDate(
                now: Date(),
                intervalMinutes: profile.waterIntervalMinutes,
                workStartHour: profile.workHoursStartHour,
                workStartMinute: profile.workHoursStartMinute,
                workEndHour: profile.workHoursEndHour,
                workEndMinute: profile.workHoursEndMinute,
                lunchStartHour: profile.lunchStartHour,
                lunchStartMinute: profile.lunchStartMinute,
                lunchEndHour: profile.lunchEndHour,
                lunchEndMinute: profile.lunchEndMinute,
                snoozedUntil: nil
            )
            NotificationManager.shared.scheduleWaterReminder(at: fallback)
            return
        }

        NotificationManager.shared.scheduleWaterReminder(at: nextDate)
    }

    private func scheduleNextStandReminder(snoozed: Bool = false) {
        guard let profile = profileManager.profile, !isStanding else { return }

        let snoozedUntil: Date? = snoozed
            ? Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60))
            : nil

        // Use last action time as the base so the full interval is respected
        let baseTime = lastStandActionDate ?? Date()

        let nextDate = ReminderSchedulingEngine.nextFireDate(
            now: baseTime,
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

        // Only schedule if the fire date is in the future
        guard nextDate > Date() else {
            let fallback = ReminderSchedulingEngine.nextFireDate(
                now: Date(),
                intervalMinutes: profile.standIntervalMinutes,
                workStartHour: profile.workHoursStartHour,
                workStartMinute: profile.workHoursStartMinute,
                workEndHour: profile.workHoursEndHour,
                workEndMinute: profile.workHoursEndMinute,
                lunchStartHour: profile.lunchStartHour,
                lunchStartMinute: profile.lunchStartMinute,
                lunchEndHour: profile.lunchEndHour,
                lunchEndMinute: profile.lunchEndMinute,
                snoozedUntil: nil
            )
            NotificationManager.shared.scheduleStandReminder(at: fallback)
            return
        }

        NotificationManager.shared.scheduleStandReminder(at: nextDate)
    }

    // MARK: - Load/Resume

    private func loadTodayStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.confirmedAt != nil
            }
        )
        guard let events = try? modelContext.fetch(descriptor) else { return }

        let todayEvents = events.filter { event in
            guard let confirmed = event.confirmedAt else { return false }
            return confirmed >= startOfDay
        }

        todayWaterCount = todayEvents.filter { $0.typeRaw == HealthEventType.water.rawValue }.count
        todayCreatineLogged = todayEvents.contains { $0.typeRaw == HealthEventType.creatine.rawValue }
        todayGymLogged = todayEvents.contains { $0.typeRaw == HealthEventType.gym.rawValue }

        // Load last action dates so reminders respect the interval from the last event
        lastWaterActionDate = events
            .filter { $0.typeRaw == HealthEventType.water.rawValue }
            .compactMap { $0.confirmedAt }
            .max()
        lastStandActionDate = events
            .filter { $0.typeRaw == HealthEventType.stand.rawValue }
            .compactMap { $0.confirmedAt }
            .max()
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
        // When user dismisses/taps without action, reschedule from now
        manager.onWaterDismissed = { [weak self] in
            DispatchQueue.main.async {
                self?.lastWaterActionDate = Date()
                self?.scheduleNextWaterReminder()
            }
        }
        manager.onStandDismissed = { [weak self] in
            DispatchQueue.main.async {
                self?.lastStandActionDate = Date()
                self?.scheduleNextStandReminder()
            }
        }
    }
}
