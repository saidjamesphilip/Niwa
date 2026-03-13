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

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, profileManager: UserProfileManager) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.profileManager = profileManager
        loadTodayStats()
        resumeStandingSession()
        setupNotificationCallbacks()
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

        gamificationEngine.awardXP(source: .stand, amount: XPConstants.standComplete, context: modelContext)
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
}
