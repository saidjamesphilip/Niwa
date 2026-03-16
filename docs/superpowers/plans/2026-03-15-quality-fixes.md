# Quality Fixes Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 13 issues across performance, reliability, UX, and code quality in three priority tiers.

**Architecture:** Independent fixes grouped by priority. Each tier produces a commit. No new files except `NiwaShared/Constants/WidgetDesignTokens.swift`. Most changes are surgical edits to existing files.

**Tech Stack:** Swift, SwiftUI, SwiftData, WidgetKit, macOS 15+, XcodeGen

**Spec:** `docs/superpowers/specs/2026-03-15-quality-fixes-design.md`

---

## Chunk 1: Tier 1 — High Priority (Performance & Reliability)

### Task 1: Quit warning during active focus timer

**Files:**
- Modify: `NiwaApp/AppDelegate.swift`
- Modify: `NiwaApp/NiwaApp.swift`

- [ ] **Step 1: Add timerEngine reference and applicationShouldTerminate to AppDelegate**

Replace entire `AppDelegate.swift`:

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var timerEngine: FocusTimerEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setup()
        NotificationManager.shared.requestPermission()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let engine = timerEngine, engine.state == .focusing {
            let alert = NSAlert()
            alert.messageText = "Focus session in progress"
            alert.informativeText = "You have an active focus timer. Quitting will lose your progress and XP for this session."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit Anyway")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationManager.shared.cancelAllPending()
    }
}
```

- [ ] **Step 2: Wire timerEngine in NiwaApp.init()**

In `NiwaApp/NiwaApp.swift`, add this line after `soundManager = SoundManager(modelContext: context)` (line 72) and before the notification callbacks section:

```swift
        appDelegate.timerEngine = timerEngine
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 2: HealthEventManager.loadTodayStats() — push date into predicate

**Files:**
- Modify: `NiwaApp/Services/HealthEventManager.swift:183-201`

- [ ] **Step 1: Replace loadTodayStats() with date-filtered predicate**

Replace the `loadTodayStats()` method (lines 183-201) with:

