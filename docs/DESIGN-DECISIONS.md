# Niwa Design Decisions

Reference document for final design choices made during development. Use this when building new features to maintain consistency.

---

## Focus Timer (improvements-and-qol)

**Chosen: Simple commit-or-cancel focus sessions**

- Replaced 5-state Pomodoro (idle/working/paused/shortBreak/longBreak) with 3-state focus timer (idle/focusing/complete)
- Preset duration chips: configurable list (default 15/25/45 min), max 5 presets
- Custom duration stepper: 1–120 min
- No pausing, no breaks, no rounds — commit or cancel only
- XP: 1 per minute of chosen duration (e.g. 25 min = +25 XP)
- Auto-return to idle after 3 seconds on completion
- Session persistence: resumes incomplete sessions across app restarts
- Daily streak dots: one dot per completed session today

**Rejected:** Keeping full Pomodoro — added complexity without value, users skipped breaks or found rigid structure frustrating.

---

## Dropdown Sizing (improvements-and-qol)

**Chosen: Screen-percentage height with expand/collapse toggle**

- Default height: 30% of visible screen height
- Expanded height: 50% of visible screen height (toggle via chevron button in toolbar)
- Settings and Sounds views match main dashboard height exactly via `GeometryReader` + `PreferenceKey`
- Width fixed at 380pt

**Rejected:** Drag-to-resize handle — caused constraint crashes in MenuBarExtra window during animated transitions. Replaced with simpler expand/collapse approach.

---

## MenuBarExtra Crash Fix (improvements-and-qol)

**Problem:** Switching between main content ↔ settings/sounds views with `withAnimation` caused `NSWindow._postWindowNeedsUpdateConstraints` crash.

**Fix:** Removed all `withAnimation` from settings/sounds view toggles. View transitions are now instant (no animation). The MenuBarExtra window style cannot handle animated constraint changes during view hierarchy swaps.

---

## Tab Touch Targets (improvements-and-qol)

- Tasks/Notes segmented control now uses `md` vertical padding (up from `sm`) and `.contentShape(Rectangle())` for full-width tappable area

---

## Task List (v1.3.11)

**Chosen: Option F — Priority + Due Dates**

- Priority system: None / Low / Medium / High
- 3px colored left bar per row: red (high), amber (medium), sage (low), hidden (none)
- Due date badges: colored pill with text (Overdue = red, Today = terracotta, Tomorrow = amber, future = muted date)
- Context menu for setting priority and due date (Today, Tomorrow, Next Monday, In 1 Week, Remove)
- Hover-reveal action buttons (move up/down, delete)
- Compact rows: 3px vertical padding, 16px checkbox, 20px priority bar height
- Default visible: 10 tasks, "Show more/less" toggle
- Max scroll height: 600px

**Rejected options:**
- A: Simple checkbox list (too basic)
- B: Subtasks (deferred to future)
- C: Tags/labels
- D: Subtasks + priority combo
- E: Kanban-style

---

## Notes List (v1.3.11)

**Chosen: Option C — Inline Editing with Per-Note Colors**

- 5 cycling colors: Terracotta, Sage, Lavender, Amber, Sky
- Colors auto-assigned via `colorIndex` (cycles through 0-4)
- Collapsed row: 3px color bar + text preview (60 chars) + metadata (date, word count)
- Expanded row: inline TextEditor with Done button, bordered with note's color
- Auto-save when switching between notes or pressing Done
- Default visible: 7 notes, "Show more/less" toggle
- Max scroll height: 600px

**Color values:**
```
Terracotta: rgb(224, 122, 95)
Sage:       rgb(129, 178, 154)
Lavender:   rgb(168, 130, 196)
Amber:      rgb(224, 172, 58)
Sky:        rgb(100, 165, 210)
```

**Rejected options:**
- A: Simple list with modal editor
- B: Card grid layout

---

## Timer Menu Bar (v1.3.11)

**Chosen: Option C — MM:SS + Progress Bar + Urgency Color**

