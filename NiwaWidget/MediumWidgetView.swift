import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: NiwaWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: Timer
            VStack(spacing: 4) {
                Image(systemName: entry.plantIconName)
                    .font(.system(size: 16))
                    .foregroundStyle(WidgetDesignTokens.primary)

                if entry.timerActive, let start = entry.timerStartDate, let end = entry.timerEndDate {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundStyle(WidgetDesignTokens.primary)
                        .monospacedDigit()

                    Text(entry.sessionLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetDesignTokens.textSecondary)
                } else {
                    Text("--:--")
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundStyle(WidgetDesignTokens.textMuted)
                }

                Text("Lv \(entry.currentLevel)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetDesignTokens.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Tasks + Health
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.topTasks.prefix(3).enumerated()), id: \.offset) { _, task in
                    HStack(spacing: 4) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(task.isCompleted
                                ? WidgetDesignTokens.secondary
                                : WidgetDesignTokens.textMuted)
                        Text(task.title)
                            .font(.system(size: 11))
                            .foregroundStyle(WidgetDesignTokens.textPrimary)
                            .lineLimit(1)
                    }
                }

                if entry.topTasks.isEmpty {
                    Text("No tasks")
                        .font(.system(size: 11))
                        .foregroundStyle(WidgetDesignTokens.textMuted)
                }

                Spacer()

                // Health pills
                HStack(spacing: 6) {
                    healthPill(icon: "drop.fill", text: "\(entry.waterCount)")
                    if entry.isStanding {
                        healthPill(icon: "figure.stand", text: "Up")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .containerBackground(WidgetDesignTokens.background, for: .widget)
    }

    private func healthPill(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 9))
        }
        .foregroundStyle(WidgetDesignTokens.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(WidgetDesignTokens.secondary.opacity(0.15))
        .clipShape(Capsule())
    }
}
