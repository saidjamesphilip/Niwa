import SwiftUI

// MARK: - Undo Target

private enum UndoTarget: Equatable {
    case creatine
    case gym
}

// MARK: - Brand Colors

private enum PillColor {
    static let sage  = Color(red: 129/255, green: 178/255, blue: 154/255)
    static let amber = Color(red: 224/255, green: 172/255, blue: 58/255)
    static let terra = Color(red: 224/255, green: 122/255, blue: 95/255)
}

// MARK: - HealthStatusView

struct HealthStatusView: View {
    let healthManager: HealthEventManager

    @State private var showUndoTooltip: UndoTarget?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var creatineHovered = false
    @State private var gymHovered = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            waterPill
            standPill
            creatinePill
            gymPill
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        // Tapping the background row dismisses any open tooltip
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                showUndoTooltip = nil
            }
            undoDismissTask?.cancel()
        }
    }

    // MARK: - Water Pill

    private var waterPill: some View {
        PillButton(color: PillColor.sage, action: { healthManager.confirmWater() }) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11))
                if healthManager.todayWaterCount == 0 {
                    Text("Water +\(XPConstants.waterConfirm)")
                        .font(DesignTokens.Typography.captionFont)
                } else {
                    Text("\(healthManager.todayWaterCount)")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
        }
        .help("Log water (+\(XPConstants.waterConfirm) XP)")
        .accessibilityLabel("Water: \(healthManager.todayWaterCount). Tap to log water.")
    }

    // MARK: - Stand Pill

    @ViewBuilder
    private var standPill: some View {
        if healthManager.isStanding {
            standingActivePill
        } else {
            PillButton(color: PillColor.sage, action: { healthManager.startStanding() }) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 11))
                    Text("Stand +\(XPConstants.standComplete)")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
            .help("Start standing session (+\(XPConstants.standComplete) XP)")
            .accessibilityLabel("Start standing")
        }
    }

    private var standingActivePill: some View {
        Button {
            healthManager.stopStanding()
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 4) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 11))
                        .symbolEffect(.pulse)

                    if let start = healthManager.standingStartedAt {
                        Text(formatDuration(from: start, to: context.date))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .monospacedDigit()

                        if let badge = milestoneBadge(from: start, to: context.date) {
                            Text("+\(badge)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(PillColor.sage)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(PillColor.sage.opacity(0.2))
                                )
                        }
                    }
                }
                .foregroundStyle(PillColor.sage)
                .padding(.vertical, 5)
                .padding(.horizontal, 11)
                .background(
                    Capsule()
                        .fill(PillColor.sage.opacity(0.25))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(PillColor.sage.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
        .help("Stop standing (+\(XPConstants.standComplete) XP)")
        .accessibilityLabel("Standing active. Tap to stop.")
    }

    // MARK: - Creatine Pill

    private var creatinePill: some View {
        let logged = healthManager.todayCreatineLogged
        return Button {
            if logged {
                scheduleUndoTooltip(for: .creatine)
            } else {
                healthManager.confirmCreatine()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                if logged {
                    Text("✓")
                        .font(DesignTokens.Typography.captionFont)
                } else {
                    Text("Creatine +\(XPConstants.creatineConfirm)")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
            .foregroundStyle(PillColor.amber)
            .opacity(logged ? 0.45 : 1.0)
            .padding(.vertical, 5)
            .padding(.horizontal, 11)
            .background(
                Capsule()
                    .fill(PillColor.amber.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(PillColor.amber.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { creatineHovered = $0 }
        .offset(y: creatineHovered ? -1 : 0)
        .brightness(creatineHovered ? 0.15 : 0)
        .animation(SwiftUI.Animation.easeOut(duration: 0.2), value: creatineHovered)
        .overlay(alignment: Alignment.top) {
            if showUndoTooltip == .creatine {
                undoTooltip(label: "Undo Creatine? −\(XPConstants.creatineConfirm) XP", color: PillColor.amber) {
                    healthManager.undoCreatine()
                    withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                        showUndoTooltip = nil
                    }
                    undoDismissTask?.cancel()
                }
                .transition(
                    AnyTransition.opacity.combined(
                        with: .scale(scale: 0.92, anchor: UnitPoint.bottom)
                    )
                )
                .offset(y: -30)
            }
        }
        .animation(SwiftUI.Animation.easeOut(duration: 0.15), value: showUndoTooltip)
        .help(logged ? "Creatine logged · tap to undo" : "Log creatine (+\(XPConstants.creatineConfirm) XP) · Once daily")
        .accessibilityLabel(logged ? "Creatine logged today. Tap to undo." : "Log creatine")
    }

    // MARK: - Gym Pill

    private var gymPill: some View {
        let logged = healthManager.todayGymLogged
        return Button {
            if logged {
                scheduleUndoTooltip(for: .gym)
            } else {
                healthManager.confirmGym()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 11))
                if logged {
                    Text("✓")
                        .font(DesignTokens.Typography.captionFont)
                } else {
                    Text("Gym +\(XPConstants.gymConfirm)")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
            .foregroundStyle(PillColor.terra)
            .opacity(logged ? 0.45 : 1.0)
            .padding(.vertical, 5)
            .padding(.horizontal, 11)
            .background(
                Capsule()
                    .fill(PillColor.terra.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(PillColor.terra.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { gymHovered = $0 }
        .offset(y: gymHovered ? -1 : 0)
        .brightness(gymHovered ? 0.15 : 0)
        .animation(SwiftUI.Animation.easeOut(duration: 0.2), value: gymHovered)
        .overlay(alignment: Alignment.top) {
            if showUndoTooltip == .gym {
                undoTooltip(label: "Undo Gym? −\(XPConstants.gymConfirm) XP", color: PillColor.terra) {
                    healthManager.undoGym()
                    withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                        showUndoTooltip = nil
                    }
                    undoDismissTask?.cancel()
                }
                .transition(
                    AnyTransition.opacity.combined(
                        with: .scale(scale: 0.92, anchor: UnitPoint.bottom)
                    )
                )
                .offset(y: -30)
            }
        }
        .animation(SwiftUI.Animation.easeOut(duration: 0.15), value: showUndoTooltip)
        .help(logged ? "Gym logged · tap to undo" : "Log gym session (+\(XPConstants.gymConfirm) XP) · Once daily")
        .accessibilityLabel(logged ? "Gym logged today. Tap to undo." : "Log gym session")
    }

    // MARK: - Undo Tooltip

    @ViewBuilder
    private func undoTooltip(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0x3D/255, green: 0x34/255, blue: 0x29/255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(color.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .zIndex(10)
    }

    // MARK: - Helpers

    private func scheduleUndoTooltip(for target: UndoTarget) {
        undoDismissTask?.cancel()
        withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
            showUndoTooltip = target
        }
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                    showUndoTooltip = nil
                }
            }
        }
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

    /// Returns the cumulative milestone bonus once the highest threshold is reached.
    private func milestoneBadge(from start: Date, to now: Date) -> Int? {
        let elapsedMinutes = Int(max(0, now.timeIntervalSince(start))) / 60
        let reached = XPConstants.standMilestones.filter { elapsedMinutes >= $0.minutes }
        guard !reached.isEmpty else { return nil }
        return reached.reduce(0) { $0 + $1.bonus }
    }
}

// MARK: - PillButton Helper

/// Reusable pill button with hover lift + brightness effect.
private struct PillButton<Label: View>: View {
    let color: Color
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(color)
                .padding(.vertical, 5)
                .padding(.horizontal, 11)
                .background(
                    Capsule()
                        .fill(color.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .offset(y: isHovered ? -1 : 0)
        .brightness(isHovered ? 0.15 : 0)
        .animation(SwiftUI.Animation.easeOut(duration: 0.2), value: isHovered)
    }
}
