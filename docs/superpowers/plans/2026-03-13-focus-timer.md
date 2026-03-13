# Focus Timer Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Pomodoro timer with a simpler Focus Timer (pick duration, commit or cancel, earn XP) and consolidate reset into a single function.

**Architecture:** Replace `PomodoroTimerEngine` with `FocusTimerEngine` (3 states: idle/focusing/complete). Rewrite `HeroView` timer section for preset chips + countdown ring + completion celebration. Simplify settings from 4 Pomodoro fields to preset list. Merge two reset functions into one that wipes everything.

**Tech Stack:** Swift, SwiftUI, SwiftData, XcodeGen

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `NiwaShared/Constants/XPConstants.swift` | Modify | Remove pomodoro constants, add `focusXPPerMinute` |
| `NiwaShared/Models/TimerSession.swift` | Modify | Add `focus` session type, add `durationMinutes` field |
| `NiwaShared/Models/UserProfile.swift` | Modify | Remove 4 pomodoro fields, add `focusPresetMinutes` |
| `NiwaShared/Engines/PomodoroTimerEngine.swift` | Delete | Replaced by FocusTimerEngine |
| `NiwaShared/Engines/FocusTimerEngine.swift` | Create | 3-state timer engine (idle/focusing/complete) |
| `NiwaApp/Views/Components/HeroView.swift` | Modify | Rewrite timer section for focus UI |
| `NiwaApp/Views/Settings/InlineSettingsView.swift` | Modify | Replace timer section, update engine type |
| `NiwaApp/Views/DropdownRootView.swift` | Modify | Update engine type, simplify sound callback, merge reset functions |
| `NiwaApp/NiwaApp.swift` | Modify | Update engine type references |

---

## Chunk 1: Data Layer

### Task 1: Update XPConstants

**Files:**
- Modify: `NiwaShared/Constants/XPConstants.swift`

- [ ] **Step 1: Remove pomodoro constants, add focus constant**

Replace lines 5 and 13-17 in `XPConstants.swift`:

```swift
// Remove line 5:
static let pomodoroComplete: Int = 25

// Replace with:
static let focusXPPerMinute: Int = 1

// Remove lines 13-17:
static let defaultWorkMinutes: Int = 25
static let defaultShortBreakMinutes: Int = 5
static let defaultLongBreakMinutes: Int = 15
static let defaultSessionsBeforeLongBreak: Int = 4

// Replace with:
static let defaultFocusPresets: [Int] = [15, 25, 45]
```

- [ ] **Step 2: Build to verify no compile errors yet (will have errors in other files — that's expected)**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add NiwaShared/Constants/XPConstants.swift
git commit -m "feat: replace pomodoro XP constants with focus timer constants"
```

---

### Task 2: Update TimerSession Model

**Files:**
- Modify: `NiwaShared/Models/TimerSession.swift`

- [ ] **Step 1: Add `focus` case to SessionType and `durationMinutes` to TimerSession**

Full file should become:

```swift
import Foundation
import SwiftData

enum SessionType: String, Codable {
    case work        // Legacy — kept for backward compat with existing data
    case shortBreak  // Legacy
    case longBreak   // Legacy
    case focus       // New
}

@Model
final class TimerSession {
    var id: UUID
    var typeRaw: String
    var duration: TimeInterval
    var durationMinutes: Int
    var startedAt: Date
    var completedAt: Date?
    var wasSkipped: Bool
    var pausedElapsed: TimeInterval

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .focus }
        set { typeRaw = newValue.rawValue }
    }

    init(type: SessionType, duration: TimeInterval, durationMinutes: Int = 0) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.duration = duration
        self.durationMinutes = durationMinutes
        self.startedAt = Date()
        self.completedAt = nil
        self.wasSkipped = false
        self.pausedElapsed = 0
    }
}
```

Note: We keep the old `SessionType` cases for backward compatibility with existing SwiftData records. New sessions use `.focus`. The `durationMinutes` field stores the user's chosen duration for XP calculation.

- [ ] **Step 2: Commit**

```bash
git add NiwaShared/Models/TimerSession.swift
git commit -m "feat: add focus session type and durationMinutes to TimerSession"
```

---

### Task 3: Update UserProfile Model

**Files:**
- Modify: `NiwaShared/Models/UserProfile.swift`

- [ ] **Step 1: Replace pomodoro fields with focusPresetMinutes**

In `UserProfile.swift`:

1. Replace lines 27-31 (the 4 pomodoro fields):
```swift
    // Pomodoro
    var pomoDurationMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var sessionsBeforeLongBreak: Int
