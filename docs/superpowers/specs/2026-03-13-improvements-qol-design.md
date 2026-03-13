# Improvements & QOL Release — Design Spec

**Date:** 2026-03-13
**Branch:** `improvements-and-qol`
**Version:** Next release after v1.3.11

---

## 1. Notification System Rewrite (Critical Bug Fix)

### Problem
Notifications fire far more frequently than configured intervals (30+ min). Five compounding bugs:
1. `willPresent` always shows banners (menu bar app is always foregrounded), and dismissing triggers a reschedule cascade
2. `ReminderSchedulingEngine.nextFireDate` has a minute-overflow bug — `minute: workStartMinute + intervalMinutes` can exceed 60, producing past dates that trigger immediate fallback scheduling
3. Cancel-then-reschedule race conditions when called from multiple code paths
4. Settings stepper taps each trigger a full cancel + reschedule cycle
5. Dismiss-without-action handler resets the clock, compounding with the above

### Design: Timer-Based Approach
Replace `UNUserNotificationCenter` scheduling with an in-app `Timer` that checks every 60 seconds whether a reminder is due. Use `UNNotification` only to *display* the banner.

**Architecture:**
- New `ReminderTimerManager` class, created in `NiwaApp.init()` alongside other managers
- Injected dependencies: `profileManager: UserProfileManager`, `healthManager: HealthEventManager`
- Reads `healthManager.isStanding` to suppress stand reminders during active standing
- Reads `profileManager.profile` for intervals, work hours, lunch hours, and `healthRemindersEnabled`

**State (stored on `ReminderTimerManager`, persisted via UserDefaults):**
- `lastWaterActionDate: Date` — when the user last confirmed/snoozed/dismissed a water reminder
- `lastStandActionDate: Date` — same for stand
- `lastWaterNotificationDate: Date?` — when the last water notification was shown (for duplicate prevention)
- `lastStandNotificationDate: Date?` — same for stand
- `snoozedWaterUntil: Date?` — set when user taps Snooze (set to `now + snoozeMinutes`)
- `snoozedStandUntil: Date?` — same for stand

**Why UserDefaults, not UserProfile:** These are transient scheduling dates, not user settings. No SwiftData schema change needed.

**Timer tick logic (runs every 60 seconds):**
```
func tick() {
    guard profile.healthRemindersEnabled else { return }
    let now = Date()

    // Water check
    if shouldFireWater(now: now) {
        NotificationManager.shared.showWaterReminder()
        lastWaterNotificationDate = now
    }

    // Stand check
    if shouldFireStand(now: now) {
        NotificationManager.shared.showStandReminder()
        lastStandNotificationDate = now
    }
}

func shouldFireWater(now: Date) -> Bool {
    // 1. Is snooze active? If so, has it expired?
    if let snoozeUntil = snoozedWaterUntil, now < snoozeUntil { return false }
    snoozedWaterUntil = nil // clear expired snooze

    // 2. Is current time within work hours and outside lunch?
    guard isWithinWorkHours(now) && !isDuringLunch(now) else { return false }

    // 3. Has interval elapsed since last action?
    let elapsed = now.timeIntervalSince(lastWaterActionDate)
    guard elapsed >= Double(profile.waterIntervalMinutes * 60) else { return false }

    // 4. Duplicate prevention: has a notification already been shown since the last action?
    if let lastNotif = lastWaterNotificationDate, lastNotif > lastWaterActionDate { return false }

    return true
}
```

`shouldFireStand` is identical but also checks `!healthManager.isStanding`.

