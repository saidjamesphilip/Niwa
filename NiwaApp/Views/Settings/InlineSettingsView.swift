import SwiftUI
import SwiftData
import AppKit

struct InlineSettingsView: View {
    let profileManager: UserProfileManager
    let timerEngine: PomodoroTimerEngine
    let healthManager: HealthEventManager
    let onResetData: () -> Void
    let onFullRestart: () -> Void
    let statusMessage: String

    @State private var confirmingReset = false
    @State private var confirmingFullRestart = false
    @State private var exportMessage = ""
    @StateObject private var updateChecker = UpdateChecker()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let profile = profileManager.profile {

                    // Profile
                    settingsSection("\u{1F331}  Profile") {
                        HStack {
                            Text("Name")
                                .font(DesignTokens.Typography.bodyFont)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            Spacer()
                            TextField("Your name", text: Binding(
                                get: { profile.displayName },
                                set: { profile.displayName = $0; profileManager.save() }
                            ))
                            .textFieldStyle(.plain)
                            .font(DesignTokens.Typography.bodyFont)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    }

                    // Timer
                    settingsSection("\u{23F1}\u{FE0F}  Timer") {
                        settingsStepper("Work", value: profile.pomoDurationMinutes, unit: "min", range: 1...120) {
                            profile.pomoDurationMinutes = $0; saveTimer()
                        }
                        settingsStepper("Short Break", value: profile.shortBreakMinutes, unit: "min", range: 1...60) {
                            profile.shortBreakMinutes = $0; saveTimer()
                        }
                        settingsStepper("Long Break", value: profile.longBreakMinutes, unit: "min", range: 1...60) {
                            profile.longBreakMinutes = $0; saveTimer()
                        }
                        settingsStepper("Sessions before long break", value: profile.sessionsBeforeLongBreak, unit: "", range: 1...10) {
                            profile.sessionsBeforeLongBreak = $0; saveTimer()
                        }
                    }

                    // Health
                    settingsSection("\u{1F49A}  Health Reminders") {
                        settingsToggle("Enable Reminders", isOn: profile.healthRemindersEnabled) {
                            profile.healthRemindersEnabled = $0; saveHealth()
                        }

                        if profile.healthRemindersEnabled {
                            settingsStepper("\u{1F4A7} Water every", value: profile.waterIntervalMinutes, unit: "min", range: 5...120, step: 5) {
                                profile.waterIntervalMinutes = $0; saveHealth()
                            }
                            settingsStepper("\u{1F9CD} Stand every", value: profile.standIntervalMinutes, unit: "min", range: 5...120, step: 5) {
                                profile.standIntervalMinutes = $0; saveHealth()
                            }
                        }

                        Button {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings")!)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 11))
                                Text("Manage in System Settings")
                                    .font(.system(size: 11))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 8))
                            }
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    }

                    // Work Hours
                    settingsSection("\u{1F4BC}  Work Hours") {
                        timeRow("Start", hour: profile.workHoursStartHour, minute: profile.workHoursStartMinute) { h, m in
                            profile.workHoursStartHour = h; profile.workHoursStartMinute = m; saveHealth()
                        }
                        timeRow("End", hour: profile.workHoursEndHour, minute: profile.workHoursEndMinute) { h, m in
                            profile.workHoursEndHour = h; profile.workHoursEndMinute = m; saveHealth()
                        }
                    }

                    // Lunch
                    settingsSection("\u{1F35C}  Lunch Break") {
                        timeRow("Start", hour: profile.lunchStartHour, minute: profile.lunchStartMinute) { h, m in
                            profile.lunchStartHour = h; profile.lunchStartMinute = m; saveHealth()
                        }
                        timeRow("End", hour: profile.lunchEndHour, minute: profile.lunchEndMinute) { h, m in
                            profile.lunchEndHour = h; profile.lunchEndMinute = m; saveHealth()
                        }
                    }

                    // Appearance
                    settingsSection("\u{1F3A8}  Appearance") {
                        appearancePicker(value: profile.appearanceMode) {
                            profile.appearanceMode = $0; save()
                            applyAppearance($0)
                        }
                    }

                    // Data
                    settingsSection("\u{1F4BE}  Data") {
                        // Export
                        dataRow(icon: "square.and.arrow.up", label: "Export JSON", color: DesignTokens.Colors.primary) {
                            exportData()
                        }

                        Divider().background(DesignTokens.Colors.subtle)

                        // Reset
                        if confirmingReset {
                            confirmationRow(
                                message: "Clear tasks, notes, clipboard, and XP? Settings will be kept.",
                                confirmLabel: "Reset",
                                onConfirm: {
                                    confirmingReset = false
                                    onResetData()
                                },
                                onCancel: { confirmingReset = false }
                            )
                        } else {
                            dataRow(icon: "arrow.counterclockwise", label: "Reset All Data", color: DesignTokens.Colors.danger, description: "Clears tasks, notes, clipboard, XP. Keeps settings.") {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    confirmingReset = true
                                    confirmingFullRestart = false
                                }
                            }
                        }

                        Divider().background(DesignTokens.Colors.subtle)

