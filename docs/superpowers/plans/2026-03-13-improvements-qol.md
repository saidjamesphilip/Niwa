# Improvements & QOL Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix notification spam, harden fresh-install reliability, redesign health pills with labels/XP/undo, add standing XP milestones, and upgrade the level-up celebration screen.

**Architecture:** Timer-based reminder system replaces broken UNNotification scheduling. Shared AppErrorState surfaces save failures. GamificationEngine gets deductXP for undo. Health pills get inline labels + XP badges. LevelUpOverlay becomes a full-bleed celebration with plant evolution.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, XcodeGen, macOS 15+

**Spec:** `docs/superpowers/specs/2026-03-13-improvements-qol-design.md`

---

## Chunk 1: Foundation & Bug Fixes

### Task 1: Fix Note Color Cycling Bug

**Files:**
- Modify: `NiwaApp/Services/NoteManager.swift:21`

- [ ] **Step 1: Fix operator precedence**

In `NiwaApp/Services/NoteManager.swift`, find line 21:
```swift
let nextColor = (notes.first?.colorIndex ?? -1 + 1) % Self.noteColorCount
```
Replace with:
```swift
let nextColor = ((notes.first?.colorIndex ?? -1) + 1) % Self.noteColorCount
```

- [ ] **Step 2: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Services/NoteManager.swift
git commit -m "fix: note color cycling — operator precedence bug

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Add AppErrorState and Harden Saves

**Files:**
- Create: `NiwaApp/Services/AppErrorState.swift`
- Modify: `NiwaApp/Services/TaskManager.swift`
- Modify: `NiwaApp/Services/NoteManager.swift`
- Modify: `NiwaApp/NiwaApp.swift`
- Create: `NiwaApp/Views/Components/ErrorBannerView.swift`
- Modify: `NiwaApp/Views/DropdownRootView.swift`

- [ ] **Step 1: Create AppErrorState**

Create `NiwaApp/Services/AppErrorState.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppErrorState {
    var bannerMessage: String?

    func showError(_ message: String) {
        bannerMessage = message
    }

    func dismiss() {
        bannerMessage = nil
    }
}
```

- [ ] **Step 2: Create ErrorBannerView**

Create `NiwaApp/Views/Components/ErrorBannerView.swift`:
```swift
import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 224/255, green: 122/255, blue: 95/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDismiss() }
            }
        }
    }
}
```

- [ ] **Step 3: Harden TaskManager.save()**

In `NiwaApp/Services/TaskManager.swift`, find the existing `save()` method (around line 112-117). It currently looks like:
```swift
private func save() {
    do {
        try modelContext.save()
    } catch {
        print("[TaskManager] Save failed: \(error)")
    }
}
```
Replace with:
```swift
private var appErrorState: AppErrorState?

// Add to init — after existing parameters, add:
// self.appErrorState = appErrorState
```

Then update `save()`:
```swift
private func save() {
    do {
        try modelContext.save()
    } catch {
        // Retry once
        do {
            try modelContext.save()
        } catch {
            appErrorState?.showError("Unable to save tasks. Please restart Niwa.")
            print("[TaskManager] Save failed after retry: \(error)")
        }
    }
}
```

Update the `TaskManager.init` signature to accept `appErrorState: AppErrorState`:
```swift
init(modelContext: ModelContext, gamificationEngine: GamificationEngine, appErrorState: AppErrorState) {
    self.modelContext = modelContext
    self.gamificationEngine = gamificationEngine
    self.appErrorState = appErrorState
    refreshTasks()
}
```

- [ ] **Step 4: Harden NoteManager.save()**

In `NiwaApp/Services/NoteManager.swift`, add the `appErrorState` property and update the init:

```swift
@MainActor
final class NoteManager: ObservableObject {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private var appErrorState: AppErrorState?

    @Published private(set) var notes: [NiwaNote] = []

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine, appErrorState: AppErrorState) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        self.appErrorState = appErrorState
        refreshNotes()
    }
```

