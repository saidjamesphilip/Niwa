import SwiftUI

struct FloatingWindowContentView: View {
    let timerEngine: PomodoroTimerEngine
    let taskManager: TaskManager

    @Query private var tasks: [NiwaTask]

    init(timerEngine: PomodoroTimerEngine, taskManager: TaskManager) {
        self.timerEngine = timerEngine
        self.taskManager = taskManager
        let descriptor = FetchDescriptor<NiwaTask>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\NiwaTask.sortOrder)]
        )
        _tasks = Query(descriptor)
    }

    private var currentTask: NiwaTask? { tasks.first }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Drag handle
            Capsule()
                .fill(DesignTokens.Colors.subtle)
                .frame(width: 32, height: 4)
                .padding(.top, DesignTokens.Spacing.sm)

            // Timer
            Text(timerEngine.formattedTime)
                .font(DesignTokens.Typography.monoLargeFont)
                .foregroundStyle(
                    timerEngine.state == .idle
                        ? DesignTokens.Colors.textMuted
                        : DesignTokens.Colors.primary
                )
                .monospacedDigit()

            // Session label
            if timerEngine.state != .idle {
                Text(sessionLabel)
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Current task
            if let task = currentTask {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Circle()
                        .fill(DesignTokens.Colors.primary)
                        .frame(width: 6, height: 6)
                    Text(task.title)
                        .font(DesignTokens.Typography.captionFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 220)
        .background(DesignTokens.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
        .shadow(
            color: Color.black.opacity(0.12),
            radius: DesignTokens.Shadow.elevatedRadius,
            y: DesignTokens.Shadow.elevatedY
        )
    }

    private var sessionLabel: String {
        switch timerEngine.state {
        case .idle: return ""
        case .working, .paused: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

import SwiftData
