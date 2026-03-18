# Weekly Insights Toggle — Design Spec

**Date:** 2026-03-18
**Branch:** `feat/health-check-and-meetings`
**Status:** Approved

---

## Overview

Add a toggle button to the XP chart header that swaps the 7-day bar chart for a qualitative weekly insights view. Shows 4 stat pills, a headline, and a brief summary — all computed from existing data. No new persistence, no new files.

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Trigger | 💡 button on chart header | Discoverable, compact, no layout changes |
| Display mode | Replace chart (toggle) | Same space, no layout shift, clean swap |
| Stat pills | Tasks, Focus time, Meetings, Waters (fixed 4) | Covers main feature areas, predictable layout |
| Summary tone | Brief + emoji | Matches Niwa's compact, warm personality |
| Data source | Existing XPEvent + MeetingReview + HealthEvent | No new persistence needed |

---

## UI Design

### Chart Header (default state)

```
XP — Last 7 Days                    💡
[bar chart bars...]
```

### Insights View (toggled state)

```
Weekly Insights                      📊
┌─────────────────────────────────────┐
│  Strong week so far                 │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐│
│  │  12  │ │ 3:45 │ │  4   │ │ 18 ││
│  │tasks │ │focus │ │meets │ │water││
│  └──────┘ └──────┘ └──────┘ └────┘│
│                                     │
│  Productive week 📈 — focus up,     │
│  habits consistent                  │
└─────────────────────────────────────┘
```

### Toggle Behaviour

- Default: chart view with 💡 button
- Tap 💡: swaps to insights view, header becomes "Weekly Insights", button becomes 📊
- Tap 📊: swaps back to chart view
- State resets on dropdown close (always opens to chart)

### Stat Pills

4 horizontal pills with equal width:

| Pill | Value | Color | Source |
|------|-------|-------|--------|
| Tasks | Count of tasks completed this week | Terracotta (#E07A5F) | XPEvent where source == .task |
| Focus | Total focus minutes formatted as h:mm | Sage (#81B29A) | XPEvent where source == .timer, sum amounts (= minutes) |
| Meetings | Count of meetings reviewed | Amber (#E0AC3A) | MeetingReview count for this week |
| Waters | Count of waters logged | Sage (#81B29A) | XPEvent where source == .water |

Pill design: `backgroundSecondary` background, rounded corners, large bold number on top, small muted label below, centered.

### Headline Logic

Based on total XP this week vs total XP the prior week:

| Condition | Headline |
|-----------|----------|
| No XP this week | "Your week starts now" |
| Prior week had no XP (no comparison) | "Looking good so far" |
| XP up >20% | "Crushing it this week" |
| XP up 1–20% | "Strong week so far" |
| XP roughly flat (±1%) | "Steady progress" |
| XP down 1–20% | "Slow start — you've got this" |
| XP down >20% | "Quiet week — time to grow" |

### Summary Line

Brief sentence with emoji, generated from the stat values:

- Template: `"[trend emoji] — [highest activity], [second observation]"`
- Examples:
  - "Productive week 📈 — focus time up, habits consistent"
  - "Good momentum 💪 — 12 tasks done, 4 meetings reviewed"
  - "Quiet start 🌱 — time to plant some seeds"

Logic: pick the most notable stat (highest count or biggest week-over-week change) and pair with a secondary observation. Keep to one line.

---

## Architecture

### No new files needed

All logic lives in `XPChartView.swift`:

1. **`WeeklyInsights` struct** (private) — computed data model:
   - `tasksCompleted: Int`
   - `focusMinutes: Int`
   - `meetingsReviewed: Int`
   - `watersLogged: Int`
   - `totalXP: Int`
   - `priorWeekXP: Int`
   - `headline: String`
   - `summary: String`

2. **`insightsView`** (private computed property) — SwiftUI view rendering the pills + text

3. **`@State private var showInsights: Bool = false`** — toggle state, reset via `.onAppear { showInsights = false }` so it always opens to chart view when the dropdown appears

### Data Computation

All data comes from the `xpEvents: [XPEvent]` array already passed to `XPChartView`. This array contains the last 8 days of events (fetched by `GamificationEngine.refreshRecentXPEvents()`).

- **This week**: filter events from last 7 days (same range as chart)
- **Prior week**: filter events from day 8–14 ago — requires expanding the fetch window in `GamificationEngine` from 8 to 15 days
- **Meeting reviews**: count `MeetingReview` records where `reviewedAt` falls within the last 7 days — computed by `CalendarManager.meetingsReviewedThisWeek` using the existing `reviewedAt: Date` field on the model
- **Focus minutes**: since `XPConstants.focusXPPerMinute == 1`, the XP `amount` for `.timer` events equals the duration in minutes. Sum directly.

### Modified Files

| File | Change |
|------|--------|
| `NiwaApp/Views/Components/XPChartView.swift` | Add toggle state, insights model, insights view, header button |
| `NiwaShared/Engines/GamificationEngine.swift` | Expand `refreshRecentXPEvents()` fetch window from 8 to 15 days |
| `NiwaApp/Services/CalendarManager.swift` | Add `meetingsReviewedThisWeek` computed property |
| `NiwaApp/Views/DropdownRootView.swift` | Pass `meetingsReviewedThisWeek` to `XPChartView` |

---

## Out of Scope

- Persisting insights or generating history
- AI-generated summaries
- Sharing or exporting insights
- Per-day breakdown (that's what the chart already does)
- Insights notifications