Replace the `save()` method (lines 48-54) with:
```swift
private func save() {
    do {
        try modelContext.save()
    } catch {
        // Retry once
        do {
            try modelContext.save()
        } catch {
            appErrorState?.showError("Unable to save notes. Please restart Niwa.")
            print("[NoteManager] Save failed after retry: \(error)")
        }
    }
}
```

- [ ] **Step 5: Harden UserProfile seed in NiwaApp.swift**

In `NiwaApp/NiwaApp.swift`, find the UserProfile seeding block (around lines 30-35):
```swift
let profiles = (try? context.fetch(descriptor)) ?? []
if profiles.isEmpty {
    context.insert(UserProfile())
    try? context.save()
}
```
Replace with:
```swift
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
```

- [ ] **Step 6: Wire AppErrorState into NiwaApp.init()**

In `NiwaApp/NiwaApp.swift`, add `let appErrorState: AppErrorState` as a property.

In `init()`, create it before the managers:
```swift
let errorState = AppErrorState()
appErrorState = errorState
```

Update manager creation to pass it:
```swift
taskManager = TaskManager(modelContext: context, gamificationEngine: engine, appErrorState: errorState)
noteManager = NoteManager(modelContext: context, gamificationEngine: engine, appErrorState: errorState)
```

Pass `appErrorState` to `DropdownRootView` as a direct property in the body:
```swift
DropdownRootView(
    gamificationEngine: engine,
    timerEngine: timerEngine,
    healthManager: healthManager,
    profileManager: profMgr,
    soundManager: soundManager,
    appErrorState: errorState   // <-- add this parameter
)
```

- [ ] **Step 7: Add ErrorBannerView to DropdownRootView**

In `NiwaApp/Views/DropdownRootView.swift`, add a property to the struct:
```swift
let appErrorState: AppErrorState
```

Then show the banner at the top of `mainContent`. At the top of the `mainContent` VStack (around line 129), add:
```swift
if let message = appErrorState.bannerMessage {
    ErrorBannerView(message: message) {
        appErrorState.dismiss()
    }
}
```

- [ ] **Step 8: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Services/AppErrorState.swift NiwaApp/Views/Components/ErrorBannerView.swift NiwaApp/Services/TaskManager.swift NiwaApp/Services/NoteManager.swift NiwaApp/NiwaApp.swift NiwaApp/Views/DropdownRootView.swift
git commit -m "feat: add save error handling with retry and error banner

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Add PlantStages Enum and deductXP to GamificationEngine

**Files:**
- Modify: `NiwaShared/Constants/XPConstants.swift`
- Modify: `NiwaShared/Engines/GamificationEngine.swift`
- Modify: `NiwaApp/Views/Components/HeroView.swift`

- [ ] **Step 1: Add PlantStages and standing milestones to XPConstants**

In `NiwaShared/Constants/XPConstants.swift`, add after the existing constants (before the level calculation functions):

```swift
// Standing milestones — cumulative bonuses at time thresholds
static let standMilestones: [(minutes: Int, bonus: Int)] = [
    (10, 5), (20, 10), (30, 15)
]
static let standMaxXP: Int = 40

// Plant stage boundaries
enum PlantStage: String {
    case seed = "Seed"
    case sprout = "Sprout"
    case seedling = "Seedling"
    case youngPlant = "Young Plant"
    case bush = "Bush"
    case smallTree = "Small Tree"
    case fullTree = "Full Tree"
    case ancientTree = "Ancient Tree"
}

static func plantStage(for level: Int) -> PlantStage {
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

static func plantStageName(for level: Int) -> String {
    plantStage(for: level).rawValue
}
```

- [ ] **Step 2: Add deductXP to GamificationEngine**

In `NiwaShared/Engines/GamificationEngine.swift`:

a) In the existing `awardXP` method, add `previousLevel = profile.currentLevel` **before** the XP update (i.e., after the `guard let profile` line). This stores the pre-award level so the level-up overlay can show the correct before/after:
```swift
let previousLevelLocal = profile.currentLevel
// ... existing XP update code ...
let leveledUp = profile.currentLevel > previousLevelLocal
if leveledUp { self.previousLevel = previousLevelLocal }
didLevelUp = leveledUp
```

