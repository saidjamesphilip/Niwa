<p align="center">
  <img src="screenshots/niwa-icon.png" alt="Niwa Icon" width="128" />
</p>

<h1 align="center">Niwa (庭)</h1>

<p align="center">
  <strong>Grow your productivity, one session at a time.</strong>
</p>

<p align="center">
  A native macOS menu bar app that combines a Pomodoro timer, task management, quick notes, clipboard history, and health reminders — all wrapped in a gamified leveling system where your virtual plant grows as you do.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/macOS-15.0+-000000?logo=apple&logoColor=white" alt="macOS 15+" />
  <img src="https://img.shields.io/badge/SwiftUI-blue?logo=swift&logoColor=white" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/SwiftData-purple?logo=swift&logoColor=white" alt="SwiftData" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
</p>

---

<details>
<summary><strong>Table of Contents</strong></summary>

- [Screenshots](#-screenshots)
- [Features](#-features)
- [Plant Growth Stages](#-plant-growth-stages)
- [Install](#-install)
- [How It Works](#-how-it-works)
- [Settings](#%EF%B8%8F-settings)
- [Design System](#-design-system)
- [Architecture](#-architecture)
- [Privacy](#-privacy)
- [Contributing](#-contributing)
- [License](#-license)

</details>

---

## Screenshots

<p align="center">
  <img src="screenshots/light-mode.png" alt="Niwa Light Mode" width="320" />
  &nbsp;&nbsp;
  <img src="screenshots/dark-mode.png" alt="Niwa Dark Mode" width="320" />
</p>

<p align="center">
  <em>Light mode (warm cream) &nbsp;|&nbsp; Dark mode (warm dark brown)</em>
</p>

<p align="center">
  <img src="screenshots/settings.png" alt="Niwa Settings" width="320" />
  &nbsp;&nbsp;
  <img src="screenshots/floating-window.png" alt="Floating Window" width="240" />
</p>

<p align="center">
  <em>Inline settings &nbsp;|&nbsp; Floating mini window</em>
</p>

---

## Features

### Pomodoro Timer
- Full state machine: Work → Short Break → Long Break → Idle
- Configurable durations (1–120 min work, 1–60 min breaks)
- Date-based time tracking (no drift on sleep/wake)
- Session counter ("2 of 4") with auto-progression
- Circular progress ring with SF Mono countdown
- **+25 XP** on work session completion

### Task Management
- Quick-add with Enter to submit
- Tap to complete with strikethrough animation
- Drag-to-reorder with persistent sort order
- Clear completed tasks in one action
- **+15 XP** per task completed

### Quick Notes
- Instant note creation from the dropdown
- Full text editor with word count
- Auto-save on navigation and close
- Sorted by last updated
- **+5 XP** per note created

### Clipboard History
- Automatic monitoring (polls every 0.5s)
- Keeps last 20 entries
- Tap to re-copy with visual feedback
- Relative timestamps ("3m ago")
- Character count for long entries

### Health Reminders
- Water and standing reminders on configurable intervals
- Smart scheduling: respects work hours and lunch breaks
- Actionable notifications with Done / Snooze
- Live standing timer with pulse animation
- **+10 XP** per health action completed

### XP & Leveling
- Earn XP from every productive action
- Level formula: Total XP to reach Level N = 25N² + 75N
- Level-up overlay with confetti animation (respects Reduce Motion)
- 7-day XP chart with daily breakdowns
- Menu bar icon evolves with your level

### Floating Window
- Compact, borderless mini window
- Shows timer + current task
- Draggable, remembers position
- Optional always-on-top mode
- Non-activating — never steals focus

### Dark Mode
- Full light/dark theme support
- Warm cream (#FAF6F1) light / warm brown (#1C1917) dark
- System, Light, or Dark override in settings
- All colors adapt automatically via asset catalog

---

## Plant Growth Stages

Your virtual plant grows as you level up — a visual representation of your productivity journey.

| Stage | Levels | Preview |
|-------|--------|---------|
| **Seed** | 0 | A small seed resting in soil |
| **Sprout** | 1–3 | First green shoot breaks through |
| **Seedling** | 4–7 | Small stem with a few leaves |
| **Young Plant** | 8–12 | Growing taller with branching leaves |
| **Bush** | 13–18 | Full leafy bush |
| **Small Tree** | 19–25 | Trunk forms, canopy develops |
| **Full Tree** | 26–35 | Mature tree with full canopy |
| **Ancient Tree** | 36+ | Majestic tree with deep roots |

<p align="center">
  <img src="screenshots/plant-stages.png" alt="All 8 plant growth stages" width="600" />
</p>

---

## Install

### Build from Source

> **Requirements:** Xcode 16+, macOS 15.0+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
# Clone the repository
git clone https://github.com/saidjamesphilip/Niwa.git
cd Niwa

# Generate Xcode project
xcodegen generate

# Build and run
xcodebuild -scheme NiwaApp -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/Niwa-*/Build/Products/Debug/Niwa.app
```

Or open `Niwa.xcodeproj` in Xcode and press **Cmd+R**.

<details>
<summary><strong>Install XcodeGen (if needed)</strong></summary>

```bash
brew install xcodegen
```

</details>

<details>
<summary><strong>Troubleshooting: "App is damaged" error</strong></summary>

If macOS shows a warning when opening, remove the quarantine flag:

```bash
xattr -cr /path/to/Niwa.app
```

</details>

> [!NOTE]
> Niwa is currently source-only. Homebrew and DMG releases are planned for a future version.

---

## How It Works

Niwa lives in your menu bar as a small leaf icon. Click it to open the dropdown panel.

### Menu Bar Icon Evolution

| Level Range | Icon | Description |
|-------------|------|-------------|
| 0–5 | `leaf.circle` | Starting out |
| 6–15 | `leaf` | Growing |
| 16–30 | `leaf.fill` | Flourishing |
| 31+ | `tree` | Fully grown |

### Dropdown Layout

```
┌─────────────────────────────┐
│  🌱 Plant  │  ⏱ Timer      │  ← Hero section
│  Seed      │  24:38         │
│────────────┴────────────────│
│  ████████████░░░  72% XP    │  ← XP progress bar
│─────────────────────────────│
│  Tasks │ Notes │ Clipboard  │  ← Content tabs
│─────────────────────────────│
│  ☐ Design new landing page  │
│  ☑ Review pull requests     │
│  ☐ Update documentation     │
│─────────────────────────────│
│  💧 3  🧍 12:45 standing    │  ← Health status
│─────────────────────────────│
│  ▁▃▅▇▅▃▁  7-day XP chart   │  ← Activity
│─────────────────────────────│
│  🪟  v1.0.0    🔄  ⚙️  ⏻   │  ← Toolbar
└─────────────────────────────┘
```

### Data Storage

All data is stored locally using **SwiftData** with an App Group container. Nothing is sent to any server.

| Data | Storage |
|------|---------|
| Tasks, notes, clipboard | SwiftData (SQLite) |
| Timer sessions | SwiftData with Date-based tracking |
| XP events | SwiftData with source attribution |
| User preferences | SwiftData (UserProfile model) |
| Window position | UserDefaults |

---

## Settings

Settings are embedded inline in the dropdown — no separate window.

| Section | Options |
|---------|---------|
| **Timer** | Work duration, short break, long break, sessions before long break |
| **Health** | Water interval, standing interval |
| **Work Hours** | Start/end time (reminders only fire within) |
| **Lunch** | Start/end time (reminders paused during) |
| **Appearance** | System / Light / Dark theme |
| **Window** | Always on top toggle |
| **Data** | Export JSON, Reset data, Full restart |

> [!TIP]
> **Full Restart** wipes everything and returns you to Level 0 with a fresh seed. Use **Reset All Data** to clear tasks/notes/XP while keeping your settings.

---

## Design System

Niwa uses a custom warm, earthy design language.

### Color Palette

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | `#FAF6F1` | `#1C1917` | Main panel background |
| `backgroundSecondary` | `#F0EAE0` | `#2C2520` | Cards, sections |
| `primary` | `#E07A5F` | `#E07A5F` | Terracotta — buttons, accents |
| `secondary` | `#81B29A` | `#81B29A` | Sage green — health, success |
| `textPrimary` | `#3D3229` | `#FAF6F1` | Headings, body text |
| `textSecondary` | `#7A6E63` | `#BFB3A5` | Supporting text |
| `textMuted` | `#A89B8C` | `#7A6E63` | Timestamps, hints |
| `danger` | `#C44536` | `#E05545` | Destructive actions |

### Typography

| Style | Spec |
|-------|------|
| Title | System Rounded, 18pt semibold |
| Heading | System Rounded, 15pt medium |
| Body | System, 13pt regular |
| Caption | System, 11pt regular |
| Mono | SF Mono, 12pt regular |
| Timer | SF Mono, 28pt medium |

---

## Architecture

```
Niwa/
├── project.yml                  # XcodeGen project definition
├── NiwaApp/                     # Main app target
│   ├── NiwaApp.swift            # @main entry, MenuBarExtra
│   ├── AppDelegate.swift        # Lifecycle, notification delegate
│   ├── Services/                # Business logic
│   │   ├── TaskManager.swift
│   │   ├── NoteManager.swift
│   │   ├── ClipboardMonitor.swift
│   │   ├── HealthEventManager.swift
│   │   ├── UserProfileManager.swift
│   │   └── NotificationManager.swift
│   ├── Views/                   # SwiftUI views
│   │   ├── DropdownRootView.swift
│   │   ├── Components/
│   │   │   ├── HeroView.swift       # Plant + timer + XP bar
│   │   │   ├── PlantView.swift      # 8 growth stages (pure SwiftUI shapes)
│   │   │   ├── LevelUpOverlay.swift
│   │   │   └── ...
│   │   ├── FloatingWindow/
│   │   │   ├── FloatingWindowController.swift  # NSPanel management
│   │   │   └── FloatingWindowContentView.swift
│   │   └── Settings/
│   │       └── InlineSettingsView.swift
│   └── Assets.xcassets/         # Color sets (light + dark variants)
├── NiwaShared/                  # Shared between app + widget
│   ├── Constants/
│   │   ├── DesignTokens.swift   # Colors, spacing, typography, animation
│   │   └── XPConstants.swift    # XP amounts, level formula, defaults
│   ├── Engines/
│   │   ├── GamificationEngine.swift
│   │   ├── PomodoroTimerEngine.swift
│   │   └── ReminderSchedulingEngine.swift
│   └── Models/                  # SwiftData @Model entities
│       ├── UserProfile.swift
│       ├── NiwaTask.swift
│       ├── NiwaNote.swift
│       ├── ClipboardEntry.swift
│       ├── TimerSession.swift
│       ├── HealthEvent.swift
│       └── XPEvent.swift
└── NiwaWidget/                  # WidgetKit extension
    ├── SmallWidgetView.swift    # Timer + level + plant
    ├── MediumWidgetView.swift   # Timer + tasks + health
    └── LargeWidgetView.swift    # Full dashboard + sparkline
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **MenuBarExtra (.window)** | Native macOS menu bar dropdown, no Dock icon |
| **SwiftData** | Modern persistence with @Query reactivity |
| **Date-based timer** | No drift on sleep/wake — compares against wall clock |
| **Shared ModelContainer** | Single context across all managers prevents stale state |
| **NSPanel floating window** | Non-activating, doesn't steal focus from other apps |
| **XcodeGen** | Reproducible project file, clean diffs |
| **Pure SwiftUI plant shapes** | No image assets needed, scales to any size |

---

## Privacy

| | Detail |
|-|--------|
| **Data storage** | All data stored locally in SwiftData (App Group container) |
| **Network** | Zero network calls. No analytics, no telemetry, no tracking |
| **Clipboard** | Reads `NSPasteboard.general` locally. Text stays on your machine |
| **Notifications** | Local `UNUserNotificationCenter` only. No push servers |

> [!IMPORTANT]
> Niwa never sends your data anywhere. Everything lives on your Mac.

---

## Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-thing`)
3. Commit your changes
4. Push to the branch (`git push origin feature/amazing-thing`)
5. Open a Pull Request

### Build Requirements

- macOS 15.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Niwa (庭)</strong> — Japanese for "garden"
  <br />
  <em>Tend your garden. Grow your focus.</em>
</p>
