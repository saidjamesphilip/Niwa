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
    private(set) var todayCoffeeCount: Int = 0

    private var dailyResetTimer: Timer?

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, profileManager: UserProfileManager) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.profileManager = profileManager
        loadTodayStats()
        resumeStandingSession()
        setupNotificationCallbacks()
        scheduleDailyReset()
    }

    // MARK: - Water

    func confirmWater() {
        let event = HealthEvent(type: .water)
        event.confirmedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        gamificationEngine.awardXP(source: .water, amount: XPConstants.waterConfirm, context: modelContext)
        todayWaterCount += 1
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

        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        var totalXP = XPConstants.standComplete  // base 10 XP
        for milestone in XPConstants.standMilestones {
            if minutes >= milestone.minutes {
                totalXP += milestone.bonus
            }
        }
        totalXP = min(totalXP, XPConstants.standMaxXP)
        gamificationEngine.awardXP(source: .stand, amount: totalXP, context: modelContext)
        isStanding = false
        standingStartedAt = nil
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

    // MARK: - Coffee

    func confirmCoffee() {
        let event = HealthEvent(type: .coffee)
        event.confirmedAt = Date()
        modelContext.insert(event)
        try? modelContext.save()

        todayCoffeeCount += 1
        if todayCoffeeCount <= XPConstants.coffeeMaxBeforePenalty {
            gamificationEngine.awardXP(source: .coffee, amount: XPConstants.coffeeConfirm, context: modelContext)
        } else {
            gamificationEngine.deductXP(source: .coffee, amount: XPConstants.coffeePenalty, context: modelContext)
        }
    }

    // MARK: - Undo (once-daily items)

    func undoCreatine() {
        guard todayCreatineLogged else { return }
        let dayStart = Self.habitDayStart()

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.typeRaw == "creatine" && event.confirmedAt != nil
            },
            sortBy: [SortDescriptor(\.confirmedAt, order: .reverse)]
        )
        if let events = try? modelContext.fetch(descriptor),
           let event = events.first(where: { ($0.confirmedAt ?? .distantPast) >= dayStart }) {
            modelContext.delete(event)
            try? modelContext.save()
        }

        gamificationEngine.deductXP(source: .creatine, amount: XPConstants.creatineConfirm, context: modelContext)
        todayCreatineLogged = false
    }

    func undoGym() {
        guard todayGymLogged else { return }
        let dayStart = Self.habitDayStart()

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.typeRaw == "gym" && event.confirmedAt != nil
            },
            sortBy: [SortDescriptor(\.confirmedAt, order: .reverse)]
        )
        if let events = try? modelContext.fetch(descriptor),
           let event = events.first(where: { ($0.confirmedAt ?? .distantPast) >= dayStart }) {
            modelContext.delete(event)
            try? modelContext.save()
        }

        gamificationEngine.deductXP(source: .gym, amount: XPConstants.gymConfirm, context: modelContext)
        todayGymLogged = false
    }

    // MARK: - Load/Resume

    func reloadStats() {
        loadTodayStats()
    }

    /// Daily habits reset at 7am, not midnight
    static func habitDayStart(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let sevenAM = calendar.date(byAdding: .hour, value: 7, to: startOfDay)!
        // If it's before 7am, the habit day started yesterday at 7am
        return date < sevenAM
            ? calendar.date(byAdding: .day, value: -1, to: sevenAM)!
            : sevenAM
    }

    private func loadTodayStats() {
        let dayStart = Self.habitDayStart()

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.confirmedAt != nil
            }
        )
        guard let events = try? modelContext.fetch(descriptor) else { return }

        let todayEvents = events.filter { event in
            guard let confirmed = event.confirmedAt else { return false }
            return confirmed >= dayStart
        }

        todayWaterCount = todayEvents.filter { $0.typeRaw == HealthEventType.water.rawValue }.count
        todayCreatineLogged = todayEvents.contains { $0.typeRaw == HealthEventType.creatine.rawValue }
        todayGymLogged = todayEvents.contains { $0.typeRaw == HealthEventType.gym.rawValue }
        todayCoffeeCount = todayEvents.filter { $0.typeRaw == HealthEventType.coffee.rawValue }.count
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
        // Callbacks are now wired in NiwaApp.init() to coordinate
        // between HealthEventManager and ReminderTimerManager
    }

    // MARK: - Daily Reset at 7am

    private func scheduleDailyReset() {
        dailyResetTimer?.invalidate()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        var next7am = calendar.date(byAdding: .hour, value: 7, to: startOfDay)!
        if now >= next7am {
            next7am = calendar.date(byAdding: .day, value: 1, to: next7am)!
        }
        let interval = next7am.timeIntervalSince(now)
        dailyResetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.performDailyReset()
            }
        }
    }

    private func performDailyReset() {
        loadTodayStats()
        scheduleDailyReset()
    }
}
