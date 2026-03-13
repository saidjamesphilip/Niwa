# Focus Timer — Design Spec

## Problem

The current Pomodoro timer has 5 states (`idle`, `working`, `paused`, `shortBreak`, `longBreak`) with round tracking and auto-break logic. This adds complexity without clear value. Users either skip breaks or find the rigid Pomodoro structure frustrating.

## Solution

Replace the Pomodoro system with a simple Focus Timer. Pick a duration, start, commit or cancel. No pausing, no breaks, no rounds.

---

## User Experience

### Idle State

- **Preset chips:** A horizontal row of tappable duration buttons (default: 15 / 25 / 45 min). Tapping a chip selects it.
- **Custom duration:** A stepper for arbitrary durations (range: 1-120 min, step: 1 min). Selecting custom deselects the chips and vice versa.
- **"Start Focus" button:** Begins the countdown for the selected duration.
- **Daily focus streak dots:** A row of small filled circles at the bottom, one per completed session today. Empty state: "No sessions today" caption.

### Active State (Focusing)

- **Countdown ring:** Circular progress indicator showing time remaining (same 120pt ring as current, but progress counts down from 1.0 to 0.0).
- **Digital time display:** MM:SS in monospaced font, centered inside the ring.
- **Selected duration label:** e.g. "25 min focus" below the ring.
- **Cancel button:** Single button, stops the timer and discards the session. No XP awarded.
- **No pause button.** This is intentional — commit or cancel only.

### Complete State

- **Checkmark animation:** The ring fills to 100% and morphs into a checkmark icon.
- **XP reward display:** "+25 XP" text animates in below the checkmark (1 XP per minute of chosen duration).
- **Completion sound:** Plays `SoundEvent.timerComplete` via existing `SoundManager`.
- **Auto-return:** After ~3 seconds, transitions back to idle state.

### Settings Changes

Replace the current Timer section (4 Pomodoro settings) with:

| Setting | Type | Default | Notes |
|---|---|---|---|
| Quick Pick Presets | Editable list of Int | [15, 25, 45] | Min 1, max 5 presets. Each value 1-120 min. |
| Completion Sound | Toggle | On (uses existing `soundsEnabled`) | Reuses existing sound toggle; no new setting needed |

The existing per-event sound picker (`soundTimerComplete`) already covers the completion sound. The `soundBreakComplete` setting becomes unused and can remain dormant for backward compatibility.

---

## Technical Design

### State Machine

Replace `TimerState` enum in `PomodoroTimerEngine.swift`:

```swift
// Current (remove)
enum TimerState: Equatable {
    case idle
    case working
    case paused
    case shortBreak
    case longBreak
}

// New
enum FocusTimerState: Equatable {
    case idle
    case focusing
    case complete
}
```

### Engine Changes

**File:** `NiwaShared/Engines/PomodoroTimerEngine.swift` — rename to `FocusTimerEngine.swift`

Replace `PomodoroTimerEngine` class with `FocusTimerEngine`:

- **Remove:** `pause()`, `resume()`, break logic, round counting (`completedWorkSessions`, `sessionsBeforeLongBreak`), `SessionType`-based branching, `shortBreakDuration`, `longBreakDuration`.
- **Keep:** Date-based elapsed tracking, `displayTimer` tick at 0.25s, `formattedTime`, `progress` computed property, `resumeIncompleteSession()` logic (simplified to only handle `.focusing` state).
- **Add:**
  - `selectedDuration: Int` (minutes) — set before calling `start()`.
  - `start(minutes: Int)` — begins countdown for the given duration.
  - `cancel()` — stops timer, marks session as skipped, resets to idle. No XP.
  - On natural completion: award XP via `gamificationEngine.awardXP(source: .timer, amount: minutes)`, play sound, set state to `.complete`, schedule auto-reset after 3 seconds.
  - `todayCompletedSessions: Int` — count of today's completed (non-skipped) `TimerSession` records. Loaded on init and incremented on completion.

### XP Constant

**File:** `NiwaShared/Constants/XPConstants.swift`

```swift
// Remove
static let pomodoroComplete: Int = 25

// Add
/// Focus timer XP: 1 XP per minute of the chosen duration (awarded on completion only)
static let focusXPPerMinute: Int = 1
```

XP examples: 15 min = 15 XP, 25 min = 25 XP, 45 min = 45 XP.

### Model Changes

**File:** `NiwaShared/Models/TimerSession.swift`

Simplify `SessionType`:

```swift
// Current (remove shortBreak, longBreak)
enum SessionType: String, Codable {
    case work
    case shortBreak
    case longBreak
}

// New
enum SessionType: String, Codable {
    case focus
}
```

The `TimerSession` model itself stays mostly the same. The `pausedElapsed` field becomes unused (no pausing) but can remain for backward compatibility with existing data. New sessions will always have `pausedElapsed = 0`.

