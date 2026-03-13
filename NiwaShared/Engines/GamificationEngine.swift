import Foundation
import SwiftData
import Observation
import WidgetKit

@MainActor
@Observable
final class GamificationEngine {
    private let modelContext: ModelContext
    private(set) var didLevelUp: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Awards XP, creates an XPEvent, updates UserProfile, and returns whether a level-up occurred.
    /// All changes are saved in a single modelContext.save() call.
    @discardableResult
    func awardXP(source: XPSource, amount: Int, context: ModelContext? = nil) -> Bool {
        let ctx = context ?? modelContext
        guard let profile = fetchProfile(from: ctx) else { return false }

        let previousLevel = profile.currentLevel

        // Create XP event
        let event = XPEvent(source: source, amount: amount)
        ctx.insert(event)

        // Update profile
        profile.totalXP += amount
        profile.currentLevel = XPConstants.levelForTotalXP(profile.totalXP)

        // Single save
        try? ctx.save()

        // Update widgets
        WidgetCenter.shared.reloadAllTimelines()

        let leveledUp = profile.currentLevel > previousLevel
        didLevelUp = leveledUp
        return leveledUp
    }

    func resetLevelUpFlag() {
        didLevelUp = false
    }

    private func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