b) Add after the `awardXP` method:

```swift
/// Stores the level before the most recent level-up, for the celebration overlay.
private(set) var previousLevel: Int = 0

@discardableResult
func deductXP(source: XPSource, amount: Int, context: ModelContext) -> Bool {
    guard let profile = fetchProfile(from: context) else { return false }

    profile.totalXP = max(0, profile.totalXP - amount)
    profile.currentLevel = XPConstants.levelForTotalXP(profile.totalXP)
    // Level-down is always silent — didLevelUp is NOT set

    // Delete the most recent matching XPEvent from today
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())
    let sourceRaw = source.rawValue
    let descriptor = FetchDescriptor<XPEvent>(
        predicate: #Predicate<XPEvent> { event in
            event.sourceRaw == sourceRaw && event.earnedAt >= startOfDay
        },
        sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
    )
    if let event = try? context.fetch(descriptor).first {
        context.delete(event)
    }

    try? context.save()
    WidgetCenter.shared.reloadAllTimelines()
    return true
}
```

- [ ] **Step 3: Update HeroView to use shared PlantStages**

In `NiwaApp/Views/Components/HeroView.swift`, find the `plantStageName` computed property (lines 166-177) and replace it with:

```swift
private var plantStageName: String {
    XPConstants.plantStageName(for: level)
}
```

- [ ] **Step 4: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaShared/Constants/XPConstants.swift NiwaShared/Engines/GamificationEngine.swift NiwaApp/Views/Components/HeroView.swift
git commit -m "feat: add PlantStages enum, standing milestones, and deductXP

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 2: Notification Rewrite

### Task 4: Create ReminderTimerManager and Rewrite Notification System

**Files:**
- Create: `NiwaApp/Services/ReminderTimerManager.swift`
- Modify: `NiwaApp/Services/NotificationManager.swift`
- Modify: `NiwaApp/Services/HealthEventManager.swift`
- Modify: `NiwaApp/NiwaApp.swift`
- Modify: `NiwaApp/Views/DropdownRootView.swift`
- Modify: `NiwaApp/Views/Settings/InlineSettingsView.swift`
- Delete: `NiwaShared/Engines/ReminderSchedulingEngine.swift`

- [ ] **Step 1: Create ReminderTimerManager**

