import Foundation
import SwiftData
import Combine
import WidgetKit

@MainActor
final class TaskManager: ObservableObject {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private var appErrorState: AppErrorState?

    @Published private(set) var tasks: [NiwaTask] = []

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, appErrorState: AppErrorState) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.appErrorState = appErrorState
        refreshTasks()
    }

    func addTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        var descriptor = FetchDescriptor<NiwaTask>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

        let task = NiwaTask(title: title.trimmingCharacters(in: .whitespaces), sortOrder: maxOrder + 1)
        modelContext.insert(task)
        save()
        refreshTasks()
    }

    func toggleComplete(_ task: NiwaTask) {
        task.isCompleted.toggle()
        if task.isCompleted {
            task.completedAt = Date()
            gamificationEngine.awardXP(source: .task, amount: XPConstants.taskComplete, context: modelContext)
        } else {
            task.completedAt = nil
        }
        save()
        refreshTasks()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteTask(_ task: NiwaTask) {
        modelContext.delete(task)
        save()
        refreshTasks()
    }

    func reorder(tasks: [NiwaTask]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        save()
        refreshTasks()
    }

    func setPriority(_ task: NiwaTask, priority: TaskPriority) {
        task.priority = priority
        save()
        refreshTasks()
    }

    func setDueDate(_ task: NiwaTask, date: Date?) {
        task.dueDate = date
        save()
        refreshTasks()
    }

    func moveUp(_ task: NiwaTask) {
        let incomplete = tasks.filter { !$0.isCompleted }
        guard let index = incomplete.firstIndex(where: { $0.id == task.id }), index > 0 else { return }
        let other = incomplete[index - 1]
        let temp = task.sortOrder
        task.sortOrder = other.sortOrder
        other.sortOrder = temp
        save()
        refreshTasks()
    }

    func moveDown(_ task: NiwaTask) {
        let incomplete = tasks.filter { !$0.isCompleted }
        guard let index = incomplete.firstIndex(where: { $0.id == task.id }), index < incomplete.count - 1 else { return }
        let other = incomplete[index + 1]
        let temp = task.sortOrder
        task.sortOrder = other.sortOrder
        other.sortOrder = temp
        save()
        refreshTasks()
    }

    func clearCompleted() {
        let descriptor = FetchDescriptor<NiwaTask>(predicate: #Predicate { $0.isCompleted })
        guard let completed = try? modelContext.fetch(descriptor) else { return }
        for task in completed {
            modelContext.delete(task)
        }
        save()
        refreshTasks()
    }

    func refreshTasks() {
        let descriptor = FetchDescriptor<NiwaTask>(sortBy: [SortDescriptor(\.sortOrder)])
        do {
            tasks = try modelContext.fetch(descriptor)
        } catch {
            tasks = []
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            // Retry once
            do {
                try modelContext.save()
            } catch {
                appErrorState?.showError("Unable to save tasks. Please restart Niwa.")
                print("[TaskManager] Save failed after retry: \(error)")
            }
        }
    }
}