```

With:
```swift
    // Focus Timer
    var focusPresetMinutes: [Int]
```

2. Replace lines 73-76 in `init()`:
```swift
        self.pomoDurationMinutes = XPConstants.defaultWorkMinutes
        self.shortBreakMinutes = XPConstants.defaultShortBreakMinutes
        self.longBreakMinutes = XPConstants.defaultLongBreakMinutes
        self.sessionsBeforeLongBreak = XPConstants.defaultSessionsBeforeLongBreak
```

With:
```swift
        self.focusPresetMinutes = XPConstants.defaultFocusPresets
```

- [ ] **Step 2: Commit**

```bash
git add NiwaShared/Models/UserProfile.swift
git commit -m "feat: replace pomodoro settings with focusPresetMinutes on UserProfile"
```

---

## Chunk 2: Engine

### Task 4: Create FocusTimerEngine

**Files:**
- Create: `NiwaShared/Engines/FocusTimerEngine.swift`
- Delete: `NiwaShared/Engines/PomodoroTimerEngine.swift`

- [ ] **Step 1: Create `FocusTimerEngine.swift`**

```swift
import Foundation
import SwiftData
import Observation

enum FocusTimerState: Equatable {
    case idle
    case focusing
    case complete
}

@MainActor
@Observable
final class FocusTimerEngine {
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine

    private(set) var state: FocusTimerState = .idle
    private(set) var selectedMinutes: Int = 25
    private(set) var remainingSeconds: TimeInterval = 0
    private(set) var totalDuration: TimeInterval = 0
    private(set) var todayCompletedSessions: Int = 0
    private(set) var lastAwardedXP: Int = 0

    // Presets from UserProfile
    private(set) var presets: [Int] = XPConstants.defaultFocusPresets

    private var sessionStartDate: Date?
    private var currentSession: TimerSession?
    private var displayTimer: Timer?
    private var completeResetTask: Task<Void, Never>?

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    var formattedTime: String {
        let total = Int(remainingSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine
        loadSettings()
        loadTodayCount()
        resumeIncompleteSession()
    }

    // MARK: - Controls

    func start(minutes: Int) {
        guard state == .idle else { return }
        selectedMinutes = minutes
        let duration = TimeInterval(minutes * 60)

        let session = TimerSession(type: .focus, duration: duration, durationMinutes: minutes)
        modelContext.insert(session)
        try? modelContext.save()

        currentSession = session
        sessionStartDate = Date()
        totalDuration = duration
        remainingSeconds = duration
        state = .focusing
        startDisplayTimer()
    }

    func cancel() {
        guard state == .focusing else { return }
        currentSession?.wasSkipped = true
        currentSession?.completedAt = Date()
        try? modelContext.save()
        resetToIdle()
    }

    // MARK: - Session Completion

    private func completeSession() {
        guard let session = currentSession else { return }

        session.completedAt = Date()
        try? modelContext.save()

        let xp = session.durationMinutes * XPConstants.focusXPPerMinute
        gamificationEngine.awardXP(source: .timer, amount: xp, context: modelContext)

        lastAwardedXP = xp
        todayCompletedSessions += 1
        stopDisplayTimer()
        state = .complete

        // Auto-return to idle after 3 seconds
        completeResetTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                resetToIdle()
            }
        }
    }

    private func resetToIdle() {
        completeResetTask?.cancel()
        completeResetTask = nil
        state = .idle
        stopDisplayTimer()
        sessionStartDate = nil
        currentSession = nil
        remainingSeconds = 0
        totalDuration = 0
    }

    // MARK: - Display Timer

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func updateRemainingTime() {
        guard let startDate = sessionStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, totalDuration - elapsed)
        remainingSeconds = remaining
        if remaining <= 0 {
            completeSession()
        }
    }

    // MARK: - Persistence

    private func resumeIncompleteSession() {
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        // Only resume focus sessions
        guard session.typeRaw == "focus" else {
            // Mark legacy sessions as skipped
            session.wasSkipped = true
            session.completedAt = Date()
            try? modelContext.save()
            return
        }

        let elapsed = Date().timeIntervalSince(session.startedAt)
        let remaining = session.duration - elapsed

        if remaining > 0 {
            currentSession = session
            sessionStartDate = session.startedAt
            totalDuration = session.duration
            remainingSeconds = remaining
            selectedMinutes = session.durationMinutes
            state = .focusing
            startDisplayTimer()
        } else {
            // Session expired while app was closed — award XP
            session.completedAt = Date()
            if !session.wasSkipped {
                let xp = session.durationMinutes * XPConstants.focusXPPerMinute
                gamificationEngine.awardXP(source: .timer, amount: xp, context: modelContext)
                todayCompletedSessions += 1
            }
            try? modelContext.save()
        }
    }

    func loadSettings() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? modelContext.fetch(descriptor).first else { return }
        presets = profile.focusPresetMinutes
    }

    private func loadTodayCount() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate {
                $0.completedAt != nil &&
                $0.wasSkipped == false &&
                $0.completedAt! >= startOfDay
            }
        )
        todayCompletedSessions = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
