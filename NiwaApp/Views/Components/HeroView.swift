import SwiftUI
import SwiftData

/// Combined top section: plant with XP ring, and focus timer side-by-side
struct HeroView: View {
    @Query private var profiles: [UserProfile]
    let engine: FocusTimerEngine

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

    @State private var customMinutes: Int = 25

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            plantWithXPRing
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(DesignTokens.Colors.subtle)
                .frame(width: 1, height: 120)

            focusTimer
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Plant with XP Ring

    private var plantWithXPRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: fillFraction)
                    .stroke(
                        DesignTokens.Colors.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.xpBarFill, value: fillFraction)

                PlantView(level: level)
                    .scaleEffect(0.75)
            }

            Text("Level \(level)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("\(progress.current)/\(progress.needed) XP")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textMuted)
        }
    }

    // MARK: - Focus Timer

    @ViewBuilder
    private var focusTimer: some View {
        switch engine.state {
        case .idle:
            idleView
        case .focusing:
            focusingView
        case .complete:
            completeView
        }
    }

    // MARK: - Idle State

    private var idleView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Preset chips
            HStack(spacing: 4) {
                ForEach(engine.presets, id: \.self) { minutes in
                    Button {
                        engine.start(minutes: minutes)
                    } label: {
                        Text("\(minutes)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.primary)
                            .frame(minWidth: 32, minHeight: 32)
                            .padding(.horizontal, 6)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primary.opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(DesignTokens.Colors.primary.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("\(minutes) min focus · +\(minutes * XPConstants.focusXPPerMinute) XP")
                }
            }

            // Custom duration row
            HStack(spacing: 4) {
                Button {
                    customMinutes = max(1, customMinutes - 5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(DesignTokens.Colors.backgroundSecondary))
                }
                .buttonStyle(.plain)

                Text("\(customMinutes) min")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 40)

                Button {
                    customMinutes = min(120, customMinutes + 5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(DesignTokens.Colors.backgroundSecondary))
                }
                .buttonStyle(.plain)

                Button {
                    engine.start(minutes: customMinutes)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(DesignTokens.Colors.primary.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .help("Start \(customMinutes) min focus")
            }

            // Streak dots
            if engine.todayCompletedSessions > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(engine.todayCompletedSessions, 10), id: \.self) { _ in
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 5, height: 5)
                    }
                    if engine.todayCompletedSessions > 10 {
                        Text("+\(engine.todayCompletedSessions - 10)")
                            .font(.system(size: 8))
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                    }
                }
            } else {
                Text("No sessions today")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
        }
    }

    // MARK: - Focusing State

    private var focusingView: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
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
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .monospacedDigit()

                    Text("\(engine.selectedMinutes) min")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Button {
                engine.cancel()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Complete State

    private var completeView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            Text("+\(engine.lastAwardedXP) XP")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
    }

    // MARK: - Plant Stage Name

    private var plantStageName: String {
        XPConstants.plantStageName(for: level)
    }
}
