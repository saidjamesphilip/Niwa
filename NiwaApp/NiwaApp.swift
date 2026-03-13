import SwiftUI
import SwiftData
import AppKit

@main
struct NiwaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    let appErrorState: AppErrorState
    let gamificationEngine: GamificationEngine
    let taskManager: TaskManager
    let timerEngine: PomodoroTimerEngine
    let noteManager: NoteManager
    let profileManager: UserProfileManager
    let healthManager: HealthEventManager
    let reminderTimerManager: ReminderTimerManager
    let soundManager: SoundManager

    init() {
        do {
            modelContainer = try ModelContainerSetup.createContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        let context = modelContainer.mainContext
        print("[NiwaApp] Using mainContext: \(context)")
        print("[NiwaApp] Store URL: \(modelContainer.configurations.first?.url.path ?? "unknown")")

        // Seed default UserProfile on first launch
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        if profiles.isEmpty {
            context.insert(UserProfile())
            do {
                try context.save()
            } catch {
                // Retry once
                do {
                    try context.save()
                } catch {
                    print("[NiwaApp] UserProfile seed failed: \(error)")
                }
            }
            // Verify it persisted
            let verify = (try? context.fetch(descriptor)) ?? []
            if verify.isEmpty {
                print("[NiwaApp] WARNING: UserProfile not persisted, running in degraded mode")
            }
        }

        // Create all managers
        let errorState = AppErrorState()
        appErrorState = errorState
        let engine = GamificationEngine(modelContext: context)
        gamificationEngine = engine
        taskManager = TaskManager(modelContext: context, gamificationEngine: engine, appErrorState: errorState)
        timerEngine = PomodoroTimerEngine(modelContext: context, gamificationEngine: engine)
        noteManager = NoteManager(modelContext: context, gamificationEngine: engine, appErrorState: errorState)

        let profMgr = UserProfileManager(modelContext: context)
        profileManager = profMgr
        let hm = HealthEventManager(
            modelContext: context,
            gamificationEngine: engine,
            profileManager: profMgr
        )
        healthManager = hm
        let rtm = ReminderTimerManager(profileManager: profMgr, healthManager: hm)
        reminderTimerManager = rtm
        soundManager = SoundManager(modelContext: context)

        // Wire ALL notification callbacks
        let nm = NotificationManager.shared

        // Water: Done = confirm water + reset timer
        nm.onWaterDone = {
            Task { @MainActor in hm.confirmWater(); rtm.waterDone() }
        }
        // Water: Snooze = snooze timer only
        nm.onWaterSnooze = {
            Task { @MainActor in rtm.waterSnoozed() }
        }
        // Water: Dismissed = reset timer (treat as acknowledged)
        nm.onWaterDismissed = {
            Task { @MainActor in rtm.waterDismissed() }
        }
        // Stand: Stand Up = start standing + reset timer
        nm.onStandUp = {
            Task { @MainActor in hm.startStanding(); rtm.standDone() }
        }
        // Stand: Snooze = snooze timer only
        nm.onStandSnooze = {
            Task { @MainActor in rtm.standSnoozed() }
        }
        // Stand: Dismissed = reset timer
        nm.onStandDismissed = {
            Task { @MainActor in rtm.standDismissed() }
        }
        // Stand: Sit Down = stop standing
        nm.onSitDown = {
            Task { @MainActor in hm.stopStanding() }
        }

        // Apply saved appearance mode
        if let mode = profMgr.profile?.appearanceMode {
            switch mode {
            case 1: NSApp.appearance = NSAppearance(named: .aqua)
            case 2: NSApp.appearance = NSAppearance(named: .darkAqua)
            default: break
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            DropdownRootView(
                appErrorState: appErrorState,
                gamificationEngine: gamificationEngine,
                timerEngine: timerEngine,
                healthManager: healthManager,
                profileManager: profileManager,
                soundManager: soundManager
            )
            .environmentObject(taskManager)
            .environmentObject(noteManager)
            .modelContainer(modelContainer)
        } label: {
            MenuBarIcon(timerEngine: timerEngine)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarIcon: View {
    let timerEngine: PomodoroTimerEngine

    private var isActive: Bool {
        timerEngine.state != .idle
    }

    private var isPaused: Bool {
        timerEngine.state == .paused
    }

    private var isBreak: Bool {
        timerEngine.state == .shortBreak || timerEngine.state == .longBreak
    }

    private var isUrgent: Bool {
        timerEngine.remainingSeconds < 180 && timerEngine.remainingSeconds > 0
    }

    private var timerColor: Color {
        if isUrgent {
            return Color(red: 224/255, green: 122/255, blue: 95/255) // Niwa primary/terracotta
        } else if isBreak {
            return Color(red: 90/255, green: 200/255, blue: 250/255) // Break blue
        } else {
            return Color(red: 76/255, green: 217/255, blue: 100/255) // Focus green
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image("MenuBarIcon")
                .renderingMode(.template)

            if isActive {
                VStack(spacing: 1) {
                    Text(timerEngine.formattedTime)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(isPaused ? .secondary : .primary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.white.opacity(0.15))
                                .frame(height: 2)

                            RoundedRectangle(cornerRadius: 1)
                                .fill(timerColor)
                                .frame(width: max(0, geo.size.width * (1.0 - timerEngine.progress)), height: 2)
                        }
                    }
                    .frame(width: 40, height: 2)
                }
            }
        }
    }
}
