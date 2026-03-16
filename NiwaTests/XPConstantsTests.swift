import XCTest
@testable import Niwa

final class XPConstantsTests: XCTestCase {

    // MARK: - totalXPForLevel

    func testTotalXPForLevel_zero_returnsZero() {
        XCTAssertEqual(XPConstants.totalXPForLevel(0), 0)
    }

    func testTotalXPForLevel_knownLevels() {
        // Formula: 25N² + 75N
        XCTAssertEqual(XPConstants.totalXPForLevel(1), 100)    // 25 + 75
        XCTAssertEqual(XPConstants.totalXPForLevel(2), 250)    // 100 + 150
        XCTAssertEqual(XPConstants.totalXPForLevel(3), 450)    // 225 + 225
        XCTAssertEqual(XPConstants.totalXPForLevel(4), 700)    // 400 + 300
        XCTAssertEqual(XPConstants.totalXPForLevel(5), 1000)   // 625 + 375
        XCTAssertEqual(XPConstants.totalXPForLevel(10), 3250)  // 2500 + 750
    }

    func testTotalXPForLevel_negativeLevel_returnsZero() {
        XCTAssertEqual(XPConstants.totalXPForLevel(-1), 0)
    }

    func testTotalXPForLevel_isStrictlyIncreasing() {
        for level in 0..<50 {
            XCTAssertLessThan(
                XPConstants.totalXPForLevel(level),
                XPConstants.totalXPForLevel(level + 1),
                "XP should increase between level \(level) and \(level + 1)"
            )
        }
    }

    // MARK: - levelForTotalXP

    func testLevelForTotalXP_zero_returnsZero() {
        XCTAssertEqual(XPConstants.levelForTotalXP(0), 0)
    }

    func testLevelForTotalXP_negative_returnsZero() {
        XCTAssertEqual(XPConstants.levelForTotalXP(-100), 0)
    }

    func testLevelForTotalXP_exactThresholds() {
        XCTAssertEqual(XPConstants.levelForTotalXP(100), 1)
        XCTAssertEqual(XPConstants.levelForTotalXP(250), 2)
        XCTAssertEqual(XPConstants.levelForTotalXP(450), 3)
        XCTAssertEqual(XPConstants.levelForTotalXP(700), 4)
        XCTAssertEqual(XPConstants.levelForTotalXP(1000), 5)
    }

    func testLevelForTotalXP_justBelowThreshold() {
        XCTAssertEqual(XPConstants.levelForTotalXP(99), 0)
        XCTAssertEqual(XPConstants.levelForTotalXP(249), 1)
        XCTAssertEqual(XPConstants.levelForTotalXP(449), 2)
        XCTAssertEqual(XPConstants.levelForTotalXP(699), 3)
    }

    func testLevelForTotalXP_midLevel() {
        XCTAssertEqual(XPConstants.levelForTotalXP(175), 1)  // Between 100 and 250
    }

    func testLevelForTotalXP_roundTrip() {
        // For any level, totalXPForLevel should round-trip back
        for level in 0..<30 {
            let xp = XPConstants.totalXPForLevel(level)
            XCTAssertEqual(
                XPConstants.levelForTotalXP(xp), level,
                "Round-trip failed for level \(level)"
            )
        }
    }

    // MARK: - xpForNextLevel

    func testXpForNextLevel_atLevelStart() {
        let result = XPConstants.xpForNextLevel(currentTotalXP: 100) // Exactly level 1
        XCTAssertEqual(result.currentLevelXP, 0)    // 0 XP into level 2
        XCTAssertEqual(result.nextLevelXP, 150)      // 250 - 100
    }

    func testXpForNextLevel_midLevel() {
        let result = XPConstants.xpForNextLevel(currentTotalXP: 175) // Level 1, halfway to 2
        XCTAssertEqual(result.currentLevelXP, 75)    // 175 - 100
        XCTAssertEqual(result.nextLevelXP, 150)      // 250 - 100
    }

    func testXpForNextLevel_atZero() {
        let result = XPConstants.xpForNextLevel(currentTotalXP: 0)
        XCTAssertEqual(result.currentLevelXP, 0)
        XCTAssertEqual(result.nextLevelXP, 100)      // 100 - 0
    }

