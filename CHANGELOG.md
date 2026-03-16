# Changelog

All notable changes to Niwa will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.3.13] — 2026-03-16

### Added
- Unit test suite — 49 tests across XP formulas, task model, timer formatting, and widget tokens
- Notification permission indicator in settings (green "Allowed" / orange "Blocked")
- Quit warning when closing app during active focus timer
- HealthEvent and TimerSession included in JSON data export
- Widget design tokens (shared brand colors across all 3 widget sizes)

### Fixed
- Health habit date filter pushed into SQLite predicate (was loading all events into memory)
- XP chart data cached in GamificationEngine — no longer fetches from DB on every render (~4x/sec)
- XP chart computed once per render instead of twice (DayXP struct)
- Timer display interval reduced from 250ms to 1000ms (4x fewer cascading re-renders)
- Level-up race condition — uses incrementing counter instead of boolean flag
- UserProfile cached instead of fetched on every access
- Widget reuses a single ModelContainer instead of recreating per refresh
- Widget day-start aligned to 7am (matching app behaviour)
- PlantView uses shared XPConstants.plantStage() instead of duplicate logic

### Changed
- Health pills uniform size (consistent minWidth across all 5 pills)
- Dropdown width increased 5% (380→400pt) and height reduced 5%
- Standing pill shows compact timer inline instead of expanding wider
- TaskManager and NoteManager migrated from ObservableObject to @Observable
- UpdateChecker migrated from @StateObject to @Observable + @State
- Removed dead schema fields (pausedElapsed, snoozedUntil, legacy SessionType cases)

### Removed
- Clipboard history feature (model, service, view, tab) — fully removed
- References to "Pomodoro" replaced with "Focus Timer" across website copy and meta tags

## [1.3.12] — 2026-03-13

### Added
- Focus Timer replaces Pomodoro — pick a duration (preset or custom), commit or cancel, earn 1 XP per minute
- Focus timer preset chips (default: 15/25/45 min) with custom duration stepper
- Daily focus streak dots showing completed sessions
- Coffee tracking habit (+10 XP per coffee, −5 XP penalty after 3 per day)
- Demo tasks and note seeded on first launch and after reset
- Garden Gate welcome screen with feature highlights and required name input
- Zen-style level-up overlay (minimal, no confetti)
- Editable Quick Pick Presets in settings (add/remove/adjust, max 5)
- Icon-only health pills with info popover (? button explains each habit)
- Standing XP milestones — bonus XP at 10/20/30 min thresholds
- Creatine/gym undo with XP deduction (tap logged pill → confirm undo)
- Expand/collapse button in bottom toolbar (+20% screen height)
- Wider tab touch targets for Tasks/Notes switching

### Changed
- Dropdown height now uses percentage of screen height (30% default, 50% expanded) instead of fixed pixel values
- Removed drag-to-resize handle — replaced with simple expand/collapse toggle
- Settings and Sounds views now match main dashboard height exactly (using GeometryReader preference key)
- Health pills redesigned as compact icon-only capsules (water, coffee, stand, creatine, gym)
- Timer section in settings simplified from 4 Pomodoro fields to editable preset list
- Reset consolidated into single "Reset All Data" function (removed separate Full Restart)
- Notification system rewritten with timer-based polling (fixes spam bugs)
- Daily habits now reset at 7am instead of midnight
- Level-up overlay redesigned to zen minimal style (no confetti)
- Welcome screen redesigned with feature highlights and torii gate icon
- "Tap" terminology replaced with "click" throughout (macOS app)
- Reset now fully stops timers, standing, and clears all state

### Fixed
- Settings and Sounds views no longer crash the app (removed withAnimation on MenuBarExtra view transitions)
- Notification spam eliminated (replaced UNNotification scheduling with 60-second polling timer)
- Note color cycling operator precedence bug
- Reset now properly handles all timer states (focusing, complete, idle)

## [1.3.11] — 2026-03-13

### Added
- Task priority system (high/medium/low) with colored priority bars
- Task due dates with quick-set options (Today, Tomorrow, Next Monday, In 1 Week)
- Due date badges with overdue/today/tomorrow color coding
- Inline note editing with expand/collapse in the notes list
- Per-note color coding (terracotta, sage, lavender, amber, sky)
- Creatine tracking pill (+15 XP, once daily)
- Gym tracking pill (+30 XP, once daily)
- Health reminders on/off toggle in settings
- "Manage in System Settings" link for macOS notification preferences
- Hover tooltips on all health status pills
- Smart overflow: show more/less for tasks and notes lists
- Timer menu bar upgrade: MM:SS countdown with progress bar and urgency color shift
- How Reminders Work section on website and README

### Changed
- Task rows are more compact with tighter spacing
- Increased default visible tasks (10) and notes (7)
- Increased scroll area height for tasks and notes
- XP chart reduced in height to save space
- XP chart now tracks creatine and gym sources
- Empty states use PlantView (brand seed icon) instead of generic SF Symbols
- Reminders now only fire while the app is running
- Reminder scheduling respects actual interval from last action, not just app launch time
- All pending notifications cancelled on app quit

### Fixed
- Reset buttons no longer crash/close the app (replaced .alert with inline confirmation)
- In-place data reset without app restart
- Task checkboxes now clickable (fixed .contentShape click interception)
- Task move up/down and delete actions working correctly

## [1.0.0] — 2026-03-12

### Added
- Menu bar dropdown with hero section (plant + timer + XP bar)
- Pomodoro timer with full state machine (work/short break/long break)
- Task management with quick-add, completion, and drag-to-reorder
- Quick notes with auto-save and word count
- Clipboard history monitoring (last 20 entries)
- Water and standing health reminders with smart scheduling
- XP gamification system with level-up animations
- 8 plant growth stages from Seed (L0) to Ancient Tree (L36+)
- Floating mini window (borderless, non-activating)
- Inline settings panel
- Dark mode support with System/Light/Dark toggle
- 7-day XP chart
- WidgetKit widgets (small, medium, large)
- Export data to JSON
- Reset data and full restart options