- Idle: Niwa icon only (no timer text)
- Active: Niwa icon + MM:SS countdown + mini progress bar underneath
- Progress bar: 40px wide, 2px tall, shrinks left-to-right as time passes
- Color coding:
  - Focus: Green (#4CD964)
  - Break: Blue (#5AC8FA)
  - Under 3 minutes remaining: Terracotta (#E07A5F) — urgency indicator
- Paused: text dimmed (secondary opacity)
- Font: SF Mono, 10pt medium, monospaced digit

**Rejected options:**
- A: Pulsing dot + compact "Xm" (current before v1.4.0)
- B: Full MM:SS + dot (no progress visual)
- D: Mini circular ring + compact time
- E: Emoji per session type
- F: Ring + full MM:SS (too wide)

---

## Health Status Pills (improvements-and-qol)

**Layout:** Horizontal row of icon-only capsule pills with info popover

| Pill | SF Symbol | Color | XP | Frequency |
|------|-----------|-------|-----|-----------|
| Water | `drop.fill` | Sage (#81B29A) | +10 | Multiple/day |
| Coffee | `cup.and.saucer.fill` | Brown (#8B5A2B) | +10 (−5 after 3) | Multiple/day |
| Stand | `figure.stand` | Sage (#81B29A) | +10 + milestones | Multiple/day |
| Creatine | `bolt.fill` | Amber (#E0AC3A) | +15 | Once/day |
| Gym | `dumbbell.fill` | Terracotta (#E07A5F) | +30 | Once/day |

**States:**
- Water: icon only when 0, icon + count when > 0
- Coffee: icon only when 0, icon + count when > 0. Pill turns terracotta after 3 (penalty warning)
- Stand idle: icon only. Active: pulsing icon + elapsed timer + milestone badge
- Creatine/Gym unlogged: icon only. Logged: icon dimmed (40% opacity)
- Undo mode (creatine/gym): "Undo −XP" text, danger color, auto-dismiss after 3s

**Standing milestones:** +5 XP at 10 min, +10 at 20 min, +15 at 30 min (cumulative badge shown)

**Info popover:** "?" button reveals grid explaining each habit with XP values

**Hover effects:** Lift 1px + brightness +15%, easeOut 0.2s

**Undo flow:** Tap logged pill → shows "Undo −XP" confirmation → tap confirms → deducts XP and deletes event

---

## Reminders (v1.3.11)

**Behavior:**
- Only fire while the app is running (cancelled on quit)
- Respect configured intervals from last action time (not app launch)
- Smart scheduling: pause during lunch, skip outside work hours
- macOS native notifications with action buttons (Done / Snooze 10 min)
- Toggle on/off in Settings with "Manage in System Settings" deep link

**Defaults:**
- Water: every 30 min
- Stand: every 45 min
- Work hours: 9 AM - 5 PM
- Lunch: 12 PM - 1 PM
- Snooze: 10 minutes

---

## Empty States (v1.3.11)

- Tasks: `PlantView(level: 0)` seed icon + "Plant a seed — add your first task"
- Notes: `PlantView(level: 0)` seed icon + "Jot down a thought to help your garden grow"
- Scale: 0.45, frame 40x40, opacity 0.6

---

## XP Chart (v1.3.12)

- Stacked bar chart, 7 days, 36px bar height
- Source colors (top to bottom in stack):
  - Gym: Terracotta (primary)
  - Creatine: Amber
  - Stand: Sage (60% opacity)
  - Water: Sage
  - Coffee: Brown (#8B5A2B)
  - Note: Primary (50% opacity)
  - Timer: Primary (75% opacity)
  - Task: Primary (35% opacity)

---

## Reset Buttons (v1.3.11)

- No `.alert()` modifiers (crash in MenuBarExtra)
- Inline confirmation: warning text + Cancel / Confirm buttons
- In-place data reset without app restart
- Success message banner with auto-navigate to dashboard after 1.5s

---

## Daily Habit Reset (v1.3.12)

- All daily habits reset at **7am**, not midnight
- Rationale: habits logged after midnight (e.g. 2am) should count toward the previous day
- Timer fires at next 7am to auto-refresh stats while app is running
- `HealthEventManager.habitDayStart()` calculates the boundary

---

## Welcome Screen (v1.3.12)

**Chosen: Garden Gate (Option C)**

- ⛩️ Torii gate icon as hero visual
- Sage gradient header background
- 4 feature highlights (timer, tasks, health, plant growth) with SF Symbol icons
- Name field is **required** — button disabled until name entered
- "Enter the garden" CTA in terracotta
- No skip option, no `withAnimation` (MenuBarExtra safe)

**Rejected:** Current (too minimal), Zen Minimal, Guided Onboarding (too heavy), Story Introduction

---

## Level-Up Overlay (v1.3.12)

**Chosen: Zen Garden Minimal (Option C)**

- Dark dimmed background (black 75% opacity)
- Large plant (120pt) with subtle sage drop shadow
- Thin horizontal rules framing the content
- Light "LEVEL UP" label with 3pt letter spacing
- Large thin-weight level number (48pt, light weight)
- Sage-colored stage name
- Fade-in entrance animation (easeOut 0.4s)
- Plant stage evolution still animates on stage boundary crossings
- Auto-dismiss after 3.5s or click anywhere

**Rejected:** Sage Glow + Confetti (too busy), Warm Terracotta, Garden Bloom, Hanko Stamp

---

## Demo Content (v1.3.12)

- 3 demo tasks seeded on first launch and after reset (no XP awarded)
- 1 demo note with welcome text
- Tasks show priority (high/medium/low) and due dates (today/tomorrow/next week)
- Inserted directly into ModelContext, bypassing XP-awarding methods

---

## General UI Conventions

- All previews/mockups must use Niwa brand colors and design tokens
- Hover states: `.easeInOut(duration: 0.15)`
- View transitions: `DesignTokens.Animation.viewTransition`
- Context menus for secondary actions on all interactive rows
- `.help()` modifier on all interactive pills/buttons for tooltip text