Create `NiwaApp/Services/ReminderTimerManager.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
final class ReminderTimerManager {
    private let profileManager: UserProfileManager
    private let healthManager: HealthEventManager
    private var timer: Timer?

    // Persisted via UserDefaults
    private let defaults = UserDefaults.standard
    private let waterActionKey = "niwa.lastWaterActionDate"
    private let standActionKey = "niwa.lastStandActionDate"
    private let waterNotifKey = "niwa.lastWaterNotificationDate"
    private let standNotifKey = "niwa.lastStandNotificationDate"
    private let waterSnoozeKey = "niwa.snoozedWaterUntil"
    private let standSnoozeKey = "niwa.snoozedStandUntil"

    var lastWaterActionDate: Date {
        get { defaults.object(forKey: waterActionKey) as? Date ?? Date() }
        set { defaults.set(newValue, forKey: waterActionKey) }
    }

    var lastStandActionDate: Date {
        get { defaults.object(forKey: standActionKey) as? Date ?? Date() }
        set { defaults.set(newValue, forKey: standActionKey) }
    }

    private var lastWaterNotificationDate: Date? {
        get { defaults.object(forKey: waterNotifKey) as? Date }
        set { defaults.set(newValue, forKey: waterNotifKey) }
    }

    private var lastStandNotificationDate: Date? {
        get { defaults.object(forKey: standNotifKey) as? Date }
        set { defaults.set(newValue, forKey: standNotifKey) }
    }

    private var snoozedWaterUntil: Date? {
        get { defaults.object(forKey: waterSnoozeKey) as? Date }
        set { defaults.set(newValue, forKey: waterSnoozeKey) }
    }

    private var snoozedStandUntil: Date? {
        get { defaults.object(forKey: standSnoozeKey) as? Date }
        set { defaults.set(newValue, forKey: standSnoozeKey) }
    }

    init(profileManager: UserProfileManager, healthManager: HealthEventManager) {
        self.profileManager = profileManager
        self.healthManager = healthManager
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Called by notification action callbacks
    func waterDone() { lastWaterActionDate = Date(); lastWaterNotificationDate = nil; snoozedWaterUntil = nil }
    func waterSnoozed() { snoozedWaterUntil = Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60)) }
    func waterDismissed() { lastWaterActionDate = Date(); lastWaterNotificationDate = nil; snoozedWaterUntil = nil }
    func standDone() { lastStandActionDate = Date(); lastStandNotificationDate = nil; snoozedStandUntil = nil }
    func standSnoozed() { snoozedStandUntil = Date().addingTimeInterval(TimeInterval(XPConstants.snoozeDurationMinutes * 60)) }
    func standDismissed() { lastStandActionDate = Date(); lastStandNotificationDate = nil; snoozedStandUntil = nil }

    // MARK: - Timer Tick

    private func tick() {
        guard profileManager.profile?.healthRemindersEnabled == true else { return }
        let now = Date()

        if shouldFireWater(now: now) {
            NotificationManager.shared.showWaterReminder()
            lastWaterNotificationDate = now
        }

        if shouldFireStand(now: now) {
            NotificationManager.shared.showStandReminder()
            lastStandNotificationDate = now
        }
    }

    private func shouldFireWater(now: Date) -> Bool {
        // Check snooze
        if let snoozeUntil = snoozedWaterUntil {
            if now < snoozeUntil { return false }
            snoozedWaterUntil = nil
        }

        guard isWithinWorkHours(date: now), !isDuringLunch(date: now) else { return false }

        // Check interval elapsed since last action
        guard let profile = profileManager.profile else { return false }
        let elapsed = now.timeIntervalSince(lastWaterActionDate)
        guard elapsed >= Double(profile.waterIntervalMinutes * 60) else { return false }

        // Duplicate prevention: already notified since last action?
        if let lastNotif = lastWaterNotificationDate, lastNotif > lastWaterActionDate { return false }

        return true
    }

    private func shouldFireStand(now: Date) -> Bool {
        // Don't remind while actively standing
        guard !healthManager.isStanding else { return false }

        // Check snooze
        if let snoozeUntil = snoozedStandUntil {
            if now < snoozeUntil { return false }
            snoozedStandUntil = nil
        }

        guard isWithinWorkHours(date: now), !isDuringLunch(date: now) else { return false }

        guard let profile = profileManager.profile else { return false }
        let elapsed = now.timeIntervalSince(lastStandActionDate)
        guard elapsed >= Double(profile.standIntervalMinutes * 60) else { return false }

        if let lastNotif = lastStandNotificationDate, lastNotif > lastStandActionDate { return false }

        return true
    }

    // MARK: - Time Checks (delegate to UserProfileManager)

    private func isWithinWorkHours(date: Date) -> Bool {
        profileManager.isWithinWorkHours(date: date)
    }

    private func isDuringLunch(date: Date) -> Bool {
        profileManager.isLunchTime(date: date)
    }
}
```

- [ ] **Step 2: Simplify NotificationManager to display-only**

In `NiwaApp/Services/NotificationManager.swift`, make these changes:

a) Add dropdown visibility property:
```swift
var isDropdownVisible: Bool = false
```

b) Replace `scheduleWaterReminder(at:)` with an immediate display method:
```swift
func showWaterReminder() {
    let content = UNMutableNotificationContent()
    content.title = "Time for Water"
    content.body = "Stay hydrated! Have a glass of water."
    content.categoryIdentifier = Self.waterCategory
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "niwa-water-reminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
```

c) Replace `scheduleStandReminder(at:)` similarly:
```swift
func showStandReminder() {
    let content = UNMutableNotificationContent()
    content.title = "Time to Stand"
    content.body = "Take a break and stand up for a few minutes."
    content.categoryIdentifier = Self.standCategory
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "niwa-stand-reminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
```

