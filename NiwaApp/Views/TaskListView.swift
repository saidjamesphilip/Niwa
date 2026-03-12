import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NiwaTask.sortOrder) private var tasks: [NiwaTask]

    let taskManager: TaskManager

    @State private var newTaskTitle = ""
    @FocusState private var isAddFieldFocused: Bool

    private var incompleteTasks: [NiwaTask] {
        tasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [NiwaTask] {
        tasks.filter { $0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Quick-add field
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .font(.system(size: 16))

                TextField("Add a task...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.bodyFont)
                    .focused($isAddFieldFocused)
                    .onSubmit {
                        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        taskManager.addTask(title: newTaskTitle)
                        newTaskTitle = ""
                        isAddFieldFocused = true
                    }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()
                .padding(.horizontal, DesignTokens.Spacing.md)

            // Content
            if tasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(incompleteTasks, id: \.id) { task in
                            TaskRowView(
                                task: task,
                                onToggle: { taskManager.toggleComplete(task) },
                                onDelete: { taskManager.deleteTask(task) }
                            )
                        }
                        .onMove { source, destination in
                            var mutable = incompleteTasks
                            mutable.move(fromOffsets: source, toOffset: destination)
                            taskManager.reorder(tasks: mutable)
                        }

                        if !completedTasks.isEmpty {
                            HStack {
                                Text("Completed (\(completedTasks.count))")
                                    .font(DesignTokens.Typography.captionFont)
                                    .foregroundStyle(DesignTokens.Colors.textMuted)
                                Spacer()
                                Button("Clear") {
                                    taskManager.clearCompleted()
                                }
                                .font(DesignTokens.Typography.captionFont)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .padding(.top, DesignTokens.Spacing.md)
                            .padding(.bottom, DesignTokens.Spacing.xs)

                            ForEach(completedTasks, id: \.id) { task in
                                TaskRowView(
                                    task: task,
                                    onToggle: { taskManager.toggleComplete(task) },
                                    onDelete: { taskManager.deleteTask(task) }
                                )
                                .opacity(0.7)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .frame(maxHeight: 300)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "leaf")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.Colors.secondary.opacity(0.5))
            Text("Add your first task to start growing")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
}
