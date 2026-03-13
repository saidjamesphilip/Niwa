import SwiftUI

struct TaskRowView: View {
    let task: NiwaTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)? = nil
    var onMoveDown: (() -> Void)? = nil
    var onSetPriority: ((TaskPriority) -> Void)? = nil
    var onSetDueDate: ((Date?) -> Void)? = nil
    var isFirst: Bool = false
    var isLast: Bool = false

    @State private var isHovering = false

    private var priorityColor: Color {
        switch task.priority {
        case .high: return DesignTokens.Colors.danger
        case .medium: return Color(red: 224/255, green: 172/255, blue: 58/255)
        case .low: return DesignTokens.Colors.secondary
        case .none: return Color.clear
        }
    }

    private var dueBadge: (text: String, color: Color)? {
        guard let dueDate = task.dueDate, !task.isCompleted else { return nil }
        if task.isOverdue {
            return ("Overdue", DesignTokens.Colors.danger)
        } else if task.isDueToday {
            return ("Today", DesignTokens.Colors.primary)
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return ("Tomorrow", Color(red: 224/255, green: 172/255, blue: 58/255))
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return (formatter.string(from: dueDate), DesignTokens.Colors.textMuted)
        }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Priority bar
            RoundedRectangle(cornerRadius: 2)
                .fill(task.priority == .none ? Color.clear : priorityColor)
                .frame(width: 3, height: 20)

            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(task.isCompleted ? DesignTokens.Colors.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    task.isCompleted ? DesignTokens.Colors.primary : DesignTokens.Colors.subtle,
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 16, height: 16)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) incomplete" : "Complete \(task.title)")

            // Title + due badge
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(task.isCompleted ? DesignTokens.Colors.textMuted : DesignTokens.Colors.textPrimary)
                    .strikethrough(task.isCompleted, color: DesignTokens.Colors.textMuted.opacity(0.5))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Due date badge
            if let badge = dueBadge {
                Text(badge.text)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(badge.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badge.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Action buttons — visible on hover
            if isHovering && !task.isCompleted {
                HStack(spacing: 2) {
                    if !isFirst {
                        iconButton(systemName: "chevron.up", color: DesignTokens.Colors.textMuted) {
                            onMoveUp?()
                        }
                    }

                    if !isLast {
                        iconButton(systemName: "chevron.down", color: DesignTokens.Colors.textMuted) {
                            onMoveDown?()
                        }
                    }

                    iconButton(systemName: "xmark.circle.fill", color: DesignTokens.Colors.danger.opacity(0.7)) {
                        onDelete()
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(isHovering ? DesignTokens.Colors.backgroundSecondary.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(action: onToggle) {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }

            if !task.isCompleted {
                Divider()

                Menu("Priority") {
                    ForEach(TaskPriority.allCases, id: \.rawValue) { priority in
                        Button {
                            onSetPriority?(priority)
                        } label: {
                            HStack {
                                Text(priority.label)
                                if task.priority == priority {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Menu("Due Date") {
                    Button { onSetDueDate?(Calendar.current.startOfDay(for: Date())) } label: {
                        Label("Today", systemImage: "calendar")
                    }
                    Button {
                        onSetDueDate?(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())))
                    } label: {
                        Label("Tomorrow", systemImage: "calendar.badge.clock")
                    }
                    Button {
                        // Next Monday
                        let today = Date()
                        let weekday = Calendar.current.component(.weekday, from: today)
                        let daysToMonday = (9 - weekday) % 7
                        let nextMonday = Calendar.current.date(byAdding: .day, value: daysToMonday == 0 ? 7 : daysToMonday, to: Calendar.current.startOfDay(for: today))
                        onSetDueDate?(nextMonday)
                    } label: {
                        Label("Next Monday", systemImage: "calendar.badge.plus")
                    }
                    Button {
                        onSetDueDate?(Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: Date())))
                    } label: {
                        Label("In 1 Week", systemImage: "calendar")
                    }
                    if task.dueDate != nil {
                        Divider()
                        Button { onSetDueDate?(nil) } label: {
                            Label("Remove Due Date", systemImage: "xmark")
                        }
                    }
                }

                Divider()

                if !isFirst {
                    Button { onMoveUp?() } label: {
                        Label("Move Up", systemImage: "chevron.up")
                    }
                }
                if !isLast {
                    Button { onMoveDown?() } label: {
                        Label("Move Down", systemImage: "chevron.down")
                    }
                }
            }

            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private func iconButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
