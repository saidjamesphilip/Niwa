# Niwa Design Decisions

Reference document for final design choices made during development. Use this when building new features to maintain consistency.

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

## Health Status Pills (v1.3.11)

**Layout:** Horizontal row of capsule-shaped pills in the dropdown

| Pill | Icon | SF Symbol | Color | XP | Frequency |
|------|------|-----------|-------|-----|-----------|
| Water | Drop | `drop.fill` | Sage (#81B29A) | +10 | Multiple/day |
| Stand | Figure | `figure.stand` | Sage (#81B29A) | +10 | Multiple/day |
| Creatine | Bolt | `bolt.fill` | Amber (#E0AC3A) | +15 | Once/day |
| Gym | Dumbbell | `dumbbell.fill` | Terracotta (#E07A5F) | +30 | Once/day |

**States:**
- Available: full color, shows label text
- Logged (once-daily items): dimmed (50% opacity), shows checkmark instead of label
- Standing active: pulsing icon + elapsed timer + stop button

**Tooltips (hover):**
- Water: "Log water (+10 XP)"
- Stand: "Start standing session (+10 XP)"
- Creatine: "Log creatine (+15 XP) · Once daily" / "Creatine logged today"
- Gym: "Log gym session (+30 XP) · Once daily" / "Gym logged today"

**Rejected icons:**
- Creatine: pill capsule (pills.fill), flask (flask.fill)
- Gym: runner (figure.run), flame (flame.fill)

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

## XP Chart (v1.3.11)

- Stacked bar chart, 7 days, 36px bar height
- Source colors (top to bottom in stack):
  - Gym: Terracotta (primary)
  - Creatine: Amber
  - Stand: Sage (60% opacity)
  - Water: Sage
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

## General UI Conventions

- All previews/mockups must use Niwa brand colors and design tokens
- Hover states: `.easeInOut(duration: 0.15)`
- View transitions: `DesignTokens.Animation.viewTransition`
- Context menus for secondary actions on all interactive rows
- `.help()` modifier on all interactive pills/buttons for tooltip text
