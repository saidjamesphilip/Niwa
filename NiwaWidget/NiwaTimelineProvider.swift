import WidgetKit
import SwiftData
import Foundation

struct NiwaTimelineProvider: TimelineProvider {
    typealias Entry = NiwaWidgetEntry

    private static let sharedContainer: ModelContainer? = {
        try? ModelContainerSetup.createContainer()
    }()

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
            guard let container = Self.sharedContainer else { return .placeholder }
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
                sessionLabel = "Focus"
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
            let dayStart = XPConstants.habitDayStart()
            let waterType = HealthEventType.water.rawValue
            let waterDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { event in
                    event.typeRaw == waterType && event.confirmedAt != nil && event.confirmedAt! >= dayStart
                }
            )
            let waterCount = try context.fetchCount(waterDescriptor)

            // Standing
            let standDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { $0.standingStartedAt != nil && $0.standingDuration == nil }
            )
            let isStanding = !(try context.fetch(standDescriptor)).isEmpty

            // Last 7 days XP
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            let xpDescriptor = FetchDescriptor<XPEvent>(
                predicate: #Predicate<XPEvent> { $0.earnedAt >= sevenDaysAgo }
            )
            let recentXPEvents = try context.fetch(xpDescriptor)
            var last7DaysXP = [Int](repeating: 0, count: 7)
            for event in recentXPEvents {
                let dayIndex = calendar.dateComponents([.day], from: sevenDaysAgo, to: event.earnedAt).day ?? 0
                if dayIndex >= 0 && dayIndex < 7 {
                    last7DaysXP[dayIndex] += event.amount
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
