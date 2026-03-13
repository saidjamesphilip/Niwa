import SwiftUI

// MARK: - Brand Colors

private enum PillColor {
    static let sage  = Color(red: 129/255, green: 178/255, blue: 154/255)
    static let amber = Color(red: 224/255, green: 172/255, blue: 58/255)
    static let terra = Color(red: 224/255, green: 122/255, blue: 95/255)
}

// MARK: - Undo Target

private enum UndoTarget: Equatable {
    case creatine
    case gym
}

// MARK: - HealthStatusView

struct HealthStatusView: View {
    let healthManager: HealthEventManager

    @State private var undoConfirm: UndoTarget?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                Text("DAILY HABITS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textMuted.opacity(0.6))
                    .tracking(0.8)

                if !showInfo {
                    Text("· tap to log")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.textMuted.opacity(0.4))
                }

                Button {
                    withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                        showInfo.toggle()
                    }
                } label: {
                    Text("?")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(
                            showInfo
                                ? DesignTokens.Colors.secondary
                                : DesignTokens.Colors.textMuted.opacity(0.6)
                        )
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(
                                    showInfo
                                        ? DesignTokens.Colors.secondary.opacity(0.15)
                                        : DesignTokens.Colors.textMuted.opacity(0.1)
                                )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    showInfo
                                        ? DesignTokens.Colors.secondary.opacity(0.3)
                                        : DesignTokens.Colors.textMuted.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, 2)

            // Pills row
            HStack(spacing: DesignTokens.Spacing.sm) {
                waterPill
                standPill
                creatinePill
                gymPill
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.sm)

            // Info popover
            if showInfo {
                infoPopover
                    .transition(
                        AnyTransition.opacity.combined(
                            with: .scale(scale: 0.96, anchor: .top)
                        )
                    )
            }
        }
    }

    // MARK: - Water Pill

    private var waterPill: some View {
        IconPill(color: PillColor.sage, action: { healthManager.confirmWater() }) {
            if healthManager.todayWaterCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11))
                    Text("\(healthManager.todayWaterCount)")
                        .font(.system(size: 11, weight: .semibold))
                }
            } else {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11))
            }
        }
        .help(healthManager.todayWaterCount > 0
              ? "Water: \(healthManager.todayWaterCount) today · +\(XPConstants.waterConfirm) XP"
              : "Log water · +\(XPConstants.waterConfirm) XP · unlimited")
        .accessibilityLabel("Water: \(healthManager.todayWaterCount). Tap to log water.")
    }

    // MARK: - Stand Pill

    @ViewBuilder
    private var standPill: some View {
        if healthManager.isStanding {
            standingActivePill
        } else {
            IconPill(color: PillColor.sage, action: { healthManager.startStanding() }) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 11))
            }
            .help("Start standing · +\(XPConstants.standComplete) XP · milestones at 10/20/30 min")
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
                .padding(.horizontal, 10)
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
        .help("Stop standing · +\(XPConstants.standComplete) XP")
        .accessibilityLabel("Standing active. Tap to stop.")
    }

    // MARK: - Creatine Pill

    private var creatinePill: some View {
        let logged = healthManager.todayCreatineLogged
        let isUndoMode = undoConfirm == .creatine

        return UndoableIconPill(
            color: PillColor.amber,
            logged: logged,
            isUndoMode: isUndoMode,
            icon: "bolt.fill",
            xp: XPConstants.creatineConfirm,
            onLog: { healthManager.confirmCreatine() },
            onTapLogged: { startUndoConfirm(for: .creatine) },
            onConfirmUndo: {
                healthManager.undoCreatine()
                cancelUndo()
            }
        )
        .help(
            isUndoMode ? "Tap to confirm undo"
            : logged ? "Creatine ✓ · tap to undo"
            : "Log creatine · +\(XPConstants.creatineConfirm) XP · once daily"
        )
        .accessibilityLabel(logged ? "Creatine logged. Tap to undo." : "Log creatine")
    }

    // MARK: - Gym Pill

    private var gymPill: some View {
        let logged = healthManager.todayGymLogged
        let isUndoMode = undoConfirm == .gym

        return UndoableIconPill(
            color: PillColor.terra,
            logged: logged,
            isUndoMode: isUndoMode,
            icon: "dumbbell.fill",
            xp: XPConstants.gymConfirm,
            onLog: { healthManager.confirmGym() },
            onTapLogged: { startUndoConfirm(for: .gym) },
            onConfirmUndo: {
                healthManager.undoGym()
                cancelUndo()
            }
        )
        .help(
            isUndoMode ? "Tap to confirm undo"
            : logged ? "Gym ✓ · tap to undo"
            : "Log gym · +\(XPConstants.gymConfirm) XP · once daily"
        )
        .accessibilityLabel(logged ? "Gym logged. Tap to undo." : "Log gym session")
    }

    // MARK: - Info Popover

    private var infoPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Track your daily health habits")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Tap icons to log activities and earn XP. Build consistency to grow your plant.")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineSpacing(2)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
                GridRow {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(PillColor.sage)
                    Text("Water")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("+\(XPConstants.waterConfirm) XP each")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                GridRow {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 11))
                        .foregroundStyle(PillColor.sage)
                    Text("Stand")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("+\(XPConstants.standComplete) XP + milestones")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                GridRow {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(PillColor.amber)
                    Text("Creatine")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("+\(XPConstants.creatineConfirm) XP · 1x daily")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                GridRow {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(PillColor.terra)
                    Text("Gym")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("+\(XPConstants.gymConfirm) XP · 1x daily")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DesignTokens.Colors.secondary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }

    // MARK: - Undo Helpers

    private func startUndoConfirm(for target: UndoTarget) {
        undoDismissTask?.cancel()
        withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
            undoConfirm = target
        }
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
                    undoConfirm = nil
                }
            }
        }
    }

    private func cancelUndo() {
        undoDismissTask?.cancel()
        withAnimation(SwiftUI.Animation.easeOut(duration: 0.15)) {
            undoConfirm = nil
        }
    }

    // MARK: - Time Helpers

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

    private func milestoneBadge(from start: Date, to now: Date) -> Int? {
        let elapsedMinutes = Int(max(0, now.timeIntervalSince(start))) / 60
        let reached = XPConstants.standMilestones.filter { elapsedMinutes >= $0.minutes }
        guard !reached.isEmpty else { return nil }
        return reached.reduce(0) { $0 + $1.bonus }
    }
}