```swift
    private func loadTodayStats() {
        let dayStart = Self.habitDayStart()

        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate<HealthEvent> { event in
                event.confirmedAt != nil && event.confirmedAt >= dayStart
            }
        )
        guard let todayEvents = try? modelContext.fetch(descriptor) else { return }

        todayWaterCount = todayEvents.filter { $0.typeRaw == HealthEventType.water.rawValue }.count
        todayCreatineLogged = todayEvents.contains { $0.typeRaw == HealthEventType.creatine.rawValue }
        todayGymLogged = todayEvents.contains { $0.typeRaw == HealthEventType.gym.rawValue }
        todayCoffeeCount = todayEvents.filter { $0.typeRaw == HealthEventType.coffee.rawValue }.count
    }
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 3: XPChartView — pass pre-filtered events from parent

**Files:**
- Modify: `NiwaApp/Views/Components/XPChartView.swift:4-5`
- Modify: `NiwaApp/Views/DropdownRootView.swift:168`

- [ ] **Step 1: Change XPChartView to accept events as a parameter**

In `XPChartView.swift`, replace:
```swift
struct XPChartView: View {
    @Query private var xpEvents: [XPEvent]
```

With:
```swift
struct XPChartView: View {
    let xpEvents: [XPEvent]
```

- [ ] **Step 2: Pass filtered events from DropdownRootView**

In `DropdownRootView.swift`, add a helper computed property after the existing `profile` computed property (line 28):

```swift
    private var recentXPEvents: [XPEvent] {
        let calendar = Calendar.current
        let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: calendar.startOfDay(for: Date()))!
        let descriptor = FetchDescriptor<XPEvent>(
            predicate: #Predicate<XPEvent> { $0.earnedAt >= eightDaysAgo }
        )
        return (try? profileManager.context.fetch(descriptor)) ?? []
    }
```

Then change the `XPChartView()` call in `mainContent` (line 168) from:
```swift
            XPChartView()
```
To:
```swift
            XPChartView(xpEvents: recentXPEvents)
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 4: Cache UserProfileManager.profile

**Files:**
- Modify: `NiwaApp/Services/UserProfileManager.swift`

- [ ] **Step 1: Replace computed profile with cached property**

Replace entire `UserProfileManager.swift`:

```swift
import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class UserProfileManager {
    let context: ModelContext
    private(set) var cachedProfile: UserProfile?

    init(modelContext: ModelContext) {
        self.context = modelContext
        self.cachedProfile = Self.fetchProfile(from: modelContext)
    }

    var profile: UserProfile? { cachedProfile }

    func isWithinWorkHours(date: Date = Date()) -> Bool {
        guard let profile else { return false }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let current = hour * 60 + minute
        let start = profile.workHoursStartHour * 60 + profile.workHoursStartMinute
        let end = profile.workHoursEndHour * 60 + profile.workHoursEndMinute
        return current >= start && current < end
    }

    func isLunchTime(date: Date = Date()) -> Bool {
        guard let profile else { return false }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let current = hour * 60 + minute
        let start = profile.lunchStartHour * 60 + profile.lunchStartMinute
        let end = profile.lunchEndHour * 60 + profile.lunchEndMinute
        return current >= start && current < end
    }

    func save() {
        try? context.save()
    }

    /// Re-fetch profile from store (call after reset)
    func reload() {
        cachedProfile = Self.fetchProfile(from: context)
    }

    private static func fetchProfile(from context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? context.fetch(descriptor).first
    }
}
```

- [ ] **Step 2: Add reload() call after reset in DropdownRootView**

In `DropdownRootView.swift`, in the `resetAllData()` function, after `context.insert(UserProfile())` and `try context.save()` (line 352-353), add:

```swift
            profileManager.reload()
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 5: Cache widget ModelContainer

**Files:**
- Modify: `NiwaWidget/NiwaTimelineProvider.swift:5,24-27`

- [ ] **Step 1: Add static container and use in createEntry()**

Add a static property before the `placeholder` method:

```swift
    private static let sharedContainer: ModelContainer? = {
        try? ModelContainerSetup.createContainer()
    }()
```

Then replace the first two lines of `createEntry()`:
```swift
            let container = try ModelContainerSetup.createContainer()
            let context = ModelContext(container)
```
With:
```swift
            guard let container = Self.sharedContainer else { return .placeholder }
            let context = ModelContext(container)
```

And change the `do {` to just the `guard` (removing the do/catch around the whole function since we now guard at the top). Actually, keep the do/catch — we just change the container line inside.

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 6: Fix widget day-start to use 7am

**Files:**
- Modify: `NiwaShared/Constants/XPConstants.swift`
- Modify: `NiwaApp/Services/HealthEventManager.swift:173-181`
- Modify: `NiwaWidget/NiwaTimelineProvider.swift:78-85`

- [ ] **Step 1: Add habitDayStart to XPConstants**

Add this at the end of `XPConstants` (before the closing `}`):

```swift
    /// Daily habits reset at 7am, not midnight
    static func habitDayStart(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let sevenAM = calendar.date(byAdding: .hour, value: 7, to: startOfDay)!
        return date < sevenAM
            ? calendar.date(byAdding: .day, value: -1, to: sevenAM)!
            : sevenAM
    }
```

- [ ] **Step 2: Update HealthEventManager to use shared function**

In `HealthEventManager.swift`, replace the `habitDayStart` method (lines 172-181) with:

```swift
    /// Daily habits reset at 7am, not midnight
    static func habitDayStart(for date: Date = Date()) -> Date {
        XPConstants.habitDayStart(for: date)
    }
```

- [ ] **Step 3: Update widget water count to use 7am day-start**

In `NiwaTimelineProvider.swift`, replace lines 78-85:
```swift
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let waterType = HealthEventType.water.rawValue
            let waterDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { $0.typeRaw == waterType && $0.confirmedAt != nil }
            )
            let waterEvents = try context.fetch(waterDescriptor)
            let waterCount = waterEvents.filter { ($0.confirmedAt ?? .distantPast) >= startOfDay }.count
