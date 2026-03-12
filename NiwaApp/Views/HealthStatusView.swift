import SwiftUI

struct HealthStatusView: View {
    let healthManager: HealthEventManager

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Water pill
            Button { healthManager.confirmWater() } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11))
                    Text("\(healthManager.todayWaterCount)")
                        .font(DesignTokens.Typography.captionFont)
                }
                .foregroundStyle(DesignTokens.Colors.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.secondary.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Water: \(healthManager.todayWaterCount). Tap to log water.")
            .help("Log water (+10 XP)")

            // Standing pill
            if healthManager.isStanding {
                standingActivePill
            } else {
                Button { healthManager.startStanding() } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 11))
                        Text("Stand")
                            .font(DesignTokens.Typography.captionFont)
                    }
                    .foregroundStyle(DesignTokens.Colors.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.secondary.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start standing")
                .help("Start standing session")
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // Live-updating standing timer using TimelineView
    private var standingActivePill: some View {
        Button { healthManager.stopStanding() } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 11))
                        .symbolEffect(.pulse)

                    if let start = healthManager.standingStartedAt {
                        Text(formatDuration(from: start, to: context.date))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .monospacedDigit()
                    }

                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 10))
                }
                .foregroundStyle(DesignTokens.Colors.secondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.secondary.opacity(0.25))
                .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Standing. Tap to sit down.")
        .help("Stop standing (+10 XP)")
    }

    private func formatDuration(from start: Date, to now: Date) -> String {
        let elapsed = Int(max(0, now.timeIntervalSince(start)))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
