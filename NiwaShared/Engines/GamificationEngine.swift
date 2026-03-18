import Foundation
import SwiftData
import Observation
import WidgetKit

@MainActor
@Observable
final class GamificationEngine {
    private let modelContext: ModelContext
    private(set) var levelUpCount: Int = 0
    /// Stores the level before the most recent level-up, for the celebration overlay.
    private(set) var previousLevel: Int = 0
    /// Cached recent XP events for the chart — refreshed only on XP award/deduct.
    private(set) var recentXPEvents: [XPEvent] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshRecentXPEvents()
    }

    private func refreshRecentXPEvents() {
        let calendar = Calendar.current
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: calendar.startOfDay(for: Date()))!
        let descriptor = FetchDescriptor<XPEvent>(
            predicate: #Predicate<XPEvent> { $0.earnedAt >= fifteenDaysAgo }
        )
        recentXPEvents = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Awards XP, creates an XPEvent, updates UserProfile, and returns whether a level-up occurred.
    /// All changes are saved in a single modelContext.save() call.
    @discardableResult
    func awardXP(source: XPSource, amount: Int, context: ModelContext? = nil) -> Bool {
        let ctx = context ?? modelContext
        guard let profile = fetchProfile(from: ctx) else { return false }

        let previousLevelLocal = profile.currentLevel

        // Create XP event
        let event = XPEvent(source: source, amount: amount)
        ctx.insert(event)

        // Update profile
        profile.totalXP += amount
        profile.currentLevel = XPConstants.levelForTotalXP(profile.totalXP)

        // Single save
        try? ctx.save()

        // Refresh cached chart data and widgets
        refreshRecentXPEvents()
        WidgetCenter.shared.reloadAllTimelines()

        let leveledUp = profile.currentLevel > previousLevelLocal
        if leveledUp { self.previousLevel = previousLevelLocal }
        if leveledUp { levelUpCount += 1 }
        return leveledUp
    }

    @discardableResult
    func deductXP(source: XPSource, amount: Int, context: ModelContext) -> Bool {
        guard let profile = fetchProfile(from: context) else { return false }

        profile.totalXP = max(0, profile.totalXP - amount)
        profile.currentLevel = XPConstants.levelForTotalXP(profile.totalXP)
        // Level-down is always silent — levelUpCount is NOT incremented

        // Delete the most recent matching XPEvent from today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<XPEvent>(
            predicate: #Predicate<XPEvent> { event in
                event.sourceRaw == sourceRaw && event.earnedAt >= startOfDay
            },
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        if let event = try? context.fetch(descriptor).first {
            context.delete(event)
        }

        try? context.save()
        refreshRecentXPEvents()
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    private func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
