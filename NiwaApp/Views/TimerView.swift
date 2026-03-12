import SwiftUI

struct TimerView: View {
    let engine: PomodoroTimerEngine

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Timer display with progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.viewTransition, value: engine.progress)

                // Time text
                Text(engine.formattedTime)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(
                        engine.state == .paused
                            ? DesignTokens.Colors.textMuted
                            : DesignTokens.Colors.primary
                    )
                    .monospacedDigit()
            }

            // Session info
            if engine.state != .idle {
                Text(sessionLabel)
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("\(engine.completedWorkSessions % engine.sessionsBeforeLongBreak) of \(engine.sessionsBeforeLongBreak)")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }

            // Controls
            HStack(spacing: DesignTokens.Spacing.lg) {
                switch engine.state {
                case .idle:
                    timerButton(icon: "play.fill", label: "Start") {
                        engine.start()
                    }

                case .working:
                    timerButton(icon: "pause.fill", label: "Pause") {
                        engine.pause()
                    }
                    timerButton(icon: "forward.fill", label: "Skip") {
                        engine.skip()
                    }

                case .paused:
                    timerButton(icon: "play.fill", label: "Resume") {
                        engine.resume()
                    }
                    timerButton(icon: "forward.fill", label: "Skip") {
                        engine.skip()
                    }

                case .shortBreak, .longBreak:
                    timerButton(icon: "forward.fill", label: "Skip Break") {
                        engine.skip()
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var sessionLabel: String {
        switch engine.state {
        case .idle: return ""
        case .working, .paused: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    private func timerButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(DesignTokens.Typography.captionFont)
            }
            .foregroundStyle(DesignTokens.Colors.primary)
            .frame(minWidth: 48, minHeight: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