    // MARK: - plantStage

    func testPlantStage_boundaries() {
        XCTAssertEqual(XPConstants.plantStage(for: 0), .seed)
        XCTAssertEqual(XPConstants.plantStage(for: 1), .sprout)
        XCTAssertEqual(XPConstants.plantStage(for: 3), .sprout)
        XCTAssertEqual(XPConstants.plantStage(for: 4), .seedling)
        XCTAssertEqual(XPConstants.plantStage(for: 7), .seedling)
        XCTAssertEqual(XPConstants.plantStage(for: 8), .youngPlant)
        XCTAssertEqual(XPConstants.plantStage(for: 12), .youngPlant)
        XCTAssertEqual(XPConstants.plantStage(for: 13), .bush)
        XCTAssertEqual(XPConstants.plantStage(for: 18), .bush)
        XCTAssertEqual(XPConstants.plantStage(for: 19), .smallTree)
        XCTAssertEqual(XPConstants.plantStage(for: 25), .smallTree)
        XCTAssertEqual(XPConstants.plantStage(for: 26), .fullTree)
        XCTAssertEqual(XPConstants.plantStage(for: 35), .fullTree)
        XCTAssertEqual(XPConstants.plantStage(for: 36), .ancientTree)
        XCTAssertEqual(XPConstants.plantStage(for: 100), .ancientTree)
    }

    func testPlantStageName_matchesRawValue() {
        XCTAssertEqual(XPConstants.plantStageName(for: 0), "Seed")
        XCTAssertEqual(XPConstants.plantStageName(for: 5), "Seedling")
        XCTAssertEqual(XPConstants.plantStageName(for: 36), "Ancient Tree")
    }

    // MARK: - habitDayStart

    func testHabitDayStart_afterSevenAM_returnsTodaySevenAM() {
        // 2026-03-16 at 10:00 AM
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 16
        components.hour = 10
        components.minute = 0
        let date = calendar.date(from: components)!

        let result = XPConstants.habitDayStart(for: date)

        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(resultComponents.year, 2026)
        XCTAssertEqual(resultComponents.month, 3)
        XCTAssertEqual(resultComponents.day, 16)
        XCTAssertEqual(resultComponents.hour, 7)
        XCTAssertEqual(resultComponents.minute, 0)
    }

    func testHabitDayStart_beforeSevenAM_returnsYesterdaySevenAM() {
        // 2026-03-16 at 3:00 AM — should return March 15 at 7am
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 16
        components.hour = 3
        components.minute = 0
        let date = calendar.date(from: components)!

        let result = XPConstants.habitDayStart(for: date)

        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        XCTAssertEqual(resultComponents.year, 2026)
        XCTAssertEqual(resultComponents.month, 3)
        XCTAssertEqual(resultComponents.day, 15)
        XCTAssertEqual(resultComponents.hour, 7)
        XCTAssertEqual(resultComponents.minute, 0)
    }

    func testHabitDayStart_exactlySevenAM_returnsSameDay() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 16
        components.hour = 7
        components.minute = 0
        components.second = 0
        let date = calendar.date(from: components)!

        let result = XPConstants.habitDayStart(for: date)

        let resultComponents = calendar.dateComponents([.day, .hour], from: result)
        XCTAssertEqual(resultComponents.day, 16)
        XCTAssertEqual(resultComponents.hour, 7)
    }

    // MARK: - Constants sanity checks

    func testCoffeeMaxBeforePenalty_isPositive() {
        XCTAssertGreaterThan(XPConstants.coffeeMaxBeforePenalty, 0)
    }

    func testStandMilestones_areOrdered() {
        let minutes = XPConstants.standMilestones.map(\.minutes)
        XCTAssertEqual(minutes, minutes.sorted(), "Stand milestones should be in ascending order")
    }

    func testStandMilestones_totalBonusDoesNotExceedMax() {
        let totalBonus = XPConstants.standMilestones.reduce(0) { $0 + $1.bonus }
        let maxPossible = totalBonus + XPConstants.standComplete
        XCTAssertEqual(maxPossible, XPConstants.standMaxXP,
                       "Base + all milestone bonuses should equal standMaxXP")
    }
}