```

- [ ] **Step 2: Delete `PomodoroTimerEngine.swift`**

```bash
rm "NiwaShared/Engines/PomodoroTimerEngine.swift"
```

- [ ] **Step 3: Regenerate Xcode project**

Run: `cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate`

- [ ] **Step 4: Commit**

```bash
git add NiwaShared/Engines/FocusTimerEngine.swift
git add -u NiwaShared/Engines/PomodoroTimerEngine.swift
git commit -m "feat: replace PomodoroTimerEngine with FocusTimerEngine (3-state focus timer)"
```

---

## Chunk 3: Views & Wiring

### Task 5: Update NiwaApp.swift

**Files:**
- Modify: `NiwaApp/NiwaApp.swift`

- [ ] **Step 1: Replace all PomodoroTimerEngine references with FocusTimerEngine**

Line 13: `let timerEngine: PomodoroTimerEngine` → `let timerEngine: FocusTimerEngine`

Line 59: `timerEngine = PomodoroTimerEngine(modelContext: context, gamificationEngine: engine)` → `timerEngine = FocusTimerEngine(modelContext: context, gamificationEngine: engine)`

Line 137: `let timerEngine: PomodoroTimerEngine` → `let timerEngine: FocusTimerEngine`

Lines 144-145 (MenuBarIcon): Remove the `isPaused` computed property:
```swift
    private var isPaused: Bool {
        timerEngine.state == .paused
    }
```

Lines 147-149 (MenuBarIcon): Remove `isBreak`:
```swift
    private var isBreak: Bool {
        timerEngine.state == .shortBreak || timerEngine.state == .longBreak
    }
```

Update `isActive` (line 139-141):
```swift
    private var isActive: Bool {
        timerEngine.state == .focusing
    }
```

Update `timerColor` (lines 155-163) — simplify since no break state:
```swift
    private var timerColor: Color {
        if timerEngine.remainingSeconds < 180 && timerEngine.remainingSeconds > 0 {
            return Color(red: 224/255, green: 122/255, blue: 95/255) // Urgent terracotta
        } else {
            return Color(red: 76/255, green: 217/255, blue: 100/255) // Focus green
        }
    }
