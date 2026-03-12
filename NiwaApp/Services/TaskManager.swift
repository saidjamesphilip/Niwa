import Foundation
import SwiftData
import Observation
import WidgetKit

@Observable
final class TaskManager {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
    }

    func addTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Get current max sortOrder
        var descriptor = FetchDescriptor<NiwaTask>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

        let task = NiwaTask(title: title.trimmingCharacters(in: .whitespaces), sortOrder: maxOrder + 1)
        modelContext.insert(task)
        try? modelContext.save()
    }

    func toggleComplete(_ task: NiwaTask) {
        task.isCompleted.toggle()
        if task.isCompleted {
            task.completedAt = Date()
            gamificationEngine.awardXP(source: .task, amount: XPConstants.taskComplete, context: modelContext)
        } else {
            task.completedAt = nil
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteTask(_ task: NiwaTask) {
        modelContext.delete(task)
        try? modelContext.save()
    }

    func reorder(tasks: [NiwaTask]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        try? modelContext.save()
    }

    func clearCompleted() {
        let descriptor = FetchDescriptor<NiwaTask>(predicate: #Predicate { $0.isCompleted })
        guard let completed = try? modelContext.fetch(descriptor) else { return }
        for task in completed {
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
}