d) Update `willPresent` to suppress banners when dropdown is visible:
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if isDropdownVisible {
        completionHandler([.sound])
    } else {
        completionHandler([.banner, .sound])
    }
}
```

e) Remove `onWaterDismissed` and `onStandDismissed` callback properties (they're replaced by the timer manager).

f) Add callbacks for `onReminderTimerManager` — update `didReceive` to route dismiss/default actions:
The `didReceive` handler already has the dismiss case. Keep it, but the callbacks will now point to `ReminderTimerManager` methods instead.

- [ ] **Step 3: Strip scheduling logic from HealthEventManager**

In `NiwaApp/Services/HealthEventManager.swift`:

a) Remove these properties: `lastWaterActionDate`, `lastStandActionDate`

b) Remove these methods entirely:
- `scheduleNextReminders()`
- `scheduleNextWaterReminder(snoozed:)`
- `scheduleNextStandReminder(snoozed:)`
- `snoozeWater()`
- `snoozeStand()`

c) Remove scheduling calls from `init()` — delete `scheduleNextReminders()` call (line 30)

d) Remove scheduling calls from `confirmWater()` — delete `lastWaterActionDate = Date()` and `scheduleNextWaterReminder()` (lines 43-44)

e) Remove scheduling calls from `stopStanding()` — delete `lastStandActionDate = Date()` and `scheduleNextStandReminder()` (lines 80-81)

f) Simplify `setupNotificationCallbacks()` — remove ALL callback assignments. The callbacks will be wired in `NiwaApp.init()` instead, since they now need to coordinate between `HealthEventManager` and `ReminderTimerManager`:
```swift
private func setupNotificationCallbacks() {
    // Callbacks are now wired in NiwaApp.init() to coordinate
    // between HealthEventManager and ReminderTimerManager
}
```

g) Remove `lastWaterActionDate`/`lastStandActionDate` loading from `loadTodayStats()` (lines 244-251)

- [ ] **Step 4: Wire ReminderTimerManager in NiwaApp.swift**

In `NiwaApp/NiwaApp.swift`:

a) Add property: `let reminderTimerManager: ReminderTimerManager`

b) In `init()`, after creating `healthManager`, create the timer manager:
```swift
reminderTimerManager = ReminderTimerManager(profileManager: profMgr, healthManager: healthManager)
```

c) Wire ALL notification callbacks in `NiwaApp.init()` after creating all managers. This replaces the old `setupNotificationCallbacks()` in HealthEventManager:
```swift
let hm = healthManager
let rtm = reminderTimerManager
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
```

- [ ] **Step 5: Wire dropdown visibility in DropdownRootView**

In `NiwaApp/Views/DropdownRootView.swift`, add to the main content view:
```swift
.onAppear { NotificationManager.shared.isDropdownVisible = true }
.onDisappear { NotificationManager.shared.isDropdownVisible = false }
```

- [ ] **Step 6: Update InlineSettingsView**

In `NiwaApp/Views/Settings/InlineSettingsView.swift`, the `saveHealth()` method (line 492) currently calls `healthManager.scheduleNextReminders()`. Remove that call — the timer manager handles everything automatically. Change to:
```swift
private func saveHealth() { profileManager.save() }
```

- [ ] **Step 7: Delete ReminderSchedulingEngine**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
rm NiwaShared/Engines/ReminderSchedulingEngine.swift
```

Then regenerate the Xcode project:
```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate
```

- [ ] **Step 8: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 9: Manual test**

Launch the app. Verify:
1. No immediate notification spam on launch
2. Set water interval to 1 minute in settings for testing — notification should fire after ~1 minute
3. Dismiss the notification — no rapid re-fire
4. Check that "Done" button on notification works (water count increments)

- [ ] **Step 10: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Services/ReminderTimerManager.swift NiwaApp/Services/NotificationManager.swift NiwaApp/Services/HealthEventManager.swift NiwaApp/NiwaApp.swift NiwaApp/Views/DropdownRootView.swift NiwaApp/Views/Settings/InlineSettingsView.swift Niwa.xcodeproj/project.pbxproj project.yml
git add -u NiwaShared/Engines/ReminderSchedulingEngine.swift
git commit -m "feat: replace notification scheduling with timer-based reminders

