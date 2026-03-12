import SwiftUI
import SwiftData

/// Combined top section: plant visualization, XP bar, and compact timer side-by-side
struct HeroView: View {
    @Query private var profiles: [UserProfile]
    let engine: PomodoroTimerEngine

    private var profile: UserProfile? { profiles.first }
    private var level: Int { profile?.currentLevel ?? 0 }
    private var totalXP: Int { profile?.totalXP ?? 0 }

    private var progress: (current: Int, needed: Int) {
        let result = XPConstants.xpForNextLevel(currentTotalXP: totalXP)
        return (current: result.currentLevelXP, needed: result.nextLevelXP)
    }

    private var fillFraction: Double {
        guard progress.needed > 0 else { return 0 }
        return Double(progress.current) / Double(progress.needed)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Plant + Timer
            HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                // Plant + level info
                VStack(spacing: DesignTokens.Spacing.xs) {
                    PlantView(level: level)

                    Text("Level \(level)")
                        .font(DesignTokens.Typography.headingFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(plantStageName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)

                // Divider line
                Rectangle()
                    .fill(DesignTokens.Colors.subtle)
                    .frame(width: 1, height: 100)

                // Compact timer
                compactTimer
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.sm)

            // XP Bar (full width, bigger)
            xpBar
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Compact Timer

    private var compactTimer: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Timer ring
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.viewTransition, value: engine.progress)

                VStack(spacing: 0) {
                    Text(engine.formattedTime)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundStyle(
                            engine.state == .paused
                                ? DesignTokens.Colors.textMuted
                                : DesignTokens.Colors.primary
                        )
                        .monospacedDigit()

                    if engine.state != .idle {
                        Text(sessionLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }
            }

            // Controls
            HStack(spacing: DesignTokens.Spacing.md) {
                switch engine.state {
                case .idle:
                    compactButton(icon: "play.fill", label: "Start") { engine.start() }

                case .working:
                    compactButton(icon: "pause.fill", label: "Pause") { engine.pause() }
                    compactButton(icon: "forward.fill", label: "Skip") { engine.skip() }

                case .paused:
                    compactButton(icon: "play.fill", label: "Resume") { engine.resume() }
                    compactButton(icon: "forward.fill", label: "Skip") { engine.skip() }

                case .shortBreak, .longBreak:
                    compactButton(icon: "forward.fill", label: "Skip") { engine.skip() }
                }
            }

            if engine.state != .idle {
                Text("\(engine.completedWorkSessions % engine.sessionsBeforeLongBreak) of \(engine.sessionsBeforeLongBreak)")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
        }
    }

    private var sessionLabel: String {
        switch engine.state {
        case .idle: return ""
        case .working, .paused: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    private func compactButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.Colors.primary)
                .frame(width: 32, height: 32)
                .background(DesignTokens.Colors.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - XP Bar

    private var xpBar: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text("\(progress.current) / \(progress.needed) XP")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Spacer()

                Text("\(Int(fillFraction * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.Colors.subtle)
                        .frame(height: 12)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.primary,
                                    DesignTokens.Colors.primary.opacity(0.7),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * fillFraction), height: 12)
                        .animation(DesignTokens.Animation.xpBarFill, value: fillFraction)
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: - Plant Stage Name

    private var plantStageName: String {
        switch level {
        case 0: return "Seed"
        case 1...3: return "Sprout"
        case 4...7: return "Seedling"
        case 8...12: return "Young Plant"
        case 13...18: return "Bush"
        case 19...25: return "Small Tree"
        case 26...35: return "Full Tree"
        default: return "Ancient Tree"
        }
    }
}