```
With:
```swift
            let dayStart = XPConstants.habitDayStart()
            let waterType = HealthEventType.water.rawValue
            let waterDescriptor = FetchDescriptor<HealthEvent>(
                predicate: #Predicate<HealthEvent> { $0.typeRaw == waterType && $0.confirmedAt != nil && $0.confirmedAt >= dayStart }
            )
            let waterCount = try context.fetchCount(waterDescriptor)
```

Also update the XP events section (lines 94-105) to use the same filtered approach:
```swift
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            let xpDescriptor = FetchDescriptor<XPEvent>(
                predicate: #Predicate<XPEvent> { $0.earnedAt >= sevenDaysAgo }
            )
            let recentXPEvents = try context.fetch(xpDescriptor)
            var last7DaysXP = [Int](repeating: 0, count: 7)
            for event in recentXPEvents {
                let dayIndex = calendar.dateComponents([.day], from: sevenDaysAgo, to: event.earnedAt).day ?? 0
                if dayIndex >= 0 && dayIndex < 7 {
                    last7DaysXP[dayIndex] += event.amount
                }
            }
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit Tier 1**

```bash
git add -A && git commit -m "fix: tier 1 — quit warning, predicate perf, profile cache, widget fixes"
```

---

## Chunk 2: Tier 2 — Medium Priority (UX & Correctness)

### Task 7: Fix GamificationEngine.didLevelUp race condition

**Files:**
- Modify: `NiwaShared/Engines/GamificationEngine.swift`
- Modify: `NiwaApp/Views/DropdownRootView.swift`

- [ ] **Step 1: Replace didLevelUp boolean with levelUpCount integer**

In `GamificationEngine.swift`:

Replace line 10:
```swift
    private(set) var didLevelUp: Bool = false
```
With:
```swift
    private(set) var levelUpCount: Int = 0
```

Replace line 43:
```swift
        didLevelUp = leveledUp
```
With:
```swift
        if leveledUp { levelUpCount += 1 }
```

Delete the `resetLevelUpFlag()` method (lines 74-76):
```swift
    func resetLevelUpFlag() {
        didLevelUp = false
    }
```

- [ ] **Step 2: Update DropdownRootView to use levelUpCount**

In `DropdownRootView.swift`, replace the `onChange(of: gamificationEngine.didLevelUp)` block (lines 88-94):
```swift
        .onChange(of: gamificationEngine.didLevelUp) { _, newValue in
            if newValue {
                showLevelUp = true
                soundManager.play(.levelUp)
                gamificationEngine.resetLevelUpFlag()
            }
        }
```
With:
```swift
        .onChange(of: gamificationEngine.levelUpCount) { _, _ in
            showLevelUp = true
            soundManager.play(.levelUp)
        }
```

Also update the XP sound guard (line 104) from:
```swift
            if !gamificationEngine.didLevelUp {
```
To:
```swift
            if gamificationEngine.levelUpCount == 0 || oldXP != nil {
```

Wait — that guard logic needs to stay conceptually the same: don't play the xp-earned sound if a level-up just happened (the level-up sound plays instead). The simplest approach: track the count locally.

Actually, the original logic checks `didLevelUp` which was immediately reset. With the counter approach, we need a different guard. The cleanest fix: just let both sounds play (level-up already plays, xp-earned is a softer sound — it's fine). Or keep a `@State` tracking last-seen count. Let's keep it simple and just remove the guard:

Replace lines 102-107:
```swift
        .onChange(of: profile?.totalXP) { oldXP, newXP in
            guard let oldXP, let newXP, newXP > oldXP else { return }
            if !gamificationEngine.didLevelUp {
                soundManager.play(.xpEarned)
            }
        }
```
With:
```swift
        .onChange(of: profile?.totalXP) { oldXP, newXP in
            guard let oldXP, let newXP, newXP > oldXP else { return }
            soundManager.play(.xpEarned)
        }
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 8: Notification permission indicator in settings

**Files:**
- Modify: `NiwaApp/Views/Settings/InlineSettingsView.swift`

- [ ] **Step 1: Add permission state tracking**

Add at the top of `InlineSettingsView`, after `@StateObject private var updateChecker = UpdateChecker()`:

```swift
    @State private var notificationPermission: String = "checking"
```

- [ ] **Step 2: Add permission check function**

Add after the `saveHealth()` function (line 525):

```swift
    private func checkNotificationPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                switch settings.authorizationStatus {
                case .authorized, .provisional: notificationPermission = "allowed"
                case .denied: notificationPermission = "blocked"
                default: notificationPermission = "unknown"
                }
            }
        }
    }
