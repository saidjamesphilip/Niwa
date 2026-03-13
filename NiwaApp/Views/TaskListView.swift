import SwiftUI
import SwiftData

struct TaskListView: View {
    var contentMaxHeight: CGFloat = 600

    @EnvironmentObject var taskManager: TaskManager

    @State private var newTaskTitle = ""
    @State private var showAllTasks = false
    @FocusState private var isAddFieldFocused: Bool

    private let visibleLimit = 10

    private var incompleteTasks: [NiwaTask] {
        taskManager.tasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [NiwaTask] {
        taskManager.tasks.filter { $0.isCompleted }
    }

    private var visibleIncompleteTasks: [NiwaTask] {
        if showAllTasks || incompleteTasks.count <= visibleLimit {
            return incompleteTasks
        }
        return Array(incompleteTasks.prefix(visibleLimit))
    }

    private var hiddenCount: Int {
        max(0, incompleteTasks.count - visibleLimit)
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
            if taskManager.tasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(visibleIncompleteTasks.enumerated()), id: \.element.id) { index, task in
                            TaskRowView(
                                task: task,
                                onToggle: { taskManager.toggleComplete(task) },
                                onDelete: { taskManager.deleteTask(task) },
                                onMoveUp: { taskManager.moveUp(task) },
                                onMoveDown: { taskManager.moveDown(task) },
                                onSetPriority: { taskManager.setPriority(task, priority: $0) },
                                onSetDueDate: { taskManager.setDueDate(task, date: $0) },
                                isFirst: index == 0,
                                isLast: index == incompleteTasks.count - 1
                            )
                        }

                        // Show more button
                        if !showAllTasks && hiddenCount > 0 {
                            Button {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    showAllTasks = true
                                }
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                    Text("Show \(hiddenCount) more")
                                        .font(DesignTokens.Typography.captionFont)
                                }
                                .foregroundStyle(DesignTokens.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .buttonStyle(.plain)
                        }

                        // Show less button
                        if showAllTasks && incompleteTasks.count > visibleLimit {
                            Button {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    showAllTasks = false
                                }
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 9))
                                    Text("Show less")
                                        .font(DesignTokens.Typography.captionFont)
                                }
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .buttonStyle(.plain)
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
                .frame(maxHeight: contentMaxHeight)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)

            Text("Plant a seed — add your first task")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xl)
    }
}
