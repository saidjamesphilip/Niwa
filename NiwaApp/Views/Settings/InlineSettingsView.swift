import SwiftUI
import SwiftData
import AppKit

struct InlineSettingsView: View {
    let profileManager: UserProfileManager
    let timerEngine: PomodoroTimerEngine
    let healthManager: HealthEventManager

    @State private var showResetConfirmation = false
    @State private var showFullResetConfirmation = false
    @State private var statusMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let profile = profileManager.profile {

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
                        settingsStepper("\u{1F4A7} Water every", value: profile.waterIntervalMinutes, unit: "min", range: 5...120, step: 5) {
                            profile.waterIntervalMinutes = $0; saveHealth()
                        }
                        settingsStepper("\u{1F9CD} Stand every", value: profile.standIntervalMinutes, unit: "min", range: 5...120, step: 5) {
                            profile.standIntervalMinutes = $0; saveHealth()
                        }
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

                    // Window
                    settingsSection("\u{1FA9F}  Floating Window") {
                        settingsToggle("Always on top", isOn: profile.alwaysOnTop) {
                            profile.alwaysOnTop = $0; save()
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
                        dataRow(icon: "arrow.counterclockwise", label: "Reset All Data", color: DesignTokens.Colors.danger, description: "Clears tasks, notes, clipboard, XP. Keeps settings.") {
                            showResetConfirmation = true
                        }

                        Divider().background(DesignTokens.Colors.subtle)

                        // Full restart
                        dataRow(icon: "leaf", label: "Full Restart \u{2014} Back to Seed", color: DesignTokens.Colors.danger, description: "Wipes everything and restarts fresh from Level 0. Cannot be undone.") {
                            showFullResetConfirmation = true
                        }
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
        .alert("Reset All Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAllData() }
        } message: {
            Text("This will permanently delete all tasks, notes, clipboard history, timer sessions, health events, and XP. Your settings will be kept. The app will restart.")
        }
        .alert("Full Restart \u{2014} Back to Seed?", isPresented: $showFullResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Restart from Seed", role: .destructive) { fullRestart() }
        } message: {
            Text("This will wipe everything and return you to Level 0 with a fresh seed. All data, XP, and settings will be permanently deleted. The app will restart.")
        }
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
    private func saveHealth() { profileManager.save(); healthManager.scheduleNextReminders() }

    private func resetAllData() {
        let context = profileManager.context
        do {
            try context.delete(model: NiwaTask.self)
            try context.delete(model: NiwaNote.self)
            try context.delete(model: ClipboardEntry.self)
            try context.delete(model: TimerSession.self)
            try context.delete(model: HealthEvent.self)
            try context.delete(model: XPEvent.self)
            if let profile = profileManager.profile {
                profile.totalXP = 0
                profile.currentLevel = 0
            }
            try context.save()
            NotificationManager.shared.cancelAllPending()
            restartApp()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func fullRestart() {
        let context = profileManager.context
        do {
            try context.delete(model: NiwaTask.self)
            try context.delete(model: NiwaNote.self)
            try context.delete(model: ClipboardEntry.self)
            try context.delete(model: TimerSession.self)
            try context.delete(model: HealthEvent.self)
            try context.delete(model: XPEvent.self)
            try context.delete(model: UserProfile.self)
            context.insert(UserProfile())
            try context.save()
            NotificationManager.shared.cancelAllPending()
            restartApp()
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func restartApp() {
        let url = Bundle.main.bundleURL
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", url.path]
        try? task.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

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
            statusMessage = "Exported to \(url.lastPathComponent)"
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
