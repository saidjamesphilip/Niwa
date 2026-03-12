import SwiftUI
import SwiftData
import AppKit

@main
struct NiwaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    let gamificationEngine: GamificationEngine
    let taskManager: TaskManager
    let timerEngine: PomodoroTimerEngine
    let noteManager: NoteManager
    let clipboardMonitor: ClipboardMonitor
    let profileManager: UserProfileManager
    let healthManager: HealthEventManager

    init() {
        do {
            modelContainer = try ModelContainerSetup.createContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        let context = ModelContext(modelContainer)

        // Seed default UserProfile on first launch
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? context.fetch(descriptor)) ?? []
        if profiles.isEmpty {
            context.insert(UserProfile())
            try? context.save()
        }

        // Create all managers
        let engine = GamificationEngine(modelContext: context)
        gamificationEngine = engine
        taskManager = TaskManager(modelContext: context, gamificationEngine: engine)
        timerEngine = PomodoroTimerEngine(modelContext: context, gamificationEngine: engine)
        noteManager = NoteManager(modelContext: context, gamificationEngine: engine)
        clipboardMonitor = ClipboardMonitor(modelContext: context)

        let profMgr = UserProfileManager(modelContext: context)
        profileManager = profMgr
        healthManager = HealthEventManager(
            modelContext: context,
            gamificationEngine: engine,
            profileManager: profMgr
        )

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
                gamificationEngine: gamificationEngine,
                taskManager: taskManager,
                timerEngine: timerEngine,
                noteManager: noteManager,
                clipboardMonitor: clipboardMonitor,
                healthManager: healthManager,
                profileManager: profileManager
            )
            .modelContainer(modelContainer)
        } label: {
            MenuBarIcon()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarIcon: View {
    @Query private var profiles: [UserProfile]

    private var iconName: String {
        let level = profiles.first?.currentLevel ?? 0
        switch level {
        case 0...5: return "leaf.circle"
        case 6...15: return "leaf"
        case 16...30: return "leaf.fill"
        default: return "tree"
        }
    }

    var body: some View {
        Image(systemName: iconName)
    }
}