**Snooze handling:**
- User taps "Snooze 10 min" → sets `snoozedWaterUntil = now + 10*60`
- `lastWaterActionDate` is NOT updated (snooze doesn't count as an action)
- Timer tick checks snooze first — if snoozed and not expired, skip
- When snooze expires, normal interval check resumes from `lastWaterActionDate`

**Notification action callbacks:**
- Done → `lastWaterActionDate = now` (full interval restarts)
- Snooze → `snoozedWaterUntil = now + snoozeMinutes`
- Dismiss/Default tap → `lastWaterActionDate = now` (treat as acknowledged)

**Dropdown visibility for `willPresent`:**
- `NotificationManager` gets a `var isDropdownVisible: Bool` property
- `DropdownRootView` sets this via `.onAppear { NotificationManager.shared.isDropdownVisible = true }` and `.onDisappear { ... = false }`
- `willPresent` returns `[.banner, .sound]` when `!isDropdownVisible`, and `[.sound]` when visible

**What gets deleted:**
- `ReminderSchedulingEngine.swift` — entire file
- `scheduleNextWaterReminder()` / `scheduleNextStandReminder()` in `HealthEventManager`
- `scheduleNextReminders()` in `HealthEventManager`
- `onWaterDismissed` / `onStandDismissed` callbacks on `NotificationManager`
- All fallback date computation logic

**What gets added:**
- `NiwaApp/Services/ReminderTimerManager.swift` — new file, ~100 lines

---

## 2. Fresh Machine Task/Note Creation Fix

### Problem
`try? context.save()` silently swallows errors everywhere. On a fresh machine, if the UserProfile seed save fails, tasks and notes appear in-memory but vanish on relaunch. No error feedback to the user.

### Design: Defensive Saves with Retry + Error Banner

**Shared error state:**
- New `@Observable` class `AppErrorState` with a published `var bannerMessage: String?`
- Created in `NiwaApp.init()`, injected into `TaskManager`, `NoteManager`, and `DropdownRootView` via environment
- When any manager's save fails, it sets `appErrorState.bannerMessage = "Unable to save..."`

**Save helper pattern (applied to TaskManager.save() and NoteManager.save()):**
```swift
func save() {
    do {
        try modelContext.save()
    } catch {
        // Retry once
        do {
            try modelContext.save()
        } catch {
            appErrorState?.bannerMessage = "Unable to save. Please restart Niwa."
            print("[Niwa] Save failed: \(error)")
        }
    }
}
```

**UserProfile seed hardening (NiwaApp.swift):**
- Replace `try?` with `do/catch` + retry
- Verify profile exists after save by re-fetching
- If still missing after retry, create an in-memory-only profile (app runs in degraded mode but doesn't crash)

**Error banner (new `ErrorBannerView`):**
- Terracotta background bar at top of dropdown
- Shows `bannerMessage` text + dismiss X button
- Auto-dismisses after 5 seconds
- `DropdownRootView` reads `appErrorState.bannerMessage` and shows `ErrorBannerView` when non-nil

---

## 3. Level-Up Screen: Full-Bleed Celebration

### Problem
Current overlay is a basic card: star icon, "Level Up!" text, small fading dots. Doesn't show plant stage, no evolution visual, confetti is subtle.

### Design: Full-Bleed Celebration

**Updated `LevelUpOverlay` signature:**
```swift
struct LevelUpOverlay: View {
    let level: Int
    let previousLevel: Int  // NEW — to detect stage evolution
    let isVisible: Bool
    let onDismiss: () -> Void
}
```

`DropdownRootView` passes `previousLevel` by capturing it before the level change in `onChange(of: gamificationEngine.didLevelUp)`.

**Plant stage boundaries (already defined in `HeroView.plantStageName`):**
```
Level 0: Seed
Level 1-3: Sprout
Level 4-7: Seedling
Level 8-12: Young Plant
Level 13-18: Bush
Level 19-25: Small Tree
Level 26-35: Full Tree
Level 36+: Ancient Tree
```

Extract `plantStageName(for level: Int) -> String` and `plantStageLevel(for level: Int) -> Int` as static functions on a new `PlantStages` enum in `XPConstants.swift` so both `HeroView` and `LevelUpOverlay` can use them.

**Layout (takes over entire 320px dropdown):**
- `ZStack` filling the full dropdown
- Dimmed background: `RadialGradient` with sage glow at center (0.2 opacity), black edges (0.6 opacity)
- Large `PlantView` (100pt frame) inside a rainbow ring:
  - Ring: `AngularGradient(colors: [sage, amber, terracotta, sage])` on a Circle stroke (8pt)
  - Outer glow: `.shadow(color: sage.opacity(0.3), radius: 30)`
- Floating "+XP" badge: `.offset(x: 40, y: -40)`, animates with `.transition(.move(edge: .bottom).combined(with: .opacity))` over 2s
- "LEVEL UP" label: 13pt, sage, `.textCase(.uppercase)`, kerning 1
- Level number: 36pt, `.bold()`, white
- Stage name badge: capsule with sage fill (0.15 opacity), sage text, 12pt
- "Tap anywhere to continue": 13pt, `textSecondary`

**Stage evolution (when `PlantStages.stageLevel(previousLevel) != PlantStages.stageLevel(level)`):**
- Old `PlantView` (small, 40pt) fades and slides left
- New `PlantView` (100pt) springs in from right
- Uses `matchedGeometryEffect` or sequential `.transition` with 0.5s spring

**Confetti:**
- 25 `ConfettiParticle` structs — each has `width: CGFloat.random(in: 3...6)`, `height: CGFloat.random(in: 2...4)`, `rotation`, `color` (sage/amber/terracotta/lavender)
- Animation: `.offset(y: +120)` + `.rotationEffect(.degrees(360))` + `.opacity(0)` over 2.5s ease-out
- Staggered with `delay: Double.random(in: 0...0.3)`

**Timing:**
- Entrance: `.spring(response: 0.4, dampingFraction: 0.7)` scale from 0.6 to 1.0
- Auto-dismiss: 3.5s
- Tap anywhere to dismiss immediately
- Sound: `soundManager.play(.levelUp)` on appear

**Accessibility:**
- `@Environment(\.accessibilityReduceMotion)`: skip all animations, show static layout, no confetti
- `.accessibilityLabel("Level up! You reached level \(level), \(stageName) stage")`

---

## 4. Standing XP: Tiered Milestones

### Problem
Standing duration is stored (`event.standingDuration`) but ignored. A 2-minute stand and a 2-hour stand both give 10 XP.

### Design: Tiered Milestones

**XP rewards (cumulative — all applicable tiers are awarded):**
| Duration | Bonus | Total XP Earned |
|----------|-------|-----------------|
| Any (base) | 10 | 10 |
| 10+ minutes | +5 | 15 |
| 20+ minutes | +10 | 25 |
| 30+ minutes | +15 | 40 |

A 25-minute stand earns: 10 (base) + 5 (10-min bonus) + 10 (20-min bonus) = 25 XP.
A 35-minute stand earns: 10 + 5 + 10 + 15 = 40 XP (cap).

**Implementation in `stopStanding()`:**
```swift
let duration = Date().timeIntervalSince(startTime)
let minutes = Int(duration / 60)
var totalXP = XPConstants.standComplete  // 10
for milestone in XPConstants.standMilestones {
    if minutes >= milestone.minutes {
        totalXP += milestone.bonus
    }
}
totalXP = min(totalXP, XPConstants.standMaxXP)
gamificationEngine.awardXP(source: .stand, amount: totalXP, context: modelContext)
```

This is a single `awardXP` call (not separate calls per milestone), keeping XP chart entries clean.

**Standing pill milestone badge (implemented in Section 6, linked here):**
- During active standing, the pill shows elapsed time + cumulative bonus earned so far
- At 0-9 min: `🧍 4:32` (no bonus badge)
- At 10-19 min: `🧍 12:15 +5` (bonus badge showing +5)
- At 20-29 min: `🧍 22:40 +15` (showing cumulative +5+10=+15)
- At 30+ min: `🧍 34:10 +30` (showing cumulative +5+10+15=+30)
- Badge: small sage pill, 9pt font

**Standing is not undoable.** Unlike creatine/gym (once-daily taps that can be fat-fingered), standing requires an explicit start + stop action. No undo mechanism needed.

**Constants (XPConstants.swift):**
```swift
static let standMilestones: [(minutes: Int, bonus: Int)] = [
    (10, 5), (20, 10), (30, 15)
]
static let standMaxXP: Int = 40
```

---

## 5. Creatine/Gym Undo: Inline Tooltip

### Problem
Once creatine or gym is logged, there's no undo. Accidental taps are permanent until full data reset.

### Design: Inline Tooltip Confirmation

**Flow:**
1. User taps a logged (dimmed) creatine or gym pill
2. A tooltip appears above the pill: "Undo Creatine? −15 XP"
3. Tapping the tooltip confirms the undo
4. Tapping elsewhere within the dropdown dismisses the tooltip (no action)
5. Tooltip auto-dismisses after 4 seconds if no interaction

**Tooltip implementation in `HealthStatusView`:**
- `@State private var showUndoTooltip: UndoTarget?` enum (`.creatine`, `.gym`, `nil`)
- Tooltip rendered as an overlay `.overlay(alignment: .top)` on the pill, positioned above with a down-arrow
- "Tap elsewhere" uses `.background(Color.clear.contentShape(Rectangle()).onTapGesture { showUndoTooltip = nil })` on the parent `HStack`
- This stays within the dropdown — no global gesture recognizer needed

**Tooltip design (SwiftUI):**
- `RoundedRectangle(cornerRadius: 8)` filled with `Color(hex: "#3D3429")`
- 1px `.overlay` stroke in pill's color (amber for creatine, terracotta for gym)
- Text: "Undo Creatine? −15 XP" in pill's color, 11pt, weight 500
- Down-arrow: `Triangle` shape rotated 180°, 10x6pt, same fill
- Entrance: `.scaleEffect` from 0.8 to 1.0, `.opacity` from 0 to 1, 200ms ease-out
- `.onAppear` schedules auto-dismiss after 4 seconds

**XP deduction (`GamificationEngine`):**
```swift
@discardableResult
func deductXP(source: XPSource, amount: Int, context: ModelContext) -> Bool {
    guard let profile = fetchProfile(from: context) else { return false }
    profile.totalXP = max(0, profile.totalXP - amount)
    profile.currentLevel = XPConstants.levelForTotalXP(profile.totalXP)
    // didLevelUp is NOT set — level-down is always silent

    // Delete the most recent matching XPEvent from today
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let descriptor = FetchDescriptor<XPEvent>(
        predicate: #Predicate { $0.source == source.rawValue && $0.date >= startOfDay },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    if let event = try? context.fetch(descriptor).first {
        context.delete(event)
    }
    try? context.save()
    WidgetCenter.shared.reloadAllTimelines()
    return true
}
```

Deletes the **most recent** matching XPEvent from today (not all matches).

**HealthEventManager additions:**
```swift
func undoCreatine() {
    guard todayCreatineLogged else { return }
    // Find and delete today's creatine HealthEvent
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let descriptor = FetchDescriptor<HealthEvent>(...)
    if let event = /* most recent creatine event today */ {
        modelContext.delete(event)
        try? modelContext.save()
    }
    gamificationEngine.deductXP(source: .creatine, amount: XPConstants.creatineConfirm, context: modelContext)
    todayCreatineLogged = false
}
```
`undoGym()` follows the same pattern.

---

## 6. Health Pills: Labels + XP Badges

### Problem
Pills show icons only. New users don't know what the bolt (creatine) or dumbbell (gym) icons mean without hovering.

### Design: Labels + XP Badges

**Pill states:**

| Pill | Unlogged (count=0) | Active/Logged | After Logging |
|------|-------------------|---------------|---------------|
| Water | `drop.fill Water +10` | `drop.fill 3` (count, no XP badge) | Same as active |
| Stand | `figure.stand Stand +10` | `figure.stand 4:32` (timer) OR `figure.stand 12:15 +5` (with milestone badge) | Returns to unlogged |
| Creatine | `bolt.fill Creatine +15` | N/A | `bolt.fill ✓` (dimmed 45%, tappable for undo) |
| Gym | `dumbbell.fill Gym +30` | N/A | `dumbbell.fill ✓` (dimmed 45%, tappable for undo) |

**Water pill at count 0:** Shows `drop.fill Water +10` (same as unlogged). After first tap: `drop.fill 1`. The label switches from "Water" to the count once `todayWaterCount > 0`.

**Icons:** SF Symbols only — `drop.fill`, `figure.stand`, `bolt.fill`, `dumbbell.fill`. No emojis in code.

**Sizing (SwiftUI values):**
- Pill: `.frame(height: 28)`, `.padding(.horizontal, 11)`, `.padding(.vertical, 5)`
- Icon: `.font(.system(size: 14))`
- Label text: `.font(.system(size: 12, weight: .medium))`
- XP text: `.font(.system(size: 10))`, `.opacity(0.6)`
- Gap: `HStack(spacing: 5)`
- Shape: `Capsule()`

**Hover (SwiftUI):**
- `.onHover { isHovered = $0 }`
- `.offset(y: isHovered ? -1 : 0)` + `.brightness(isHovered ? 0.15 : 0)`
- `.animation(.easeOut(duration: 0.2), value: isHovered)`

**Note:** Sections 4 and 6 both modify the standing pill. The implementor should handle them together in `HealthStatusView` — the milestone badge from Section 4 is part of the pill layout defined here.

---

## 7. Note Color Cycling Bug Fix

### Problem
`NoteManager.swift:21`:
```swift
let nextColor = (notes.first?.colorIndex ?? -1 + 1) % Self.noteColorCount
```
Swift operator precedence: `-1 + 1 = 0`, so this evaluates to `notes.first?.colorIndex ?? 0`. Every note gets color 0.

### Fix
```swift
let nextColor = ((notes.first?.colorIndex ?? -1) + 1) % Self.noteColorCount
```

One-line fix. Notes will now correctly cycle through: Terracotta (0) → Sage (1) → Lavender (2) → Amber (3) → Sky (4).

---

## Files to Create/Modify

### New Files
- `NiwaApp/Services/ReminderTimerManager.swift` — timer-based reminder engine (~100 lines)
- `NiwaApp/Views/Components/ErrorBannerView.swift` — save error banner view
- `NiwaApp/Services/AppErrorState.swift` — shared observable error state

### Modified Files
- `NiwaApp/Services/HealthEventManager.swift` — remove all scheduling logic, add `undoCreatine()`/`undoGym()`, update `stopStanding()` for milestones
- `NiwaApp/Services/NotificationManager.swift` — simplify to display-only, add `isDropdownVisible`, remove `onWaterDismissed`/`onStandDismissed`, update `willPresent`
- `NiwaApp/Views/Components/LevelUpOverlay.swift` — full-bleed celebration rewrite, new parameters
- `NiwaApp/Views/HealthStatusView.swift` — labels + XP badges, undo tooltip, standing milestone badge
- `NiwaApp/Views/DropdownRootView.swift` — error banner, `isDropdownVisible` binding, pass `previousLevel` to `LevelUpOverlay`
- `NiwaApp/NiwaApp.swift` — UserProfile seed hardening, create `ReminderTimerManager` and `AppErrorState`
- `NiwaApp/Services/NoteManager.swift` — color bug fix, save hardening with `AppErrorState`
- `NiwaApp/Services/TaskManager.swift` — save hardening with `AppErrorState`
- `NiwaApp/Services/UserProfileManager.swift` — no schema change but may need to expose profile for `ReminderTimerManager`
- `NiwaShared/Engines/GamificationEngine.swift` — add `deductXP(source:amount:context:)` method
- `NiwaShared/Constants/XPConstants.swift` — add `standMilestones`, `standMaxXP`, extract `PlantStages` enum

### Deleted Files
- `NiwaShared/Engines/ReminderSchedulingEngine.swift` — replaced by `ReminderTimerManager`

### No Changes Needed
- Models (HealthEvent, NiwaTask, NiwaNote, UserProfile, XPEvent) — no schema changes
- PlantView, HeroView, XPChartView — no changes
- Website, README — update after implementation