// MARK: - IconPill

/// Compact icon-only pill with hover lift effect.
private struct IconPill<Label: View>: View {
    let color: Color
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(color)
                .frame(minWidth: 20, minHeight: 16)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
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

// MARK: - UndoableIconPill

/// Icon pill that shows logged/undo states for once-daily actions.
private struct UndoableIconPill: View {
    let color: Color
    let logged: Bool
    let isUndoMode: Bool
    let icon: String
    let xp: Int
    let onLog: () -> Void
    let onTapLogged: () -> Void
    let onConfirmUndo: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            if isUndoMode {
                onConfirmUndo()
            } else if logged {
                onTapLogged()
            } else {
                onLog()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))

                if isUndoMode {
                    Text("Undo −\(xp)")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundStyle(isUndoMode ? DesignTokens.Colors.danger : color)
            .opacity(logged && !isUndoMode ? 0.4 : 1.0)
            .frame(minWidth: 20, minHeight: 16)
            .padding(.vertical, 5)
            .padding(.horizontal, isUndoMode ? 10 : 8)
            .background(
                Capsule()
                    .fill(
                        isUndoMode
                            ? DesignTokens.Colors.danger.opacity(0.15)
                            : color.opacity(0.12)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isUndoMode
                            ? DesignTokens.Colors.danger.opacity(0.4)
                            : color.opacity(0.25),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .offset(y: isHovered ? -1 : 0)
        .brightness(isHovered ? 0.15 : 0)
        .animation(SwiftUI.Animation.easeOut(duration: 0.2), value: isHovered)
        .animation(SwiftUI.Animation.easeOut(duration: 0.15), value: isUndoMode)
        .animation(SwiftUI.Animation.easeOut(duration: 0.15), value: logged)
    }
}
