import SwiftUI

struct DropdownRootView: View {
    let appErrorState: AppErrorState
    let gamificationEngine: GamificationEngine
    let timerEngine: FocusTimerEngine
    let healthManager: HealthEventManager
    let profileManager: UserProfileManager
    let soundManager: SoundManager

    let taskManager: TaskManager
    let noteManager: NoteManager
    let calendarManager: CalendarManager

    @State private var showLevelUp = false
    @State private var showSettings = false
    @State private var showSounds = false
    @State private var showWelcome = false
    @State private var showGreeting = false
    @State private var greetingMessage = ""
    @State private var resetStatusMessage = ""
    @State private var isExpanded = false
    @State private var mainContentHeight: CGFloat = 0

    private var screenHeight: CGFloat { NSScreen.main?.visibleFrame.height ?? 900 }
    private var contentMaxHeight: CGFloat { isExpanded ? screenHeight * 0.45 : screenHeight * 0.27 }

    private var profile: UserProfile? { profileManager.profile }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if showSettings {
                    navigationHeader(title: "Settings") { showSettings = false }
                    InlineSettingsView(
                        profileManager: profileManager,
                        timerEngine: timerEngine,
                        healthManager: healthManager,
                        onResetData: { resetAllData() },
                        statusMessage: resetStatusMessage
                    )
                    .frame(height: mainContentHeight > 0 ? mainContentHeight : contentMaxHeight)
                } else if showSounds {
                    navigationHeader(title: "Sounds") { showSounds = false }
                    SoundsView(
                        soundManager: soundManager,
                        profileManager: profileManager
                    )
                    .frame(height: mainContentHeight > 0 ? mainContentHeight : contentMaxHeight)
                } else {
                    if showGreeting {
                        GreetingBanner(message: greetingMessage, isVisible: $showGreeting)
                    }
                    mainContent
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: MainContentHeightKey.self, value: geo.size.height)
                            }
                        )
                        .onPreferenceChange(MainContentHeightKey.self) { height in
                            mainContentHeight = height
                        }
                }

                Divider()
                    .background(DesignTokens.Colors.subtle)

                bottomToolbar
            }
            .frame(width: 400)
            .background(DesignTokens.Colors.background)

            LevelUpOverlay(
                level: profileManager.profile?.currentLevel ?? 1,
                previousLevel: gamificationEngine.previousLevel,
                isVisible: showLevelUp,
                onDismiss: { showLevelUp = false }
            )

            WelcomeOverlay(isVisible: $showWelcome) { name in
                if let profile = profileManager.profile {
                    profile.displayName = name
                    profile.lastGreetingDate = Date()
                    profileManager.save()
                }
            }
        }
        .onChange(of: gamificationEngine.levelUpCount) { _, _ in
            showLevelUp = true
            soundManager.play(.levelUp)
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
            soundManager.play(.xpEarned)
        }
        .onChange(of: timerEngine.state) { _, newState in
            if newState == .complete {
                soundManager.play(.timerComplete)
            }
        }
    }

    private func checkFirstLaunchAndGreeting() {
        guard let profile = profile else { return }

        // First launch — show welcome and seed demo content
        if profile.displayName.isEmpty && profile.lastGreetingDate == nil {
            if taskManager.tasks.isEmpty {
                profileManager.seedDemoContent()
                taskManager.refreshTasks()
                noteManager.refreshNotes()
            }
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
        showGreeting = true
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

            ContentTabView(taskManager: taskManager, noteManager: noteManager, calendarManager: calendarManager, contentMaxHeight: contentMaxHeight)

            Divider()
                .background(DesignTokens.Colors.subtle)

            HealthStatusView(healthManager: healthManager)

            Divider()
                .background(DesignTokens.Colors.subtle)

            XPChartView(xpEvents: gamificationEngine.recentXPEvents)
        }
    }

    // MARK: - Navigation Header

    private func navigationHeader(title: String, onBack: @escaping () -> Void) -> some View {
        HStack {
            Button {
                onBack()
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

            Text(title)
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
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
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
                isExpanded.toggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.up.2" : "chevron.down.2")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Show Less" : "Show More")
            .help(isExpanded ? "Show Less" : "Show More")

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
                showSounds.toggle()
                showSettings = false
            } label: {
                Image(systemName: showSounds ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: 14))
                    .foregroundStyle(showSounds ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sounds")
            .help("Sounds")

            Button {
                showSettings.toggle()
                showSounds = false
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
        if profileManager.resetAllData() {
            NotificationManager.shared.cancelAllPending()
            timerEngine.forceReset()
            healthManager.stopStanding()
            healthManager.reloadStats()
            profileManager.seedDemoContent()
            taskManager.refreshTasks()
            noteManager.refreshNotes()
            resetStatusMessage = "All data reset. Fresh start!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSettings = false
                showWelcome = true
                resetStatusMessage = ""
            }
        } else {
            resetStatusMessage = "Reset failed. Please try again."
        }
    }
}

private struct MainContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
