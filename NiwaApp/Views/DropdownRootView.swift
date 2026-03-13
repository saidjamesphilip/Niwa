import SwiftUI
import SwiftData

struct DropdownRootView: View {
    let appErrorState: AppErrorState
    let gamificationEngine: GamificationEngine
    let timerEngine: PomodoroTimerEngine
    let healthManager: HealthEventManager
    let profileManager: UserProfileManager
    let soundManager: SoundManager

    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var noteManager: NoteManager

    @State private var showLevelUp = false
    @State private var showSettings = false
    @State private var showSounds = false
    @State private var showWelcome = false
    @State private var showGreeting = false
    @State private var greetingMessage = ""
    @State private var resetStatusMessage = ""

    private var profile: UserProfile? { profileManager.profile }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if showSettings {
                    settingsHeader
                    InlineSettingsView(
                        profileManager: profileManager,
                        timerEngine: timerEngine,
                        healthManager: healthManager,
                        onResetData: { resetAllData() },
                        onFullRestart: { fullRestart() },
                        statusMessage: resetStatusMessage
                    )
                } else if showSounds {
                    soundsHeader
                    SoundsView(
                        soundManager: soundManager,
                        profileManager: profileManager
                    )
                } else {
                    if showGreeting {
                        GreetingBanner(message: greetingMessage, isVisible: $showGreeting)
                    }
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
                onDismiss: {
                    showLevelUp = false
                    soundManager.play(.levelUp)
                }
            )

            WelcomeOverlay(isVisible: $showWelcome) { name in
                if let profile = profileManager.profile {
                    profile.displayName = name
                    profile.lastGreetingDate = Date()
                    profileManager.save()
                }
            }
        }
        .onChange(of: gamificationEngine.didLevelUp) { _, newValue in
            if newValue {
                showLevelUp = true
                gamificationEngine.resetLevelUpFlag()
            }
        }
        .onAppear {
            NotificationManager.shared.isDropdownVisible = true
            checkFirstLaunchAndGreeting()
        }
        .onDisappear {
            NotificationManager.shared.isDropdownVisible = false
        }
        .onChange(of: profile?.totalXP) { oldXP, newXP in
            guard let oldXP, let newXP, newXP > oldXP else { return }
            if !gamificationEngine.didLevelUp {
                soundManager.play(.xpEarned)
            }
        }
        .onChange(of: timerEngine.state) { oldState, newState in
            // Work session just completed → moved to break
            if oldState == .working && (newState == .shortBreak || newState == .longBreak) {
                soundManager.play(.timerComplete)
            }
            // Break just completed → back to idle
            if (oldState == .shortBreak || oldState == .longBreak) && newState == .idle {
                soundManager.play(.breakComplete)
            }
        }
    }

    private func checkFirstLaunchAndGreeting() {
        guard let profile = profile else { return }

        // First launch — show welcome
        if profile.displayName.isEmpty && profile.lastGreetingDate == nil {
            showWelcome = true
            return
        }

        // Daily greeting — check if we've greeted today
        let today = Calendar.current.startOfDay(for: Date())
        if let lastGreeting = profile.lastGreetingDate,
           Calendar.current.startOfDay(for: lastGreeting) == today {
            return // Already greeted today
        }

        // Show greeting
        greetingMessage = GreetingMessages.randomGreeting(name: profile.displayName)
        withAnimation(DesignTokens.Animation.viewTransition) {
            showGreeting = true
        }
        profile.lastGreetingDate = Date()
        profileManager.save()
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            if let message = appErrorState.bannerMessage {
                ErrorBannerView(message: message) {
                    appErrorState.dismiss()
                }
            }

            HeroView(engine: timerEngine)

            Divider()
                .background(DesignTokens.Colors.subtle)

            ContentTabView()

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

    // MARK: - Sounds Header

    private var soundsHeader: some View {
        HStack {
            Button {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSounds = false
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

            Text("Sounds")
                .font(DesignTokens.Typography.headingFont)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

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
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.3.10")")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textMuted)

            #if DEBUG
            Text("DEV")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.orange.cornerRadius(3))
            #endif

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
                    showSounds.toggle()
                    showSettings = false
                }
            } label: {
                Image(systemName: showSounds ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: 14))
                    .foregroundStyle(showSounds ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sounds")
            .help("Sounds")

            Button {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings.toggle()
                    showSounds = false
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
            timerEngine.skip()
            taskManager.refreshTasks()
            noteManager.refreshNotes()
            resetStatusMessage = "Data reset successfully!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings = false
                    resetStatusMessage = ""
                }
            }
        } catch {
            resetStatusMessage = "Reset failed: \(error.localizedDescription)"
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
            timerEngine.skip()
            taskManager.refreshTasks()
            noteManager.refreshNotes()
            resetStatusMessage = "Fresh start! Back to seed."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings = false
                    showWelcome = true
                    resetStatusMessage = ""
                }
            }
        } catch {
            resetStatusMessage = "Restart failed: \(error.localizedDescription)"
        }
    }
}