                        // Full restart
                        if confirmingFullRestart {
                            confirmationRow(
                                message: "Wipe everything and start fresh from Level 0? This cannot be undone.",
                                confirmLabel: "Full Restart",
                                onConfirm: {
                                    confirmingFullRestart = false
                                    onFullRestart()
                                },
                                onCancel: { confirmingFullRestart = false }
                            )
                        } else {
                            dataRow(icon: "leaf", label: "Full Restart \u{2014} Back to Seed", color: DesignTokens.Colors.danger, description: "Wipes everything and restarts fresh from Level 0. Cannot be undone.") {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    confirmingFullRestart = true
                                    confirmingReset = false
                                }
                            }
                        }

                        Divider().background(DesignTokens.Colors.subtle)

                        // Updates (integrated)
                        updateRow
                    }

                    // Status messages
                    if !statusMessage.isEmpty {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text(statusMessage)
                                .font(DesignTokens.Typography.captionFont)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.primary.opacity(0.1))
                    }

                    if !exportMessage.isEmpty {
                        Text(exportMessage)
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }

    // MARK: - Components

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .tracking(0.8)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Divider()
                .background(DesignTokens.Colors.subtle)
                .padding(.top, DesignTokens.Spacing.sm)
        }
    }

    private func settingsStepper(_ label: String, value: Int, unit: String, range: ClosedRange<Int>, step: Int = 1, onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button {
                    onChange(max(range.lowerBound, value - step))
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)

                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 50, alignment: .center)

                Button {
                    onChange(min(range.upperBound, value + step))
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func settingsToggle(_ label: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Spacer()
            Toggle("", isOn: Binding(get: { isOn }, set: { onChange($0) }))
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(DesignTokens.Colors.primary)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func timeRow(_ label: String, hour: Int, minute: Int, onChange: @escaping (Int, Int) -> Void) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Spacer()
            HStack(spacing: DesignTokens.Spacing.xs) {
                Button {
                    onChange((hour - 1 + 24) % 24, minute)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)

                Text(String(format: "%02d:%02d", hour, minute))
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 50, alignment: .center)

                Button {
                    onChange((hour + 1) % 24, minute)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func appearancePicker(value: Int, onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            Text("Theme")
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            HStack(spacing: 2) {
                ForEach(Array(["System", "Light", "Dark"].enumerated()), id: \.offset) { index, label in
                    Button {
                        onChange(index)
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: value == index ? .semibold : .regular))
                            .foregroundStyle(value == index ? DesignTokens.Colors.background : DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .fill(value == index ? DesignTokens.Colors.primary : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small + 2)
                    .fill(DesignTokens.Colors.backgroundSecondary)
            )
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private func dataRow(icon: String, label: String, color: Color, description: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color)

                    if let description {
                        Text(description)
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundStyle(color.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Confirmation Row

    private func confirmationRow(message: String, confirmLabel: String, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button {
                    withAnimation(DesignTokens.Animation.viewTransition) { onCancel() }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(DesignTokens.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm()
                } label: {
                    Text(confirmLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(DesignTokens.Colors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Update Row

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.3.11"
    }

    private var updateRow: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 13))
                .foregroundStyle(updateChecker.updateAvailable ? Color.orange : DesignTokens.Colors.primary)
                .frame(width: 20)

            if updateChecker.isChecking {
                Text("Checking for updates...")
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Spacer()
                ProgressView()
                    .scaleEffect(0.6)
            } else if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(version) available")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("Download") {
                    updateChecker.openDownloadPage()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            } else {
                Button {
                    Task { await updateChecker.checkForUpdates() }
                } label: {
                    Text("Check for updates")
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("v\(currentVersion)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DesignTokens.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Actions

    private func applyAppearance(_ mode: Int) {
        switch mode {
        case 1: NSApp.appearance = NSAppearance(named: .aqua)
        case 2: NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil // follow system
        }
    }

    private func save() { profileManager.save() }
    private func saveTimer() { profileManager.save(); timerEngine.loadSettings() }
    private func saveHealth() { profileManager.save() }

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "niwa-export.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let context = profileManager.context
        do {
            var export: [String: Any] = [:]
            let tasks = try context.fetch(FetchDescriptor<NiwaTask>())
            export["tasks"] = tasks.map { ["id": $0.id.uuidString, "title": $0.title, "isCompleted": $0.isCompleted, "sortOrder": $0.sortOrder] }
            let notes = try context.fetch(FetchDescriptor<NiwaNote>())
            export["notes"] = notes.map { ["id": $0.id.uuidString, "content": $0.content] }
            let xpEvents = try context.fetch(FetchDescriptor<XPEvent>())
            export["xpEvents"] = xpEvents.map { ["source": $0.source.rawValue, "amount": $0.amount, "earnedAt": $0.earnedAt.ISO8601Format()] }
            let profiles = try context.fetch(FetchDescriptor<UserProfile>())
            if let p = profiles.first {
                export["profile"] = ["totalXP": p.totalXP, "currentLevel": p.currentLevel]
            }
            let data = try JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url)
            exportMessage = "Exported to \(url.lastPathComponent)"
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
