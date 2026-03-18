# Calendar Meetings Integration — Design Spec

**Date:** 2026-03-17
**Branch:** `fix/project-health-check`
**Status:** Approved

---

**Minimum deployment target:** macOS 15.0 (Sequoia) — matches existing project requirement.

## Overview

Add a Meetings tab to Niwa that shows today's calendar events via macOS EventKit. Users can review completed meetings (3-point rating + optional notes) to earn XP. Stays local-first — no Google OAuth, no API keys. Uses the system's already-connected calendar accounts.

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Calendar source | macOS EventKit (Apple Calendar) | Local-first, no auth, works with Google/Outlook/iCloud via system sync |
| UI placement | New "Meetings" tab (third tab) | Dedicated space, familiar pattern, doesn't crowd existing views |
| Post-meeting enrichment | Auto-prompt for recent + all past reviewable | Nudges while fresh, but non-blocking |
| XP values | +5 rate, +5 notes (max +10/meeting) | Light — rewards reflection, not attendance |
| Rating scale | 3-point: Bad / OK / Good | Fast, enough signal for reflection |
| Entitlements | Calendar entitlement only (no sandbox) | Minimal change, avoids breaking existing features |
| Scope | Today's meetings only (7am boundary) | Matches existing daily habit reset pattern |

---

## Architecture

### Data Flow

```
EventKit (macOS Calendar.app synced accounts)
    ↓
CalendarManager (@MainActor @Observable service)
    ↓  Fetches today's events on launch + every 5 min
    ↓  Tracks pending review (most recent ended, unreviewed)
    ↓
MeetingReview (@Model — SwiftData)
    ↓  Persists rating + notes per event
    ↓
MeetingsListView (new tab)
    ↓
GamificationEngine (awards XP via .meeting source)
```

### CalendarManager Service

**File:** `NiwaApp/Services/CalendarManager.swift`

Pattern: `@MainActor @Observable final class` (matches all other services)

**Responsibilities:**
- Request calendar permission via `EKEventStore.requestFullAccessToEvents()`
- Fetch today's events using `EKEventStore.events(matching:)` filtered from 7am today to 7am tomorrow (matching `HealthEventManager.habitDayStart()` boundary)
- Refresh every 5 minutes via `Timer`
- Listen for `EKEventStoreChanged` notification to refresh on external changes
- Expose observable properties:
  - `todayEvents: [EKEvent]` — all events today, sorted by start time
  - `authorizationStatus: EKAuthorizationStatus`
  - `pendingReview: EKEvent?` — most recent ended meeting (within last 30 min) not yet reviewed
- Categorize events into: upcoming, current (happening now), past

**Dependencies:** `ModelContext` (to check which events have reviews), `GamificationEngine` (to award XP — matches pattern used by HealthEventManager, TaskManager, NoteManager)

**Lifecycle:** A single `EKEventStore` instance is created at `CalendarManager.init()` and retained for the app's lifetime. This is required to keep receiving `EKEventStoreChanged` notifications.

**Event freshness:** Always fetch `EKEvent` instances fresh via `EKEventStore.events(matching:)` per refresh cycle. Do not persist or cache `EKEvent` object references between refreshes — they can become stale, especially for recurring event occurrences.

**Does NOT persist calendar events** — they live in EventKit. Only reviews are stored.

### MeetingReview Model

**File:** `NiwaShared/Models/MeetingReview.swift`

```swift
@Model
final class MeetingReview {
    var eventIdentifier: String   // EKEvent.eventIdentifier — unique per occurrence
    var rating: Int               // 0 = bad, 1 = ok, 2 = good
    var notes: String             // Optional notes (empty string if skipped)
    var ratingXPAwarded: Bool     // Guard against double-awarding rating XP
    var notesXPAwarded: Bool      // Guard against double-awarding notes XP
    var reviewedAt: Date
    var eventTitle: String        // Snapshot of title at review time
}
```

Linked to `EKEvent` via `eventIdentifier` (unique per occurrence for recurring events). Title is snapshotted because EventKit events can change after the fact.

**XP de-duplication:** Rating is immutable once set — the UI disables rating buttons after selection. Notes XP is awarded once on first save. Both guarded by `ratingXPAwarded` / `notesXPAwarded` flags to prevent double-awarding even if the UI fails to enforce it.

### XP Integration

**New source case:** `XPEvent.Source.meeting`

