import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: NiwaWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            // Top: same as medium layout
            HStack(spacing: 12) {
                // Timer side
                VStack(spacing: 4) {
                    Image(systemName: entry.plantIconName)
                        .font(.system(size: 16))
                        .foregroundStyle(WidgetDesignTokens.primary)

                    if entry.timerActive, let start = entry.timerStartDate, let end = entry.timerEndDate {
                        Text(timerInterval: start...end, countsDown: true)
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(WidgetDesignTokens.primary)
                            .monospacedDigit()

                        Text(entry.sessionLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(WidgetDesignTokens.textSecondary)
                    } else {
                        Text("--:--")
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundStyle(WidgetDesignTokens.textMuted)
                    }

                    Text("Lv \(entry.currentLevel)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Tasks side
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
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        healthPill(icon: "drop.fill", text: "\(entry.waterCount)")
                        if entry.isStanding {
                            healthPill(icon: "figure.stand", text: "Up")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // XP Sparkline
            VStack(alignment: .leading, spacing: 4) {
                Text("XP — Last 7 Days")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetDesignTokens.textSecondary)

                WidgetXPSparkline(data: entry.last7DaysXP)
                    .frame(height: 50)
            }

            // XP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetDesignTokens.xpTrack)
                        .frame(height: 4)
                    Capsule()
                        .fill(WidgetDesignTokens.primary)
                        .frame(width: geo.size.width * entry.xpProgress, height: 4)
                }
            }
            .frame(height: 4)
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
