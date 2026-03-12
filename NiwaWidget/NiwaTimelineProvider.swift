import WidgetKit
import SwiftData
import Foundation

struct NiwaTimelineProvider: TimelineProvider {
    typealias Entry = NiwaWidgetEntry

    func placeholder(in context: Context) -> NiwaWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NiwaWidgetEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NiwaWidgetEntry>) -> Void) {
        let entry = createEntry()
        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> NiwaWidgetEntry {
        do {
            let container = try ModelContainerSetup.createContainer()
            let context = ModelContext(container)

            // Profile
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let profile = try context.fetch(profileDescriptor).first

            let totalXP = profile?.totalXP ?? 0
            let currentLevel = profile?.currentLevel ?? 0
            let xpInfo = XPConstants.xpForNextLevel(currentTotalXP: totalXP)
            let xpProgress = xpInfo.nextLevelXP > 0 ? Double(xpInfo.currentLevelXP) / Double(xpInfo.nextLevelXP) : 0

            // Plant icon
            let plantIcon: String
            switch currentLevel {
            case 0...5: plantIcon = "leaf.circle"
            case 6...15: plantIcon = "leaf"
            case 16...30: plantIcon = "leaf.fill"
            default: plantIcon = "tree"
            }

            // Timer
            var timerActive = false
            var timerEndDate: Date?
            var timerStartDate: Date?
            var sessionLabel = ""

            let timerDescriptor = FetchDescriptor<TimerSession>(
                predicate: #Predicate { $0.completedAt == nil },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            if let session = try context.fetch(timerDescriptor).first {
                timerActive = true
                timerStartDate = session.startedAt
                timerEndDate = session.startedAt.addingTimeInterval(session.duration)
                switch session.type {
                case .work: sessionLabel = "Focus"
                case .shortBreak: sessionLabel = "Short Break"
                case .longBreak: sessionLabel = "Long Break"
                }
            }

            // Tasks
            var taskDescriptor = FetchDescriptor<NiwaTask>(
                predicate: #Predicate { !$0.isCompleted },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            taskDescriptor.fetchLimit = 3
            let tasks = try context.fetch(taskDescriptor)
            let topTasks = tasks.map { (title: $0.title, isCompleted: $0.isCompleted) }

            // Water count today
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let waterType = HealthEventType.water.rawValue
            let waterDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { $0.typeRaw == waterType && $0.confirmedAt != nil }
            )
            let waterEvents = try context.fetch(waterDescriptor)
            let waterCount = waterEvents.filter { ($0.confirmedAt ?? .distantPast) >= startOfDay }.count

            // Standing
            let standDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { $0.standingStartedAt != nil && $0.standingDuration == nil }
            )
            let isStanding = !(try context.fetch(standDescriptor)).isEmpty

            // Last 7 days XP
            var last7DaysXP = [Int](repeating: 0, count: 7)
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfDay)!
            let xpDescriptor = FetchDescriptor<XPEvent>()
            let allXPEvents = try context.fetch(xpDescriptor)
            for event in allXPEvents {
                if event.earnedAt >= sevenDaysAgo {
                    let dayIndex = calendar.dateComponents([.day], from: sevenDaysAgo, to: event.earnedAt).day ?? 0
                    if dayIndex >= 0 && dayIndex < 7 {
                        last7DaysXP[dayIndex] += event.amount
                    }
                }
            }

            return NiwaWidgetEntry(
                date: .now,
                timerActive: timerActive,
                timerEndDate: timerEndDate,
                timerStartDate: timerStartDate,
                sessionLabel: sessionLabel,
                topTasks: topTasks,
                waterCount: waterCount,
                isStanding: isStanding,
                totalXP: totalXP,
                currentLevel: currentLevel,
                xpProgress: xpProgress,
                last7DaysXP: last7DaysXP,
                plantIconName: plantIcon
            )
        } catch {
            return .placeholder
        }
    }
}
