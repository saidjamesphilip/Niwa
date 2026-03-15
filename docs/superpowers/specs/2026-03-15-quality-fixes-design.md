# Niwa Quality Fixes — Design Spec

**Date:** 2026-03-15
**Branch:** `dev/quick-wins-2026-03-15`

## Goal

Fix 13 issues across performance, reliability, UX, and code quality. Work in three priority tiers with testing between each.

---

## Tier 1 — High Priority (Performance & Reliability)

### 1. Quit warning during active focus timer

**Problem:** Quit button calls `NSApplication.shared.terminate(nil)` immediately. Active focus sessions are silently marked `wasSkipped`, XP lost.

**Fix:** Add `applicationShouldTerminate(_:)` to `AppDelegate`. If `FocusTimerEngine.state == .focusing`, show an `NSAlert` with "Quit anyway" / "Cancel". If no timer active, terminate immediately. The `AppDelegate` needs a reference to `FocusTimerEngine` — set it from `NiwaApp.init()`.

### 2. HealthEventManager.loadTodayStats() full table scan

**Problem:** Fetches ALL `HealthEvent` rows, then filters by date in Swift. Degrades over months.

**Fix:** Push the date filter into the `#Predicate`:
```swift
let dayStart = habitDayStart()
let predicate = #Predicate<HealthEvent> { $0.confirmedAt != nil && $0.confirmedAt! >= dayStart }
```
This lets SQLite do the filtering.

### 3. XPChartView loads all XP events into memory

**Problem:** `@Query private var xpEvents: [XPEvent]` has no date filter. Loads entire history for a 7-day chart.

**Fix:** Replace `@Query` with a manual fetch in a computed property (or `init`-time query), filtered to last 8 days (7 + buffer). `@Query` doesn't support dynamic predicates easily, so use a `let xpEvents: [XPEvent]` populated via the model context passed in, or use `@Query(filter:)` with a static predicate for "last 8 days from now." Since `@Query` predicates are evaluated at compile time and can't reference `Date()`, the cleanest approach is to accept a `modelContext` parameter and fetch manually in a computed property, or pass pre-filtered data from the parent.

**Chosen approach:** Inject the model context and do a filtered fetch in `onAppear`, storing results in `@State`. This avoids loading all-time data while keeping the view self-contained.

### 4. UserProfileManager.profile fetches on every access

**Problem:** `profile` is a computed property that calls `context.fetch()` every time. `ReminderTimerManager.tick()` triggers 3 fetches per minute.

**Fix:** Cache the profile in a stored `var cachedProfile: UserProfile?`. Populate in `init()`. Update the cache in `save()` and add a `reload()` method for post-reset. The computed `profile` property becomes a simple getter for the cached value.

### 5. Widget recreates ModelContainer every 5 minutes

**Problem:** `NiwaTimelineProvider.createEntry()` calls `ModelContainerSetup.createContainer()` on every widget refresh.

**Fix:** Add a `static let shared` lazy container to `NiwaTimelineProvider`:
```swift
private static let sharedContainer: ModelContainer? = {
    try? ModelContainerSetup.createContainer()
}()
```
Use this in `createEntry()` instead of creating a new one each time.

### 6. Widget uses midnight vs app's 7am for day-start

**Problem:** Widget computes water count using `calendar.startOfDay(for: Date())` (midnight). App uses `HealthEventManager.habitDayStart()` (7am). Numbers disagree between midnight and 7am.

**Fix:** Extract the 7am day-start logic into a static function on a shared type in `NiwaShared` (e.g. `XPConstants.habitDayStart()`) so both the widget and app use the same calculation. Update `HealthEventManager` to call this shared function, and update `NiwaTimelineProvider` to use it for water count filtering.

---

## Tier 2 — Medium Priority (UX & Correctness)

### 7. GamificationEngine.didLevelUp race condition

**Problem:** `didLevelUp` is a boolean. Two rapid XP awards set it `true` → `true`. SwiftUI's `onChange` won't fire for same-value transitions, so the second level-up overlay is missed.

**Fix:** Replace `didLevelUp: Bool` with `levelUpCount: Int`. Increment on each level-up. `DropdownRootView.onChange(of: gamificationEngine.levelUpCount)` fires on every increment. Reset is no longer needed — the view just tracks the last-seen count.

### 8. No notification permission indicator in settings

**Problem:** Settings shows "Manage in System Settings" but no indication of whether permission is currently granted. Users who denied get no feedback.

**Fix:** Add a permission status check using `UNUserNotificationCenter.current().notificationSettings()`. Display a small pill/label next to the "Enable Reminders" toggle: green "Allowed" or orange "Blocked — click to fix" (which opens System Settings). Check on `onAppear` of the health settings section.

---

## Tier 3 — Low Priority (Code Quality)

### 9. Mixed ObservableObject / @Observable patterns

**Problem:** `TaskManager` and `NoteManager` use `ObservableObject` + `@Published`. Everything else uses `@Observable`.

**Fix:** Migrate both to `@Observable`. Remove `ObservableObject` conformance, `@Published` wrappers. In `NiwaApp`, switch from `.environmentObject()` to passing as constructor arguments (same as other managers). Update all `@EnvironmentObject` usage in views to `let` parameters or `@Environment`.

### 10. PlantView duplicates stage logic

**Problem:** `PlantView` has its own `PlantStage` enum and level-to-stage mapping that duplicates `XPConstants.plantStage(for:)`.

**Fix:** Delete `PlantView`'s private `PlantStage` enum and `switch` statement. Use `XPConstants.plantStage(for: level)` instead. Map `XPConstants.PlantStage` cases to the SF Symbol names and colors already used in `PlantView`.

### 11. Widget hardcodes colors as raw RGB

**Problem:** Widget views use inline `Color(red:green:blue:)` literals. Brand color change requires 9+ edits.

**Fix:** Create a `WidgetDesignTokens` enum in `NiwaShared/Constants/` with the brand colors used by widgets. Update all three widget views to reference these tokens.

### 12. Dead schema fields

**Problem:** `TimerSession.pausedElapsed` is never read. `HealthEvent.snoozedUntil` is never written. Legacy `SessionType` cases (`.work`, `.shortBreak`, `.longBreak`) are unused.

**Fix:** Remove `pausedElapsed` from `TimerSession`. Remove `snoozedUntil` from `HealthEvent`. Remove legacy `SessionType` cases (keep only `.focus`). Note: SwiftData schema changes are additive-safe for removals (removed properties are just ignored in existing rows), but we should verify the app handles existing data gracefully — the `resumeIncompleteSession()` method already filters by `typeRaw == "focus"`, so old rows are safely ignored.

### 13. Export missing data types

**Problem:** JSON export omits `HealthEvent`, `TimerSession`, and (formerly) `ClipboardEntry`.

**Fix:** Add `HealthEvent` and `TimerSession` to the export function in `InlineSettingsView.exportData()`. Map relevant fields to JSON-safe types. `ClipboardEntry` is now removed so no longer relevant.

---

## Out of Scope

- Versioned schema migrations (future work when model changes are planned)
- Widget plant rendering (requires App Group entitlement, separate project)
- Unit test suite (good idea but separate initiative)