Add `durationMinutes: Int` stored property (the user's chosen duration in minutes, used for XP calculation). This avoids rounding issues from the `duration: TimeInterval` field.

### UserProfile Changes

**File:** `NiwaShared/Models/UserProfile.swift`

```swift
// Remove these 4 fields
var pomoDurationMinutes: Int
var shortBreakMinutes: Int
var longBreakMinutes: Int
var sessionsBeforeLongBreak: Int

// Add
var focusPresetMinutes: [Int]  // Default: [15, 25, 45]
```

Note: SwiftData `@Model` supports arrays of primitive types. Default value set in `init()`.

### View Changes

**File:** `NiwaApp/Views/TimerView.swift`

Complete rewrite. New structure:

```
VStack {
    switch engine.state {
    case .idle:
        // Preset chips (HStack of capsule buttons)
        // Custom stepper
        // "Start Focus" button
        // Daily streak dots
    case .focusing:
        // Countdown ring + MM:SS
        // Duration label
        // Cancel button
    case .complete:
        // Checkmark + "+XX XP" animation
    }
}
```

The view takes `FocusTimerEngine` instead of `PomodoroTimerEngine`.

**File:** `NiwaApp/Views/Settings/InlineSettingsView.swift`

Replace the Timer section (lines 45-58) with:

- **Quick Pick Presets:** Show current preset values as editable chips. Add/remove buttons. Each value uses a stepper (1-120 min). Max 5 presets.
- The `saveTimer()` helper updates the new `focusPresetMinutes` array on the profile and calls `timerEngine.loadSettings()`.

Update the `timerEngine` property type from `PomodoroTimerEngine` to `FocusTimerEngine`.

### Sound Integration

**File:** `NiwaApp/Services/SoundManager.swift`

No changes needed. The existing `SoundEvent.timerComplete` and `SoundManager.play(.timerComplete)` handle the completion sound. `SoundEvent.breakComplete` becomes unused but remains for backward compatibility.

### Daily Session Tracking

Query `TimerSession` records for today (where `completedAt != nil`, `wasSkipped == false`, and `completedAt >= startOfDay`). This follows the same pattern used in `HealthEventManager.loadTodayStats()`. No new model needed — `TimerSession` already has `completedAt` and `wasSkipped`.

---

## What Gets Removed

| Item | Location |
|---|---|
| `TimerState.paused` / `.shortBreak` / `.longBreak` | `PomodoroTimerEngine.swift` |
| `pause()`, `resume()` methods | `PomodoroTimerEngine.swift` |
| Break session logic (`beginSession(.shortBreak/longBreak)`) | `PomodoroTimerEngine.swift` |
| Round tracking (`completedWorkSessions`, `sessionsBeforeLongBreak`) | `PomodoroTimerEngine.swift` |
| `SessionType.shortBreak` / `.longBreak` | `TimerSession.swift` |
| 4 Pomodoro settings (work, short break, long break, sessions) | `InlineSettingsView.swift` |
| 4 Pomodoro defaults in constants | `XPConstants.swift` |
| 4 Pomodoro fields on UserProfile | `UserProfile.swift` |
| `pomodoroComplete` XP constant (flat 25 XP) | `XPConstants.swift` |

## What Gets Added

| Item | Location |
|---|---|
| `FocusTimerState` enum (idle/focusing/complete) | `FocusTimerEngine.swift` |
| `FocusTimerEngine` class | `FocusTimerEngine.swift` (renamed from `PomodoroTimerEngine.swift`) |
| Duration preset chips UI | `TimerView.swift` |
| Custom duration stepper | `TimerView.swift` |
| Countdown ring (reuses existing ring, reversed direction) | `TimerView.swift` |
| Completion checkmark + XP animation | `TimerView.swift` |
| Daily focus streak dots | `TimerView.swift` |
| `focusXPPerMinute` constant | `XPConstants.swift` |
| `focusPresetMinutes` array on UserProfile | `UserProfile.swift` |
| `durationMinutes` on TimerSession | `TimerSession.swift` |
| Quick Pick Presets setting | `InlineSettingsView.swift` |

---

## Files Affected (Full Paths)

| File | Action |
|---|---|
| `NiwaShared/Engines/PomodoroTimerEngine.swift` | Rename to `FocusTimerEngine.swift`, rewrite |
| `NiwaShared/Models/TimerSession.swift` | Simplify `SessionType`, add `durationMinutes` |
| `NiwaShared/Constants/XPConstants.swift` | Remove Pomodoro constants, add `focusXPPerMinute` |
| `NiwaShared/Models/UserProfile.swift` | Remove 4 Pomodoro fields, add `focusPresetMinutes` |
| `NiwaApp/Views/TimerView.swift` | Full rewrite for new 3-state UI |
| `NiwaApp/Views/Settings/InlineSettingsView.swift` | Replace Timer section with Quick Pick Presets |
| `NiwaApp/NiwaApp.swift` | Update engine type references (PomodoroTimerEngine -> FocusTimerEngine) |
| `NiwaApp/Services/SoundManager.swift` | No code changes; `breakComplete` becomes unused |
| `NiwaShared/Models/XPEvent.swift` | No changes; `XPSource.timer` still used |
| `NiwaShared/Engines/GamificationEngine.swift` | No changes; `awardXP` API unchanged |
| `project.yml` (XcodeGen) | Update file reference if renaming engine file |

---

## Migration Notes

- Existing `TimerSession` records with `typeRaw = "shortBreak"` or `"longBreak"` become orphaned. They are historical data and can remain in the database. The new engine only creates sessions with `typeRaw = "focus"`.
- Existing `SessionType.work` records are compatible — they still represent completed focus sessions for historical queries.
- The 4 removed `UserProfile` fields (`pomoDurationMinutes`, `shortBreakMinutes`, `longBreakMinutes`, `sessionsBeforeLongBreak`) should use SwiftData's default-value strategy for the migration: add default values to the new schema so existing rows don't break.
- `focusPresetMinutes` should default to `[15, 25, 45]` in the model init. SwiftData will apply this default for existing profiles on first access.