```

Update the menu bar body (lines 170-189) — remove `isPaused` reference:
```swift
    var body: some View {
        HStack(spacing: 3) {
            Image("MenuBarIcon")
                .renderingMode(.template)

            if isActive {
                VStack(spacing: 1) {
                    Text(timerEngine.formattedTime)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .monospacedDigit()

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
```

- [ ] **Step 2: Commit**

```bash
git add NiwaApp/NiwaApp.swift
git commit -m "feat: update NiwaApp and MenuBarIcon to use FocusTimerEngine"
```

---

### Task 6: Update DropdownRootView

**Files:**
- Modify: `NiwaApp/Views/DropdownRootView.swift`

- [ ] **Step 1: Update engine type and sound callback**

Line 7: `let timerEngine: PomodoroTimerEngine` → `let timerEngine: FocusTimerEngine`

Replace the timer state sound callback (lines 106-115):
```swift
        .onChange(of: timerEngine.state) { oldState, newState in
            if oldState == .working && (newState == .shortBreak || newState == .longBreak) {
                soundManager.play(.timerComplete)
            }
            if (oldState == .shortBreak || oldState == .longBreak) && newState == .idle {
                soundManager.play(.breakComplete)
            }
        }
```

With:
```swift
        .onChange(of: timerEngine.state) { oldState, newState in
            if newState == .complete {
                soundManager.play(.timerComplete)
            }
        }
```

- [ ] **Step 2: Merge the two reset functions into one**

Replace both `resetAllData()` (lines 339-367) and `fullRestart()` (lines 369-396) with a single function:

```swift
    private func resetAllData() {
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
            timerEngine.cancel()
            taskManager.refreshTasks()
            noteManager.refreshNotes()
            resetStatusMessage = "All data reset. Fresh start!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    showSettings = false
                    showWelcome = true
                    resetStatusMessage = ""
                }
            }
        } catch {
            resetStatusMessage = "Reset failed: \(error.localizedDescription)"
        }
    }
```

Remove `fullRestart()` entirely. Update `InlineSettingsView` call site accordingly (Task 8).

Also update the `timerEngine.skip()` call in the reset function to `timerEngine.cancel()` since the new engine uses `cancel()`.

- [ ] **Step 3: Remove `onFullRestart` from the `InlineSettingsView` init call**

In `mainContent` (around line 33-40), change:
```swift
                    InlineSettingsView(
                        profileManager: profileManager,
                        timerEngine: timerEngine,
                        healthManager: healthManager,
                        onResetData: { resetAllData() },
                        onFullRestart: { fullRestart() },
                        statusMessage: resetStatusMessage
                    )
```

To:
```swift
                    InlineSettingsView(
                        profileManager: profileManager,
                        timerEngine: timerEngine,
                        healthManager: healthManager,
                        onResetData: { resetAllData() },
                        statusMessage: resetStatusMessage
                    )
```

- [ ] **Step 4: Commit**

```bash
git add NiwaApp/Views/DropdownRootView.swift
git commit -m "feat: update DropdownRootView for FocusTimerEngine, merge reset into single function"
```

---

### Task 7: Rewrite HeroView Timer Section

**Files:**
- Modify: `NiwaApp/Views/Components/HeroView.swift`

- [ ] **Step 1: Rewrite HeroView for focus timer UI**

Full file replacement:

```swift
import SwiftUI
import SwiftData

/// Combined top section: plant with XP ring, and focus timer side-by-side
struct HeroView: View {
    @Query private var profiles: [UserProfile]
    let engine: FocusTimerEngine

    private var profile: UserProfile? { profiles.first }
    private var level: Int { profile?.currentLevel ?? 0 }
    private var totalXP: Int { profile?.totalXP ?? 0 }

    private var progress: (current: Int, needed: Int) {
        let result = XPConstants.xpForNextLevel(currentTotalXP: totalXP)
        return (current: result.currentLevelXP, needed: result.nextLevelXP)
    }

    private var fillFraction: Double {
        guard progress.needed > 0 else { return 0 }
        return Double(progress.current) / Double(progress.needed)
    }

    @State private var customMinutes: Int = 25

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            plantWithXPRing
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(DesignTokens.Colors.subtle)
                .frame(width: 1, height: 110)

            focusTimer
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Plant with XP Ring

    private var plantWithXPRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: fillFraction)
                    .stroke(
                        DesignTokens.Colors.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.xpBarFill, value: fillFraction)

                PlantView(level: level)
                    .scaleEffect(0.75)
            }

            Text("Level \(level)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("\(progress.current)/\(progress.needed) XP")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textMuted)
        }
    }

    // MARK: - Focus Timer

    @ViewBuilder
    private var focusTimer: some View {
        switch engine.state {
        case .idle:
            idleView
        case .focusing:
            focusingView
        case .complete:
            completeView
        }
    }

    // MARK: - Idle State

    private var idleView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Preset chips
            HStack(spacing: 4) {
                ForEach(engine.presets, id: \.self) { minutes in
                    Button {
                        engine.start(minutes: minutes)
                    } label: {
                        Text("\(minutes)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.primary)
                            .frame(minWidth: 28, minHeight: 24)
                            .padding(.horizontal, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primary.opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(DesignTokens.Colors.primary.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("\(minutes) min focus · +\(minutes * XPConstants.focusXPPerMinute) XP")
                }
            }

            // Custom duration row
            HStack(spacing: 4) {
                Button {
                    customMinutes = max(1, customMinutes - 5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(DesignTokens.Colors.backgroundSecondary))
                }
                .buttonStyle(.plain)

                Text("\(customMinutes) min")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .monospacedDigit()
                    .frame(minWidth: 40)

                Button {
                    customMinutes = min(120, customMinutes + 5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(DesignTokens.Colors.backgroundSecondary))
                }
                .buttonStyle(.plain)

                Button {
                    engine.start(minutes: customMinutes)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(DesignTokens.Colors.primary.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .help("Start \(customMinutes) min focus")
            }

            // Streak dots
            if engine.todayCompletedSessions > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<min(engine.todayCompletedSessions, 10), id: \.self) { _ in
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 5, height: 5)
                    }
                    if engine.todayCompletedSessions > 10 {
                        Text("+\(engine.todayCompletedSessions - 10)")
                            .font(.system(size: 8))
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                    }
                }
            } else {
                Text("No sessions today")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
        }
    }

    // MARK: - Focusing State

    private var focusingView: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.subtle, lineWidth: 3)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Animation.viewTransition, value: engine.progress)

                VStack(spacing: 0) {
                    Text(engine.formattedTime)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .monospacedDigit()

                    Text("\(engine.selectedMinutes) min")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Button {
                engine.cancel()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Complete State

    private var completeView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.primary)
            }

            Text("+\(engine.lastAwardedXP) XP")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.primary)
        }
    }

    // MARK: - Plant Stage Name

    private var plantStageName: String {
        XPConstants.plantStageName(for: level)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add NiwaApp/Views/Components/HeroView.swift
git commit -m "feat: rewrite HeroView with focus timer UI (presets, countdown, completion)"
```

---

### Task 8: Update InlineSettingsView

**Files:**
- Modify: `NiwaApp/Views/Settings/InlineSettingsView.swift`

- [ ] **Step 1: Update engine type**

Line 7: `let timerEngine: PomodoroTimerEngine` → `let timerEngine: FocusTimerEngine`

- [ ] **Step 2: Remove `onFullRestart` parameter**

Remove `let onFullRestart: () -> Void` from the struct properties (line 9 area).

- [ ] **Step 3: Replace timer settings section**

Replace lines 44-58 (the Timer section):
```swift
                    settingsSection("\u{23F1}\u{FE0F}  Timer") {
                        settingsStepper("Work", value: profile.pomoDurationMinutes, unit: "min", range: 1...120) {
                            profile.pomoDurationMinutes = $0; saveTimer()
                        }
                        settingsStepper("Short Break", value: profile.shortBreakMinutes, unit: "min", range: 1...60) {
                            profile.shortBreakMinutes = $0; saveTimer()
                        }
                        settingsStepper("Long Break", value: profile.longBreakMinutes, unit: "min", range: 1...60) {
                            profile.longBreakMinutes = $0; saveTimer()
                        }
                        settingsStepper("Sessions before long break", value: profile.sessionsBeforeLongBreak, unit: "", range: 1...10) {
                            profile.sessionsBeforeLongBreak = $0; saveTimer()
                        }
                    }
```

With:
```swift
                    settingsSection("\u{23F1}\u{FE0F}  Focus Timer") {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Quick Pick Presets")
                                .font(DesignTokens.Typography.bodyFont)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            HStack(spacing: 6) {
                                ForEach(Array(profile.focusPresetMinutes.enumerated()), id: \.offset) { index, minutes in
                                    HStack(spacing: 2) {
                                        Button {
                                            let newVal = max(1, minutes - 5)
                                            profile.focusPresetMinutes[index] = newVal
                                            saveTimer()
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(DesignTokens.Colors.textMuted)
                                        }
                                        .buttonStyle(.plain)

                                        Text("\(minutes)")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                                            .monospacedDigit()
                                            .frame(minWidth: 24)

                                        Button {
                                            let newVal = min(120, minutes + 5)
                                            profile.focusPresetMinutes[index] = newVal
                                            saveTimer()
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(DesignTokens.Colors.textMuted)
                                        }
                                        .buttonStyle(.plain)

                                        // Remove button (keep at least 1 preset)
                                        if profile.focusPresetMinutes.count > 1 {
                                            Button {
                                                profile.focusPresetMinutes.remove(at: index)
                                                saveTimer()
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 7, weight: .bold))
                                                    .foregroundStyle(DesignTokens.Colors.textMuted.opacity(0.5))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(DesignTokens.Colors.backgroundSecondary)
                                    )
                                }

                                // Add button (max 5 presets)
                                if profile.focusPresetMinutes.count < 5 {
                                    Button {
                                        profile.focusPresetMinutes.append(30)
                                        saveTimer()
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 14))
                                            .foregroundStyle(DesignTokens.Colors.primary.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    }
```

- [ ] **Step 4: Consolidate reset into single button**

Remove the "Full Restart" section (the `confirmingFullRestart` block and related `dataRow`). Keep only the single "Reset All Data" button but update its description:

Replace the existing Reset + Full Restart blocks (around lines 129-169) with just one reset block:

```swift
                        // Reset
                        if confirmingReset {
                            confirmationRow(
                                message: "This will wipe everything — tasks, notes, XP, settings — and start fresh from Level 0. This cannot be undone.",
                                confirmLabel: "Reset Everything",
                                onConfirm: {
                                    confirmingReset = false
                                    onResetData()
                                },
                                onCancel: { confirmingReset = false }
                            )
                        } else {
                            dataRow(icon: "arrow.counterclockwise", label: "Reset All Data", color: DesignTokens.Colors.danger, description: "Wipes everything and starts fresh from Level 0.") {
                                withAnimation(DesignTokens.Animation.viewTransition) {
                                    confirmingReset = true
                                }
                            }
                        }
```

Remove `@State private var confirmingFullRestart = false` (line 14).

Remove the `onFullRestart` property entirely.

- [ ] **Step 5: Commit**

```bash
git add NiwaApp/Views/Settings/InlineSettingsView.swift
git commit -m "feat: replace pomodoro settings with focus presets, consolidate reset"
```

---

### Task 9: Delete Unused TimerView & Build

**Files:**
- Delete: `NiwaApp/Views/TimerView.swift` (unused — timer lives in HeroView)

- [ ] **Step 1: Delete the unused file**

```bash
rm "NiwaApp/Views/TimerView.swift"
```

- [ ] **Step 2: Regenerate Xcode project and build**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build 2>&1 | tail -20
```

Fix any compile errors that arise.

- [ ] **Step 3: Commit**

```bash
git add -u NiwaApp/Views/TimerView.swift
git commit -m "chore: remove unused TimerView (timer lives in HeroView)"
```

---

### Task 10: Final Build, Test & Launch

- [ ] **Step 1: Full clean build**

```bash
cd "/Users/james/Claude Projects/Niwa/Niwa" && xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug clean build 2>&1 | tail -30
```

- [ ] **Step 2: Launch and manually verify**

```bash
pkill -f "Niwa.app" 2>/dev/null; sleep 1; open "build/Build/Products/Debug/Niwa.app"
```

Verify:
- [ ] Preset chips show (15, 25, 45)
- [ ] Tapping a preset starts the countdown
- [ ] Countdown ring progresses and time decrements
- [ ] Cancel button stops and returns to idle (no XP)
- [ ] Timer completing shows checkmark + XP + plays sound
- [ ] Auto-returns to idle after ~3 seconds
- [ ] Custom duration stepper works
- [ ] Menu bar shows countdown when focusing
- [ ] Settings → Focus Timer shows editable presets
- [ ] Reset All Data wipes everything and shows welcome
- [ ] Streak dots appear after completing a session

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: focus timer complete — replaces pomodoro with simple commit-or-cancel focus sessions"
```