Fixes notification spam by using a 60-second polling timer instead of
UNNotification scheduling. Eliminates minute-overflow bug, willPresent
cascade, and cancel/reschedule race conditions.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 3: Health Pills, Standing XP, Undo, Level-Up

### Task 5: Standing XP Milestones

**Files:**
- Modify: `NiwaApp/Services/HealthEventManager.swift`

- [ ] **Step 1: Update stopStanding() with milestone XP**

In `NiwaApp/Services/HealthEventManager.swift`, find `stopStanding()` and replace the XP award line:
```swift
gamificationEngine.awardXP(source: .stand, amount: XPConstants.standComplete, context: modelContext)
```
With:
```swift
let duration = Date().timeIntervalSince(startTime)
let minutes = Int(duration / 60)
var totalXP = XPConstants.standComplete  // base 10 XP
for milestone in XPConstants.standMilestones {
    if minutes >= milestone.minutes {
        totalXP += milestone.bonus
    }
}
totalXP = min(totalXP, XPConstants.standMaxXP)
gamificationEngine.awardXP(source: .stand, amount: totalXP, context: modelContext)
```

- [ ] **Step 2: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Services/HealthEventManager.swift
git commit -m "feat: standing XP milestones — bonus XP at 10/20/30 min

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Creatine/Gym Undo with XP Deduction

**Files:**
- Modify: `NiwaApp/Services/HealthEventManager.swift`

- [ ] **Step 1: Add undoCreatine() and undoGym()**

In `NiwaApp/Services/HealthEventManager.swift`, add after `confirmGym()`:

```swift
// MARK: - Undo (once-daily items)

func undoCreatine() {
    guard todayCreatineLogged else { return }
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())

    let descriptor = FetchDescriptor<HealthEvent>(
        predicate: #Predicate<HealthEvent> { event in
            event.typeRaw == "creatine" && event.confirmedAt != nil
        },
        sortBy: [SortDescriptor(\.confirmedAt, order: .reverse)]
    )
    if let events = try? modelContext.fetch(descriptor),
       let event = events.first(where: { ($0.confirmedAt ?? .distantPast) >= startOfDay }) {
        modelContext.delete(event)
        try? modelContext.save()
    }

    gamificationEngine.deductXP(source: .creatine, amount: XPConstants.creatineConfirm, context: modelContext)
    todayCreatineLogged = false
}

func undoGym() {
    guard todayGymLogged else { return }
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: Date())

    let descriptor = FetchDescriptor<HealthEvent>(
        predicate: #Predicate<HealthEvent> { event in
            event.typeRaw == "gym" && event.confirmedAt != nil
        },
        sortBy: [SortDescriptor(\.confirmedAt, order: .reverse)]
    )
    if let events = try? modelContext.fetch(descriptor),
       let event = events.first(where: { ($0.confirmedAt ?? .distantPast) >= startOfDay }) {
        modelContext.delete(event)
        try? modelContext.save()
    }

    gamificationEngine.deductXP(source: .gym, amount: XPConstants.gymConfirm, context: modelContext)
    todayGymLogged = false
}
```

- [ ] **Step 2: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Services/HealthEventManager.swift
git commit -m "feat: add creatine/gym undo with XP deduction

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 7: Redesign Health Pills with Labels, XP Badges, and Undo Tooltip

**Files:**
- Modify: `NiwaApp/Views/HealthStatusView.swift` (full rewrite)

- [ ] **Step 1: Rewrite HealthStatusView**

Replace the entire contents of `NiwaApp/Views/HealthStatusView.swift` with the new design. The new version must include:

a) **Pill layout with labels + XP badges:**
- Water: `drop.fill` + "Water +10" when count is 0, `drop.fill` + count when count > 0
- Stand: `figure.stand` + "Stand +10" when idle, `figure.stand` + timer + milestone badge when active
- Creatine: `bolt.fill` + "Creatine +15" when unlogged, `bolt.fill` + "✓" when logged (dimmed 45%)
- Gym: `dumbbell.fill` + "Gym +30" when unlogged, `dumbbell.fill` + "✓" when logged (dimmed 45%)

