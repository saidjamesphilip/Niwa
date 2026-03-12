import WidgetKit
import Foundation

struct NiwaWidgetEntry: TimelineEntry {
    let date: Date

    // Timer
    let timerActive: Bool
    let timerEndDate: Date?
    let timerStartDate: Date?
    let sessionLabel: String

    // Tasks
    let topTasks: [(title: String, isCompleted: Bool)]

    // Health
    let waterCount: Int
    let isStanding: Bool

    // XP
    let totalXP: Int
    let currentLevel: Int
    let xpProgress: Double // 0...1
    let last7DaysXP: [Int] // 7 values, one per day

    // Plant icon
    let plantIconName: String

    static var placeholder: NiwaWidgetEntry {
        NiwaWidgetEntry(
            date: .now,
            timerActive: false,
            timerEndDate: nil,
            timerStartDate: nil,
            sessionLabel: "",
            topTasks: [],
            waterCount: 0,
            isStanding: false,
            totalXP: 0,
            currentLevel: 0,
            xpProgress: 0,
            last7DaysXP: Array(repeating: 0, count: 7),
            plantIconName: "leaf.circle"
        )
    }
}