```

Add `import UserNotifications` at the top of the file.

- [ ] **Step 3: Add permission pill next to the System Settings link**

Replace the "Manage in System Settings" button block (lines 129-143) with:

```swift
                        HStack(spacing: DesignTokens.Spacing.sm) {
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

                            Spacer()

                            if notificationPermission == "allowed" {
                                Text("Allowed")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.Colors.secondary.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else if notificationPermission == "blocked" {
                                Text("Blocked")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .onAppear { checkNotificationPermission() }
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit Tier 2**

```bash
git add -A && git commit -m "fix: tier 2 — level-up race condition, notification permission indicator"
```

---

## Chunk 3: Tier 3 — Low Priority (Code Quality)

### Task 9: Migrate TaskManager, NoteManager, and UpdateChecker to @Observable

**Files:**
- Modify: `NiwaApp/Services/TaskManager.swift`
- Modify: `NiwaApp/Services/NoteManager.swift`
- Modify: `NiwaApp/Services/UpdateChecker.swift`
- Modify: `NiwaApp/NiwaApp.swift`
- Modify: `NiwaApp/Views/DropdownRootView.swift`
- Modify: `NiwaApp/Views/ContentTabView.swift`
- Modify: `NiwaApp/Views/TaskListView.swift`
- Modify: `NiwaApp/Views/NotesListView.swift`
- Modify: `NiwaApp/Views/Settings/InlineSettingsView.swift`

- [ ] **Step 1: Migrate TaskManager**

In `TaskManager.swift`:
- Replace `import Combine` with `import Observation`
- Replace `final class TaskManager: ObservableObject {` with `@Observable\nfinal class TaskManager {`
- Replace `@Published private(set) var tasks: [NiwaTask] = []` with `private(set) var tasks: [NiwaTask] = []`

- [ ] **Step 2: Migrate NoteManager**

In `NoteManager.swift`:
- Replace `import Combine` with `import Observation`
- Replace `final class NoteManager: ObservableObject {` with `@Observable\nfinal class NoteManager {`
- Replace `@Published private(set) var notes: [NiwaNote] = []` with `private(set) var notes: [NiwaNote] = []`

- [ ] **Step 3: Migrate UpdateChecker**

In `UpdateChecker.swift`:
- Add `import Observation`
- Replace `final class UpdateChecker: ObservableObject {` with `@Observable\nfinal class UpdateChecker {`
- Replace all 4 `@Published` lines with just `var` (remove `@Published`)

In `InlineSettingsView.swift`:
- Replace `@StateObject private var updateChecker = UpdateChecker()` with `@State private var updateChecker = UpdateChecker()`

- [ ] **Step 4: Update NiwaApp to pass managers as parameters instead of environmentObject**

In `NiwaApp.swift`, replace lines 117-128:
```swift
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
```
With:
```swift
            DropdownRootView(
                appErrorState: appErrorState,
                gamificationEngine: gamificationEngine,
                timerEngine: timerEngine,
                healthManager: healthManager,
                profileManager: profileManager,
                soundManager: soundManager,
                taskManager: taskManager,
                noteManager: noteManager
            )
            .modelContainer(modelContainer)
```

- [ ] **Step 5: Update DropdownRootView to use let parameters**

In `DropdownRootView.swift`, replace lines 12-13:
```swift
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var noteManager: NoteManager
```
With:
```swift
    let taskManager: TaskManager
    let noteManager: NoteManager
```

Update `ContentTabView` call in `mainContent` to pass managers:
```swift
            ContentTabView(taskManager: taskManager, noteManager: noteManager, contentMaxHeight: contentMaxHeight)
```

- [ ] **Step 6: Update ContentTabView**

Replace lines 8-10:
```swift
struct ContentTabView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var noteManager: NoteManager
```
With:
```swift
struct ContentTabView: View {
    let taskManager: TaskManager
    let noteManager: NoteManager
```

Update the tab content to pass managers:
```swift
            case .tasks:
                TaskListView(taskManager: taskManager, contentMaxHeight: contentMaxHeight)
            case .notes:
                NotesListView(noteManager: noteManager, contentMaxHeight: contentMaxHeight)
```

- [ ] **Step 7: Update TaskListView**

Replace line 7:
```swift
    @EnvironmentObject var taskManager: TaskManager
```
With:
```swift
    let taskManager: TaskManager
```

Move it above `contentMaxHeight` so the call site reads naturally: `TaskListView(taskManager:, contentMaxHeight:)`.

- [ ] **Step 8: Update NotesListView**

Replace line 7:
```swift
    @EnvironmentObject var noteManager: NoteManager
```
With:
```swift
    let noteManager: NoteManager
```

Move it above `contentMaxHeight`.

- [ ] **Step 9: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 10: PlantView — deduplicate stage logic

**Files:**
- Modify: `NiwaApp/Views/Components/PlantView.swift`

- [ ] **Step 1: Replace private PlantStage with XPConstants.PlantStage**

Delete the private enum (lines 361-363):
```swift
    private enum PlantStage {
        case seed, sprout, seedling, youngPlant, bush, smallTree, fullTree, ancientTree
    }
```

Replace the `stage` computed property (lines 10-21):
```swift
    private var stage: PlantStage {
        switch level {
        case 0: return .seed
        case 1...3: return .sprout
        case 4...7: return .seedling
        case 8...12: return .youngPlant
        case 13...18: return .bush
        case 19...25: return .smallTree
        case 26...35: return .fullTree
        default: return .ancientTree
        }
    }
```
With:
```swift
    private var stage: XPConstants.PlantStage {
        XPConstants.plantStage(for: level)
    }
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 11: Widget design tokens

**Files:**
- Create: `NiwaShared/Constants/WidgetDesignTokens.swift`
- Modify: `NiwaWidget/SmallWidgetView.swift`
- Modify: `NiwaWidget/MediumWidgetView.swift`
- Modify: `NiwaWidget/LargeWidgetView.swift`
- Modify: `NiwaWidget/WidgetXPSparkline.swift`

- [ ] **Step 1: Create WidgetDesignTokens**

Create `NiwaShared/Constants/WidgetDesignTokens.swift`:

```swift
import SwiftUI

enum WidgetDesignTokens {
    // Brand colors
    static let primary = Color(red: 224/255, green: 122/255, blue: 95/255)      // Terracotta
    static let secondary = Color(red: 129/255, green: 178/255, blue: 154/255)   // Sage

    // Text colors
    static let textPrimary = Color(red: 61/255, green: 50/255, blue: 41/255)
    static let textSecondary = Color(red: 122/255, green: 110/255, blue: 99/255)
    static let textMuted = Color(red: 168/255, green: 155/255, blue: 140/255)

    // Backgrounds
    static let background = Color(red: 250/255, green: 246/255, blue: 241/255)  // Cream
    static let xpTrack = Color(red: 212/255, green: 197/255, blue: 178/255)
}
```

- [ ] **Step 2: Replace all inline colors in widget views**

In all 4 widget files, replace each `Color(red:green:blue:)` with the matching `WidgetDesignTokens` constant. Use find-and-replace:

| Inline color | Token |
|---|---|
| `Color(red: 224/255, green: 122/255, blue: 95/255)` | `WidgetDesignTokens.primary` |
| `Color(red: 129/255, green: 178/255, blue: 154/255)` | `WidgetDesignTokens.secondary` |
| `Color(red: 61/255, green: 50/255, blue: 41/255)` | `WidgetDesignTokens.textPrimary` |
| `Color(red: 122/255, green: 110/255, blue: 99/255)` | `WidgetDesignTokens.textSecondary` |
| `Color(red: 168/255, green: 155/255, blue: 140/255)` | `WidgetDesignTokens.textMuted` |
| `Color(red: 250/255, green: 246/255, blue: 241/255)` | `WidgetDesignTokens.background` |
| `Color(red: 212/255, green: 197/255, blue: 178/255)` | `WidgetDesignTokens.xpTrack` |

Note: `Color(red: 224/255, green: 172/255, blue: 58/255)` (amber) appears nowhere in widget files, so no token needed.

- [ ] **Step 3: Regenerate Xcode project (new file added)**

Run: `xcodegen generate`

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 12: Remove dead schema fields

**Files:**
- Modify: `NiwaShared/Models/TimerSession.swift`
- Modify: `NiwaShared/Models/HealthEvent.swift`
- Modify: `NiwaWidget/NiwaTimelineProvider.swift`

- [ ] **Step 1: Remove pausedElapsed from TimerSession and legacy SessionType cases**

In `TimerSession.swift`, replace `SessionType` enum:
```swift
enum SessionType: String, Codable {
    case work        // Legacy
    case shortBreak  // Legacy
    case longBreak   // Legacy
    case focus       // New
}
```
With:
```swift
enum SessionType: String, Codable {
    case focus
}
```

Remove `var pausedElapsed: TimeInterval` from the model (line 20).
Remove `self.pausedElapsed = 0` from the init (line 35).

- [ ] **Step 2: Remove snoozedUntil from HealthEvent**

In `HealthEvent.swift`, remove `var snoozedUntil: Date?` (line 17).
Remove `self.snoozedUntil = nil` from the init (line 30).

- [ ] **Step 3: Update widget timer switch**

In `NiwaTimelineProvider.swift`, replace lines 61-65:
```swift
                switch session.type {
                case .work, .focus: sessionLabel = "Focus"
                case .shortBreak: sessionLabel = "Short Break"
                case .longBreak: sessionLabel = "Long Break"
                }
```
With:
```swift
                sessionLabel = "Focus"
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 13: Add HealthEvent and TimerSession to JSON export

**Files:**
- Modify: `NiwaApp/Views/Settings/InlineSettingsView.swift`

- [ ] **Step 1: Add health events and timer sessions to export**

In `InlineSettingsView.swift`, in the `exportData()` function, after the `xpEvents` section (line 541) and before the `profiles` section, add:

```swift
            let healthEvents = try context.fetch(FetchDescriptor<HealthEvent>())
            export["healthEvents"] = healthEvents.map {
                var dict: [String: Any] = ["type": $0.typeRaw]
                if let confirmed = $0.confirmedAt { dict["confirmedAt"] = confirmed.ISO8601Format() }
                if let standStart = $0.standingStartedAt { dict["standingStartedAt"] = standStart.ISO8601Format() }
                if let standDuration = $0.standingDuration { dict["standingDuration"] = standDuration }
                return dict
            }
            let timerSessions = try context.fetch(FetchDescriptor<TimerSession>())
            export["timerSessions"] = timerSessions.map {
                var dict: [String: Any] = [
                    "type": $0.typeRaw,
                    "durationMinutes": $0.durationMinutes,
                    "startedAt": $0.startedAt.ISO8601Format(),
                    "wasSkipped": $0.wasSkipped
                ]
                if let completed = $0.completedAt { dict["completedAt"] = completed.ISO8601Format() }
                return dict
            }
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit Tier 3**

```bash
git add -A && git commit -m "fix: tier 3 — @Observable migration, dedup PlantView, widget tokens, clean schema, full export"
```

Then regenerate Xcode project:
```bash
xcodegen generate
```