b) **Hover effects:**
```swift
.onHover { isHovered = $0 }
.offset(y: isHovered ? -1 : 0)
.brightness(isHovered ? 0.15 : 0)
.animation(.easeOut(duration: 0.2), value: isHovered)
```

c) **Undo tooltip:**
- `@State private var showUndoTooltip: UndoTarget?` enum with `.creatine` and `.gym` cases
- Tapping logged creatine/gym pill sets `showUndoTooltip`
- Tooltip rendered as `.overlay(alignment: .top)` on the pill
- Tapping tooltip calls `healthManager.undoCreatine()` or `undoGym()`
- Tapping elsewhere (background tap on HStack) dismisses tooltip
- Auto-dismiss after 4 seconds

d) **Standing milestone badge:**
- During active standing, compute elapsed minutes
- Show cumulative bonus badge when elapsed >= 10 min: `+5`, `+15`, `+30`
- Badge: small sage capsule, 9pt font

e) **Pill sizing:** 28pt height, 11pt horizontal padding, 5pt vertical padding, `Capsule()` shape

f) **Colors:** Use existing `DesignTokens` where possible, brand colors for pill backgrounds:
- Sage pills: `rgba(129,178,154, 0.12)` background, `rgba(129,178,154, 0.25)` border
- Amber pill: `rgba(224,172,58, 0.12)` background, `rgba(224,172,58, 0.25)` border
- Terracotta pill: `rgba(224,122,95, 0.12)` background, `rgba(224,122,95, 0.25)` border

- [ ] **Step 2: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual test**

Launch the app and verify:
1. All four pills show labels + XP values when unlogged
2. Tapping water shows count, no more "+10" badge
3. Starting stand shows timer, milestone badge appears at 10 min
4. Tapping creatine logs it, pill dims with checkmark
5. Tapping logged creatine shows undo tooltip
6. Confirming undo restores pill, deducts XP
7. Hover lifts pill slightly

- [ ] **Step 4: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Views/HealthStatusView.swift
git commit -m "feat: redesign health pills with labels, XP badges, and undo

Pills now show text labels and XP values. Creatine/gym can be undone
via inline tooltip. Standing shows milestone bonus during active session.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 8: Full-Bleed Level-Up Celebration

**Files:**
- Modify: `NiwaApp/Views/Components/LevelUpOverlay.swift` (full rewrite)
- Modify: `NiwaApp/Views/DropdownRootView.swift`

- [ ] **Step 1: Rewrite LevelUpOverlay**

Replace the entire contents of `NiwaApp/Views/Components/LevelUpOverlay.swift`. The new version must include:

a) **Updated signature:**
```swift
struct LevelUpOverlay: View {
    let level: Int
    let previousLevel: Int
    let isVisible: Bool
    let onDismiss: () -> Void
}
```

b) **Full-bleed layout (ZStack filling entire dropdown):**
- Dimmed background: `RadialGradient` with sage glow at center, black edges
- Tap gesture on background to dismiss

c) **Plant with rainbow XP ring:**
- `PlantView(level: level)` at 100pt frame
- Ring: `Circle().strokeBorder(AngularGradient(colors: [sage, amber, terracotta, sage]), lineWidth: 8)` at 116pt
- Outer glow: `.shadow(color: sage.opacity(0.3), radius: 30)`

d) **Floating +XP badge:**
- Positioned top-right of ring
- Text: "+\(xpForLevel) XP" in sage on sage/15% background capsule
- Animates: `.offset(y: animated ? -20 : 0)` + `.opacity(animated ? 0 : 1)` over 2s

e) **Text stack:**
- "LEVEL UP" — 13pt, sage, `.textCase(.uppercase)`, `.kerning(1)`
- "Level \(level)" — 36pt, `.bold()`, white
- Stage name badge — `Capsule()` with sage fill 15%, sage text, 12pt: "\(XPConstants.plantStageName(for: level))"
- "Tap anywhere to continue" — 13pt, `textSecondary`

