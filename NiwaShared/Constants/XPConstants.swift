import Foundation

enum XPConstants {
    // XP award amounts per action
    static let focusXPPerMinute: Int = 1
    static let taskComplete: Int = 15
    static let noteCreate: Int = 5
    static let waterConfirm: Int = 10
    static let standComplete: Int = 10
    static let creatineConfirm: Int = 15
    static let gymConfirm: Int = 30
    static let coffeeConfirm: Int = 10
    static let coffeePenalty: Int = 5
    static let coffeeMaxBeforePenalty: Int = 3

    // Focus timer defaults
    static let defaultFocusPresets: [Int] = [15, 25, 45]

    // Health reminder defaults
    static let defaultWaterIntervalMinutes: Int = 30
    static let defaultStandIntervalMinutes: Int = 45
    static let snoozeDurationMinutes: Int = 10

    // Work hours defaults
    static let defaultWorkStartHour: Int = 9
    static let defaultWorkStartMinute: Int = 0
    static let defaultWorkEndHour: Int = 17
    static let defaultWorkEndMinute: Int = 0
    static let defaultLunchStartHour: Int = 12
    static let defaultLunchStartMinute: Int = 0
    static let defaultLunchEndHour: Int = 13
    static let defaultLunchEndMinute: Int = 0

    // Standing milestones — cumulative bonuses at time thresholds
    static let standMilestones: [(minutes: Int, bonus: Int)] = [
        (10, 5), (20, 10), (30, 15)
    ]
    static let standMaxXP: Int = 40

    // Plant stage boundaries
    enum PlantStage: String {
        case seed = "Seed"
        case sprout = "Sprout"
        case seedling = "Seedling"
        case youngPlant = "Young Plant"
        case bush = "Bush"
        case smallTree = "Small Tree"
        case fullTree = "Full Tree"
        case ancientTree = "Ancient Tree"
    }

    static func plantStage(for level: Int) -> PlantStage {
        switch level {
        case 0: return .seed
        case 1...3: return .sprout
        case 4...7: return .seedling
        case 8...12: return .youngPlant
        case 13...18: return .bush
        case 19...25: return .smallTree
        case 26...35: return .fullTree
        default: return .ancientTree
        }
    }

    static func plantStageName(for level: Int) -> String {
        plantStage(for: level).rawValue
    }

    /// Total XP required to reach a given level.
    /// Formula: 25N² + 75N (Level 1: 100, Level 2: 250, Level 3: 450, Level 4: 700, Level 5: 1000)
    static func totalXPForLevel(_ level: Int) -> Int {
        guard level > 0 else { return 0 }
        return 25 * level * level + 75 * level
    }

    /// Calculate the current level for a given total XP amount.
    static func levelForTotalXP(_ totalXP: Int) -> Int {
        guard totalXP > 0 else { return 0 }
        var level = 0
        while totalXPForLevel(level + 1) <= totalXP {
            level += 1
        }
        return level
    }

    /// XP needed for the next level from current total XP.
    static func xpForNextLevel(currentTotalXP: Int) -> (currentLevelXP: Int, nextLevelXP: Int) {
        let currentLevel = levelForTotalXP(currentTotalXP)
        let currentLevelThreshold = totalXPForLevel(currentLevel)
        let nextLevelThreshold = totalXPForLevel(currentLevel + 1)
        return (currentTotalXP - currentLevelThreshold, nextLevelThreshold - currentLevelThreshold)
    }

    /// Daily habits reset at 7am, not midnight
    static func habitDayStart(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let sevenAM = calendar.date(byAdding: .hour, value: 7, to: startOfDay)!
        return date < sevenAM
            ? calendar.date(byAdding: .day, value: -1, to: sevenAM)!
            : sevenAM
    }
}
