# QA Plan — Quality Fixes (v1.3.13)

**Branch:** `dev/quick-wins-2026-03-15`
**Date:** 2026-03-16
**Tester:** James

> Work through each section in order. Check the box when verified. If something fails, note the behavior next to the item.

---

## Prerequisites

- [ ] Build the app from the branch (`Cmd+B` in Xcode or `xcodebuild`)
- [ ] Launch the app — confirm it opens in the menu bar without crashes
- [ ] If prompted with the Garden Gate welcome screen, enter a name and proceed

---

## 1. Quit Warning During Active Focus Timer

**What changed:** App now warns you before quitting if a focus timer is running.

- [ ] Start a focus timer (any duration)
- [ ] While timer is running, press `Cmd+Q` or use the Quit menu item
- [ ] **Expected:** An alert appears: "Focus session in progress" with "Quit Anyway" and "Cancel" buttons
- [ ] Click **Cancel** — app stays open, timer continues
- [ ] Press `Cmd+Q` again, click **Quit Anyway** — app quits
- [ ] Relaunch the app. With NO timer running, press `Cmd+Q`
- [ ] **Expected:** App quits immediately with no alert

---

## 2. Health Event Performance (Date-Filtered Predicate)

**What changed:** Water/creatine/gym/coffee counts now filter in the database instead of loading all events.

- [ ] Log 2-3 water events by tapping the water pill
- [ ] Log a coffee event
- [ ] **Expected:** Counts display correctly in the health pills
- [ ] Close and reopen the dropdown — counts persist and display correctly
- [ ] Check that the health pills reset properly after 7am (if testing across days)

---

## 3. XP Chart (Pre-filtered Events)

**What changed:** XP chart no longer loads entire event history — parent passes filtered data.

- [ ] Open the dropdown — XP chart should render with recent data
- [ ] Complete a task to earn XP — chart should update to reflect the new event
- [ ] **Expected:** Chart shows last 7 days of XP, bars are accurate, no blank chart

---

## 4. Profile Caching

**What changed:** User profile is cached instead of fetched from the database on every access.

- [ ] Open Settings > change your display name
- [ ] **Expected:** Name updates immediately in the header/greeting
- [ ] Close and reopen dropdown — name persists
- [ ] Use "Reset All Data" in settings — confirm app resets cleanly with a new welcome screen

---

## 5. Widget — Cached Container + 7am Day Start + Design Tokens

**What changed:** Widget reuses a single database container, uses 7am day boundary (matching the app), and uses shared brand color tokens.

- [ ] Add all 3 widget sizes (small, medium, large) to your desktop if not already present
- [ ] Log some water and complete a task in the app
- [ ] Wait for widget refresh (or lock/unlock screen to force it)
- [ ] **Expected (small widget):** Shows XP level, plant, and current stats
- [ ] **Expected (medium widget):** Shows XP level, tasks, and water count matching the app
- [ ] **Expected (large widget):** Shows full stats including sparkline chart
- [ ] **Expected (all sizes):** Colors match Niwa's brand (terracotta, sage, cream) — no stray blue/red system colors
- [ ] Verify water count in widget matches water count in the app (especially important between midnight and 7am)

---

## 6. Level-Up Race Condition

**What changed:** Level-up detection uses an incrementing counter instead of a boolean flag, so rapid level-ups aren't missed.

- [ ] If your XP is close to a level boundary, complete tasks rapidly to level up
- [ ] **Expected:** Level-up overlay appears each time you cross a level boundary
- [ ] **Expected:** The Zen level-up overlay displays correctly (plant, level number, dismiss)
- [ ] Dismiss the overlay — it should not reappear until the next actual level-up

> Note: This is hard to test manually unless you're near a level boundary. If not, verify the overlay works at least once.

---

## 7. Notification Permission Indicator

**What changed:** Settings now shows whether notification permissions are "Allowed" or "Blocked."

- [ ] Open Settings > scroll to the health/reminders section
- [ ] **Expected:** A pill/label appears near "Manage in System Settings" showing permission status
- [ ] If notifications are **allowed**: green "Allowed" indicator
- [ ] If notifications are **blocked**: orange "Blocked" indicator (clicking should open System Settings)

---

## 8. @Observable Migration (TaskManager, NoteManager, UpdateChecker)

**What changed:** Migrated from old `ObservableObject` pattern to modern `@Observable`.

- [ ] **Tasks:** Create a new task — confirm it appears in the list
- [ ] Edit a task title — confirm it updates
- [ ] Complete a task (check it off) — confirm it moves to completed, XP awarded
- [ ] Delete a task — confirm it disappears
- [ ] **Notes:** Create a new note — confirm it appears
- [ ] Edit note content — confirm it saves
- [ ] Delete a note — confirm it disappears
- [ ] **Update checker:** Open Settings — the version number and "Check for updates" should work without crashes

---

## 9. PlantView Dedup

**What changed:** PlantView now uses shared `XPConstants.plantStage()` instead of its own duplicate logic.

- [ ] View the plant in the dropdown header
- [ ] **Expected:** Plant icon matches your current level (seed → sprout → seedling → ... → ancient tree)
- [ ] If you level up, the plant should evolve to match the new stage

---

## 10. Dead Schema Fields Removed

**What changed:** Removed unused `pausedElapsed`, `snoozedUntil`, and legacy session types.

- [ ] Start and complete a focus timer session
- [ ] **Expected:** Session completes normally, XP is awarded
- [ ] Check that the focus timer works end-to-end (start → focusing → complete → XP)
- [ ] **Expected:** No crashes related to missing database fields

> Note: If upgrading from a previous version, the app may reset its data store (existing behavior for schema changes). This is expected.

---

## 11. Full JSON Export

**What changed:** Export now includes HealthEvent and TimerSession data.

- [ ] Log some health events (water, coffee, etc.) and complete a focus session
- [ ] Open Settings > Export Data
- [ ] Save the JSON file and open it in a text editor
- [ ] **Expected:** JSON contains `healthEvents` array with entries (type, confirmedAt, etc.)
- [ ] **Expected:** JSON contains `timerSessions` array with entries (type, durationMinutes, startedAt, etc.)
- [ ] **Expected:** Existing export data (tasks, notes, xpEvents, profiles) still present

---

## 12. Clipboard Feature Removed

**What changed:** Clipboard history feature was fully removed (model, service, view, tab).

- [ ] **Expected:** No "Clipboard" tab or option visible anywhere in the UI
- [ ] **Expected:** No crashes when navigating between tabs (Tasks, Notes, Settings)

---

## 13. Regression Checks

Run through core app flows to ensure nothing broke:

- [ ] **App launch:** Menu bar icon appears, dropdown opens on click
- [ ] **Dropdown resize:** Drag handle works, dropdown remembers size
- [ ] **Tab navigation:** Switch between Tasks, Notes, Settings — all render correctly
- [ ] **XP system:** Completing tasks awards XP, XP bar updates
- [ ] **Health pills:** All pills (water, creatine, gym, coffee, standing) are tappable and functional
- [ ] **Sound effects:** XP earned and level-up sounds play (if enabled)
- [ ] **Settings:** All settings sections load, toggles work
- [ ] **Reset All Data:** Resets everything, shows welcome screen again

---

## Sign-Off

- [ ] All items above pass
- [ ] No crashes observed during testing
- [ ] Ready to merge PR and tag release
