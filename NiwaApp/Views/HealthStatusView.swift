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
                .help("Start standing session (+10 XP)")
            }

            // Creatine pill (once daily)
            Button { healthManager.confirmCreatine() } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                    if healthManager.todayCreatineLogged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                    } else {
                        Text("Creatine")
                            .font(DesignTokens.Typography.captionFont)
                    }
                }
                .foregroundStyle(creatineColor)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(creatineColor.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(healthManager.todayCreatineLogged)
            .accessibilityLabel(healthManager.todayCreatineLogged ? "Creatine logged today" : "Log creatine")
            .help(healthManager.todayCreatineLogged ? "Creatine logged today" : "Log creatine (+15 XP) · Once daily")

            // Gym pill (once daily)
            Button { healthManager.confirmGym() } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11))
                    if healthManager.todayGymLogged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                    } else {
                        Text("Gym")
                            .font(DesignTokens.Typography.captionFont)
                    }
                }
                .foregroundStyle(gymColor)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(gymColor.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(healthManager.todayGymLogged)
            .accessibilityLabel(healthManager.todayGymLogged ? "Gym logged today" : "Log gym session")
            .help(healthManager.todayGymLogged ? "Gym logged today" : "Log gym session (+30 XP) · Once daily")

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Colors

    private var creatineColor: Color {
        healthManager.todayCreatineLogged
            ? Color(red: 224/255, green: 172/255, blue: 58/255).opacity(0.5)
            : Color(red: 224/255, green: 172/255, blue: 58/255) // Amber
    }

    private var gymColor: Color {
        healthManager.todayGymLogged
            ? DesignTokens.Colors.primary.opacity(0.5)
            : DesignTokens.Colors.primary // Terracotta
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
