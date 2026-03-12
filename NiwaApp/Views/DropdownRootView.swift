import SwiftUI
import SwiftData

struct DropdownRootView: View {
    @Query private var profiles: [UserProfile]

    let gamificationEngine: GamificationEngine
    let taskManager: TaskManager
    let timerEngine: PomodoroTimerEngine
    let noteManager: NoteManager
    let clipboardMonitor: ClipboardMonitor
    let healthManager: HealthEventManager
    let profileManager: UserProfileManager

    @State private var showLevelUp = false
    @State private var showSettings = false
    @State private var floatingWindowController = FloatingWindowController()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if showSettings {
                    settingsHeader
                    InlineSettingsView(
                        profileManager: profileManager,
                        timerEngine: timerEngine,
                        healthManager: healthManager
                    )
                } else {
                    mainContent
                }

                Divider()
                    .background(DesignTokens.Colors.subtle)

                bottomToolbar
            }
            .frame(width: 320)
            .background(DesignTokens.Colors.background)

            LevelUpOverlay(
                level: profile?.currentLevel ?? 0,
                isVisible: showLevelUp,
                onDismiss: { showLevelUp = false }
            )
        }
        .onChange(of: gamificationEngine.didLevelUp) { _, newValue in
            if newValue {
                showLevelUp = true
                gamificationEngine.resetLevelUpFlag()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            HeroView(engine: timerEngine)

            Divider()
                .background(DesignTokens.Colors.subtle)

            ContentTabView(
                taskManager: taskManager,
                noteManager: noteManager,
                clipboardMonitor: clipboardMonitor
            )

            Divider()
                .background(DesignTokens.Colors.subtle)

            HealthStatusView(healthManager: healthManager)

            Divider()
                .background(DesignTokens.Colors.subtle)

            XPChartView()
        }
    }

    // MARK: - Settings Header

    private var settingsHeader: some View {
        HStack {
            Button {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings = false
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(DesignTokens.Typography.captionFont)
                }
                .foregroundStyle(DesignTokens.Colors.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(DesignTokens.Typography.headingFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            // Invisible spacer to balance the back button
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(DesignTokens.Typography.captionFont)
            }
            .opacity(0)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundSecondary)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button {
                toggleFloatingWindow()
            } label: {
                Image(systemName: floatingWindowController.isVisible ? "pip.fill" : "pip")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle floating window")
            .help("Toggle floating window")

            Text("v1.0.0")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textMuted)

            Spacer()

            Button {
                restartApp()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Restart")
            .help("Restart Niwa")

            Button {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: showSettings ? "gear.circle.fill" : "gear")
                    .font(.system(size: 14))
                    .foregroundStyle(showSettings ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .help("Settings")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quit Niwa")
            .help("Quit Niwa")
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Actions

    @Environment(\.modelContext) private var modelContext

    private func toggleFloatingWindow() {
        let contentView = FloatingWindowContentView(timerEngine: timerEngine, taskManager: taskManager)
            .modelContainer(modelContext.container)
        floatingWindowController.toggle(
            contentView: contentView,
            alwaysOnTop: profile?.alwaysOnTop ?? false
        )
    }

    private func restartApp() {
        let url = Bundle.main.bundleURL
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", url.path]
        try? task.run()
        NSApplication.shared.terminate(nil)
    }
}
