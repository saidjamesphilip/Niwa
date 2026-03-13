# Changelog

All notable changes to Niwa will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
