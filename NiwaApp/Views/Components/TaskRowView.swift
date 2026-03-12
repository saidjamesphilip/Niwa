import SwiftUI

struct TaskRowView: View {
    let task: NiwaTask
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Custom checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(task.isCompleted ? DesignTokens.Colors.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    task.isCompleted ? DesignTokens.Colors.primary : (isHovering ? DesignTokens.Colors.primary.opacity(0.5) : DesignTokens.Colors.subtle),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 18, height: 18)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) incomplete" : "Complete \(task.title)")

            // Title
            Text(task.title)
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(task.isCompleted ? DesignTokens.Colors.textMuted : DesignTokens.Colors.textPrimary)
                .strikethrough(task.isCompleted, color: DesignTokens.Colors.textMuted.opacity(0.5))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Delete on hover
            if isHovering && !task.isCompleted {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.textMuted.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Delete task")
            }

            // Drag handle on hover
            if isHovering && !task.isCompleted {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill(isHovering ? DesignTokens.Colors.backgroundSecondary.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
