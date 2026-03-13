import SwiftUI
import SwiftData

/// Combined top section: plant with XP ring, and compact timer side-by-side
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
        HStack(alignment: .center, spacing: 0) {
            // Plant with XP ring
            plantWithXPRing
                .frame(maxWidth: .infinity)

            // Divider line
            Rectangle()
                .fill(DesignTokens.Colors.subtle)
                .frame(width: 1, height: 110)

            // Compact timer
            compactTimer
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Plant with XP Ring

    private var plantWithXPRing: some View {
        VStack(spacing: 4) {
            ZStack {
                // XP ring track
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 80, height: 80)

                // XP ring fill
                Circle()
                    .trim(from: 0, to: fillFraction)
                    .stroke(
                        DesignTokens.Colors.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.xpBarFill, value: fillFraction)

                // Plant inside the ring
                PlantView(level: level)
                    .scaleEffect(0.75)
            }

            // Level + XP info
            Text("Level \(level)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("\(progress.current)/\(progress.needed) XP")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textMuted)
        }
    }

    // MARK: - Compact Timer

    private var compactTimer: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            // Timer ring
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.viewTransition, value: engine.progress)

                VStack(spacing: 0) {
                    Text(engine.formattedTime)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
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
            HStack(spacing: DesignTokens.Spacing.sm) {
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
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Colors.primary)
                .frame(width: 28, height: 28)
                .background(DesignTokens.Colors.primary.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Plant Stage Name

    private var plantStageName: String {
        XPConstants.plantStageName(for: level)
    }
}