f) **Stage evolution (when plant boundary crossed):**
- Check: `XPConstants.plantStage(for: previousLevel) != XPConstants.plantStage(for: level)`
- Old plant: `PlantView(level: previousLevel)` at 40pt, fades and slides left
- New plant: springs in from right
- Use `@State` booleans to sequence the animation

g) **Confetti:**
- 25 `ConfettiParticle` structs with `width`, `height`, `rotation`, `color` (sage/amber/terracotta/lavender)
- Each particle: `RoundedRectangle(cornerRadius: 1)` instead of `Circle`
- Animation: `.offset(y: +120)` + `.rotationEffect(.degrees(360))` + `.opacity(0)` over 2.5s
- Staggered: `delay: Double.random(in: 0...0.3)`

h) **Timing:**
- Entrance: `.spring(response: 0.4, dampingFraction: 0.7)` scale 0.6→1.0
- Auto-dismiss after 3.5s
- Tap anywhere dismisses immediately

i) **Accessibility:**
- `@Environment(\.accessibilityReduceMotion)`: skip animations, show static, no confetti
- `.accessibilityLabel("Level up! You reached level \(level), \(XPConstants.plantStageName(for: level)) stage")`

- [ ] **Step 2: Update DropdownRootView to pass previousLevel**

In `NiwaApp/Views/DropdownRootView.swift`:

a) In the `onChange(of: gamificationEngine.didLevelUp)` handler, set `showLevelUp`:
```swift
.onChange(of: gamificationEngine.didLevelUp) { _, newValue in
    if newValue {
        showLevelUp = true
        gamificationEngine.resetLevelUpFlag()
    }
}
```

b) Update the `LevelUpOverlay` call to use `gamificationEngine.previousLevel` (stored by `awardXP` before the level change):
```swift
LevelUpOverlay(
    level: profileManager.profile?.currentLevel ?? 1,
    previousLevel: gamificationEngine.previousLevel,
    isVisible: showLevelUp,
    onDismiss: { showLevelUp = false; soundManager.play(.levelUp) }
)
```

- [ ] **Step 3: Build and verify**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual test**

To test without grinding XP: temporarily set level thresholds very low in `XPConstants.swift`, trigger a level-up by completing a task, verify:
1. Full-bleed overlay appears with rainbow ring + plant
2. Stage name badge shows correct stage
3. Confetti falls as rectangles in brand colors
4. Auto-dismisses after 3.5s
5. Sound plays on dismiss
6. Tap anywhere dismisses early

Remember to revert any test modifications to XPConstants.

- [ ] **Step 5: Commit**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add NiwaApp/Views/Components/LevelUpOverlay.swift NiwaApp/Views/DropdownRootView.swift
git commit -m "feat: full-bleed level-up celebration with plant evolution

Rainbow XP ring, falling confetti in brand colors, stage name badge,
and before/after plant transition when crossing stage boundaries.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 4: Final Verification

### Task 9: Full Build, XcodeGen Regen, and Final QA

**Files:**
- Modify: `project.yml` (if needed)
- Modify: `Niwa.xcodeproj/project.pbxproj` (regenerated)

- [ ] **Step 1: Regenerate Xcode project**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate
```

- [ ] **Step 2: Full Release build**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodebuild -project Niwa.xcodeproj -scheme NiwaApp -configuration Release CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Run the app and verify all features**

Launch the app and check:
1. **Notifications:** Set interval to 1 min, verify single notification after ~1 min, no spam
2. **Health pills:** All show labels + XP values, creatine/gym undo works
3. **Standing:** Start standing, verify milestone badge appears at time thresholds
4. **Level-up:** Trigger a level-up, verify full-bleed celebration
5. **Notes:** Create multiple notes, verify colors cycle correctly
6. **Error handling:** App doesn't crash on launch, no silent failures visible
7. **Settings:** Changing intervals doesn't cause notification storm

- [ ] **Step 4: Commit final state**

If any fixes were needed during QA, commit them:
```bash
cd "/Users/james/Claude Projects/Niwa/Niwa"
git add -A
git commit -m "chore: xcodegen regen and QA fixes

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```
