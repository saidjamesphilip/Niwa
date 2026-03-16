# Niwa Quality Fixes — Design Spec

**Date:** 2026-03-15
**Branch:** `dev/quick-wins-2026-03-15`

## Goal

Fix 13 issues across performance, reliability, UX, and code quality. Work in three priority tiers with testing between each.

---

## Tier 1 — High Priority (Performance & Reliability)

### 1. Quit warning during active focus timer

**Problem:** Quit button calls `NSApplication.shared.terminate(nil)` immediately. Active focus sessions are silently marked `wasSkipped`, XP lost.

**Fix:** Add `applicationShouldTerminate(_:)` to `AppDelegate`. If `FocusTimerEngine.state == .focusing`, show an `NSAlert` with "Quit anyway" / "Cancel". If no timer active, terminate immediately.

**Wiring:** `AppDelegate` is created by `@NSApplicationDelegateAdaptor` before `NiwaApp.init()` runs, so the engine cannot be passed via init. Instead, add a `var timerEngine: FocusTimerEngine?` property to `AppDelegate` and assign it via `appDelegate.timerEngine = timerEngine` inside `NiwaApp.init()` after both are constructed.

### 2. HealthEventManager.loadTodayStats() full table scan

**Problem:** Fetches ALL `HealthEvent` rows, then filters by date in Swift. Degrades over months.

**Fix:** Push the date filter into the `#Predicate`. Use optional comparison (not force-unwrap) to avoid SwiftData predicate translation issues:
```swift
let dayStart = habitDayStart()
let predicate = #Predicate<HealthEvent> { $0.confirmedAt != nil && $0.confirmedAt >= dayStart }
```
SwiftData handles optional `Date` comparisons safely — no force-unwrap needed. This lets SQLite do the filtering.

### 3. XPChartView loads all XP events into memory

**Problem:** `@Query private var xpEvents: [XPEvent]` has no date filter. Loads entire history for a 7-day chart.

**Fix:** Pass pre-filtered XP events from the parent view (`DropdownRootView` → `mainContent` → `XPChartView`). The parent already observes the model context, so new XP awards will trigger re-renders and pass updated data downstream. This avoids the stale-data problem of a one-time `onAppear` fetch while keeping the view reactive.

**Implementation:** Add a `let xpEvents: [XPEvent]` parameter to `XPChartView`. In the parent, fetch events from the last 8 days via `modelContext` and pass them in. Remove the `@Query` from `XPChartView`.

### 4. UserProfileManager.profile fetches on every access

**Problem:** `profile` is a computed property that calls `context.fetch()` every time. `ReminderTimerManager.tick()` triggers 3 fetches per minute.

**Fix:** Cache the profile in a stored `var cachedProfile: UserProfile?`. Populate in `init()`. The computed `profile` property becomes a simple getter for the cached value. Add a `reload()` method for post-reset scenarios.

**Note on reference semantics:** `UserProfile` is a SwiftData `@Model` class (reference type). Callers that mutate properties directly (e.g. `profile.displayName = $0`) mutate the cached object in place — the cache stays consistent automatically. `save()` just calls `context.save()` on the already-mutated object.

### 5. Widget recreates ModelContainer every 5 minutes

**Problem:** `NiwaTimelineProvider.createEntry()` calls `ModelContainerSetup.createContainer()` on every widget refresh.

**Fix:** Add a `static let shared` lazy container to `NiwaTimelineProvider`:
```swift
private static let sharedContainer: ModelContainer? = {
    try? ModelContainerSetup.createContainer()
}()
```
Use this in `createEntry()` instead of creating a new one each time.

**Known edge case:** If the main app's migration fallback deletes and recreates the store files, the static container will point at a stale file handle. This is acceptable because: (a) store deletion only happens on schema migration failure, which is rare; (b) the widget process will eventually be killed and relaunched by the system, creating a fresh container. No mitigation needed for v1.

### 6. Widget uses midnight vs app's 7am for day-start

**Problem:** Widget computes water count using `calendar.startOfDay(for: Date())` (midnight). App uses `HealthEventManager.habitDayStart()` (7am). Numbers disagree between midnight and 7am.