**Constants (XPConstants.swift):**
- `meetingRate = 5` — XP for submitting a rating
- `meetingNotes = 5` — XP for adding non-empty notes
- Max +10 XP per meeting

**Chart color:** Amber (#E0AC3A) — distinct from existing sources, matches the "OK" rating color.

---

## UI Design

### Meetings Tab

**Location:** Third tab in `ContentTabView` — **Tasks | Notes | Meetings**

Shows today's events grouped into three sections:

#### Upcoming Meetings
- Left color bar: sage (#81B29A)
- Title, start time, duration
- "soon" badge (terracotta) if starting within 15 minutes

#### Current Meeting
- Left color bar: terracotta (#E07A5F), pulsing subtly
- Title, "Now · ends at X:XX"
- Slightly elevated background

#### Past Meetings
- Left color bar: muted (#A89B8C)
- Not reviewed: "Review" button in terracotta text
- Reviewed: dimmed row with rating icon + checkmark

### Auto-Prompt Banner

When the dropdown opens and there's a meeting that ended within the last 30 minutes and hasn't been reviewed:

- Subtle banner at top of Meetings tab
- "[Meeting name] just ended — how was it?"
- 3-point rating buttons inline
- Dismisses after review or tap to dismiss

### Review Flow

1. **Rating** — Three icon buttons:
   - 😕 Bad — muted color
   - 😐 OK — amber
   - 😊 Good — sage
   - Tap to select → **+5 XP** awarded immediately

2. **Notes** (optional) — Text field: "Quick notes..."
   - Single-line default, expands to 3 lines on focus
   - "Done" button saves → **+5 XP** if non-empty

3. **Persistence** — `MeetingReview` saved, meeting row updates to show rating icon

### Empty States

- **No calendar access:** PlantView seed icon + "Connect your calendar in System Settings" with deep link
- **No meetings today:** PlantView seed icon + "No meetings today — focus time!"
- **Calendar access pending:** "Tap to enable calendar access" button that triggers the permission request

---

## Permission Flow

1. User taps Meetings tab for the first time
2. `CalendarManager` calls `EKEventStore.requestFullAccessToEvents()`
3. macOS shows system permission dialog
4. If granted → meetings load immediately
5. If denied → empty state with "Enable in System Settings" link (`NSWorkspace.shared.open` to Privacy & Security → Calendars)
6. `CalendarManager` observes `EKEventStoreChanged` to refresh when access changes

---

## Entitlements & Config Changes

**NiwaApp.entitlements:**
```xml
<key>com.apple.security.personal-information.calendars</key>
<true/>
```

**Info.plist:**
```xml
<key>NSCalendarsUsageDescription</key>
<string>Niwa shows your upcoming meetings and lets you earn XP by reviewing them.</string>
```

**project.yml:** Add `EventKit` framework to NiwaApp target.

**Widget:** No changes — widget does not access calendar.

---

## File Changes

### New Files (4)

| File | Purpose |
|------|---------|
| `NiwaApp/Services/CalendarManager.swift` | EventKit service |
| `NiwaShared/Models/MeetingReview.swift` | SwiftData model for reviews |
| `NiwaApp/Views/MeetingsListView.swift` | Meetings tab view |
| `NiwaApp/Views/Components/MeetingReviewCard.swift` | Reusable review UI (rating + notes) |

### Modified Files (9)

| File | Change |
|------|--------|
| `project.yml` | Add EventKit framework |
| `NiwaApp/NiwaApp.entitlements` | Add calendar entitlement |
| `NiwaApp/Info.plist` | Add NSCalendarsUsageDescription |
| `NiwaApp/NiwaApp.swift` | Instantiate CalendarManager, pass to DropdownRootView |
| `NiwaApp/Views/DropdownRootView.swift` | Accept and pass CalendarManager to ContentTabView |
| `NiwaApp/Views/ContentTabView.swift` | Add Meetings tab |
| `NiwaShared/Models/ModelContainerSetup.swift` | Register MeetingReview in schema |
| `NiwaShared/Models/XPEvent.swift` | Add `.meeting` source case |
| `NiwaShared/Constants/XPConstants.swift` | Add meeting XP constants |

### Not Changed

- NiwaWidget (no calendar access)
- Existing services and models
- GamificationEngine (already handles any XPEvent source generically)

---

## Out of Scope

- Google OAuth / direct API integration
- Multi-day calendar view
- Meeting creation or editing
- Calendar selection/filtering (shows all calendars)
- Widget calendar display
- Recurring meeting detection
- Meeting attendee display