**Fix:** Extract the 7am day-start logic into `XPConstants.habitDayStart()` in `NiwaShared` so both targets can use it. Update `HealthEventManager` to call `XPConstants.habitDayStart()` instead of its own implementation. Update `NiwaTimelineProvider` to use the same function for water count filtering.

---

## Tier 2 — Medium Priority (UX & Correctness)

### 7. GamificationEngine.didLevelUp race condition

**Problem:** `didLevelUp` is a boolean. Two rapid XP awards set it `true` → `true`. SwiftUI's `onChange` won't fire for same-value transitions, so the second level-up overlay is missed.

**Fix:** Replace `didLevelUp: Bool` with `levelUpCount: Int`. Increment on each level-up. `DropdownRootView.onChange(of: gamificationEngine.levelUpCount)` fires on every increment. Delete `resetLevelUpFlag()` and remove its call site in `DropdownRootView` — it becomes dead code after this change.

### 8. No notification permission indicator in settings

**Problem:** Settings shows "Manage in System Settings" but no indication of whether permission is currently granted. Users who denied get no feedback.

**Fix:** Add a permission status check using `UNUserNotificationCenter.current().notificationSettings()`. Display a small pill/label next to the "Manage in System Settings" link: green "Allowed" or orange "Blocked" (which opens System Settings on click). Check on `onAppear` of the health settings section.

---

## Tier 3 — Low Priority (Code Quality)

### 9. Mixed ObservableObject / @Observable patterns

**Problem:** `TaskManager` and `NoteManager` use `ObservableObject` + `@Published`. Everything else uses `@Observable`.

**Fix:** Migrate both to `@Observable`. Remove `ObservableObject` conformance, `@Published` wrappers. In `NiwaApp`, switch from `.environmentObject()` to passing as constructor arguments (same as other managers). Update all `@EnvironmentObject` usage in views to `let` parameters or `@Environment`.

**Note:** `UpdateChecker` in `InlineSettingsView` also uses `@StateObject` / `ObservableObject`. Migrate it to `@Observable` + `@State` in the same pass for consistency.

### 10. PlantView duplicates stage logic

**Problem:** `PlantView` has its own `PlantStage` enum and level-to-stage mapping that duplicates `XPConstants.plantStage(for:)`.

**Fix:** Delete `PlantView`'s private `PlantStage` enum and `switch` statement. Use `XPConstants.plantStage(for: level)` instead. Map `XPConstants.PlantStage` cases to the SF Symbol names and colors already used in `PlantView`.

### 11. Widget hardcodes colors as raw RGB

**Problem:** Widget views use inline `Color(red:green:blue:)` literals. Brand color change requires 9+ edits.

**Fix:** Create a `WidgetDesignTokens` enum in `NiwaShared/Constants/` with the brand colors used by widgets. Update all three widget views to reference these tokens.

### 12. Dead schema fields

**Problem:** `TimerSession.pausedElapsed` is never read. `HealthEvent.snoozedUntil` is never written. Legacy `SessionType` cases (`.work`, `.shortBreak`, `.longBreak`) are unused.

**Fix:** Remove `pausedElapsed` from `TimerSession`. Remove `snoozedUntil` from `HealthEvent`. Remove legacy `SessionType` cases (keep only `.focus`). SwiftData ignores removed properties in existing rows, so old data is safe.

**Important:** `NiwaTimelineProvider.swift` has a `switch` statement referencing `.work`, `.shortBreak`, `.longBreak` — this must be updated in the same change to remove those cases and only handle `.focus`. The `resumeIncompleteSession()` method in the app already filters by `typeRaw == "focus"`, so old rows are safely ignored.

### 13. Export missing data types

**Problem:** JSON export omits `HealthEvent` and `TimerSession`.

**Fix:** Add `HealthEvent` and `TimerSession` to the export function in `InlineSettingsView.exportData()`. Map relevant fields to JSON-safe types.

---

## Out of Scope

- Versioned schema migrations (future work when model changes are planned)
- Widget plant rendering (requires App Group entitlement, separate project)
- Unit test suite (good idea but separate initiative)
