# Calendar Meetings Integration — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Meetings tab showing today's calendar events via EventKit, with post-meeting reviews that earn XP.

**Architecture:** New `CalendarManager` service fetches events from macOS EventKit. `MeetingReview` SwiftData model persists reviews. `MeetingsListView` renders the tab with upcoming/current/past sections. `MeetingReviewCard` handles the rating + notes flow. XP awarded via existing `GamificationEngine`.

**Tech Stack:** SwiftUI, SwiftData, EventKit, XcodeGen

**Spec:** `docs/superpowers/specs/2026-03-17-calendar-meetings-design.md`

---

## Chunk 1: Foundation — Model, Constants, Config

### Task 1: Add MeetingReview SwiftData model

**Files:**
- Create: `NiwaShared/Models/MeetingReview.swift`
- Modify: `NiwaShared/Models/ModelContainerSetup.swift`

- [ ] **Step 1: Create MeetingReview model**

```swift
// NiwaShared/Models/MeetingReview.swift
import Foundation
import SwiftData

@Model
final class MeetingReview {
    var id: UUID
    @Attribute(.unique) var eventIdentifier: String
    var rating: Int
    var notes: String
    var ratingXPAwarded: Bool
    var notesXPAwarded: Bool
    var reviewedAt: Date
    var eventTitle: String

    init(eventIdentifier: String, rating: Int, eventTitle: String) {
        self.id = UUID()
        self.eventIdentifier = eventIdentifier
        self.rating = rating
        self.notes = ""
        self.ratingXPAwarded = false
        self.notesXPAwarded = false
        self.reviewedAt = Date()
        self.eventTitle = eventTitle
    }
}
```

- [ ] **Step 2: Register MeetingReview in ModelContainerSetup**

In `NiwaShared/Models/ModelContainerSetup.swift`, add `MeetingReview.self` to `allModelTypes`:

```swift
static let allModelTypes: [any PersistentModel.Type] = [
    NiwaTask.self,
    NiwaNote.self,
    TimerSession.self,
    HealthEvent.self,
    XPEvent.self,
    UserProfile.self,
    MeetingReview.self,
]
```

- [ ] **Step 3: Build to verify model compiles**

Run: `cd /Users/james/Claude\ Projects/Niwa/Niwa && xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add NiwaShared/Models/MeetingReview.swift NiwaShared/Models/ModelContainerSetup.swift
git commit -m "feat(meetings): add MeetingReview SwiftData model"
```

---

### Task 2: Add XP constants and source enum

**Files:**
- Modify: `NiwaShared/Models/XPEvent.swift`
- Modify: `NiwaShared/Constants/XPConstants.swift`
- Modify: `NiwaApp/Views/Components/XPChartView.swift`

- [ ] **Step 1: Add `.meeting` case to XPSource**

In `NiwaShared/Models/XPEvent.swift`, add `.meeting` case to the existing `XPSource` enum (do NOT replace the file — only modify the enum):

```swift
// Add this case after `case coffee`:
    case meeting
// ... rest of XPEvent.swift (@Model class, init, etc.) stays unchanged
```

- [ ] **Step 2: Add meeting XP constants**

In `NiwaShared/Constants/XPConstants.swift`, add after `coffeeMaxBeforePenalty`:

```swift
    // Meeting review XP
    static let meetingRate: Int = 5
    static let meetingNotes: Int = 5
```

- [ ] **Step 3: Add meeting segment to XP chart**

In `NiwaApp/Views/Components/XPChartView.swift`:

Update `DayXP` struct to add `meeting` field:

```swift
private struct DayXP {
    let day: String
    let task: Int
    let timer: Int
    let note: Int
    let water: Int
    let coffee: Int
    let stand: Int
    let creatine: Int
    let gym: Int
    let meeting: Int

    var total: Int { task + timer + note + water + coffee + stand + creatine + gym + meeting }
}
```

Update `computeChartData()` to include meeting in the `DayXP` constructor:

```swift
return DayXP(
    day: label,
    task: dayEvents.filter { $0.source == .task }.reduce(0) { $0 + $1.amount },
    timer: dayEvents.filter { $0.source == .timer }.reduce(0) { $0 + $1.amount },
    note: dayEvents.filter { $0.source == .note }.reduce(0) { $0 + $1.amount },
    water: dayEvents.filter { $0.source == .water }.reduce(0) { $0 + $1.amount },
    coffee: dayEvents.filter { $0.source == .coffee }.reduce(0) { $0 + $1.amount },
    stand: dayEvents.filter { $0.source == .stand }.reduce(0) { $0 + $1.amount },
    creatine: dayEvents.filter { $0.source == .creatine }.reduce(0) { $0 + $1.amount },
    gym: dayEvents.filter { $0.source == .gym }.reduce(0) { $0 + $1.amount },
    meeting: dayEvents.filter { $0.source == .meeting }.reduce(0) { $0 + $1.amount }
)
```

Add the meeting bar segment in the stacked bar body, between gym and creatine:

```swift
barSegment(value: day.gym, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary)
barSegment(value: day.meeting, maxTotal: chartData.maxTotal, color: Color(red: 224/255, green: 172/255, blue: 58/255).opacity(0.7))
barSegment(value: day.creatine, maxTotal: chartData.maxTotal, color: Color(red: 224/255, green: 172/255, blue: 58/255))
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add NiwaShared/Models/XPEvent.swift NiwaShared/Constants/XPConstants.swift NiwaApp/Views/Components/XPChartView.swift
git commit -m "feat(meetings): add .meeting XP source, constants, and chart segment"
```

---

### Task 3: Update project config — entitlements, Info.plist, project.yml

**Files:**
- Modify: `NiwaApp/NiwaApp.entitlements`
- Modify: `NiwaApp/Info.plist`
- Modify: `project.yml`

- [ ] **Step 1: Add calendar entitlement**

Replace `NiwaApp/NiwaApp.entitlements` contents with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.personal-information.calendars</key>
	<true/>
</dict>
</plist>
```

- [ ] **Step 2: Add calendar usage description to Info.plist**

Replace `NiwaApp/Info.plist` contents with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>LSUIElement</key>
	<true/>
	<key>NSCalendarsUsageDescription</key>
	<string>Niwa shows your upcoming meetings and lets you earn XP by reviewing them.</string>
</dict>
</plist>
```

- [ ] **Step 3: Add EventKit framework to project.yml**

In `project.yml`, add `frameworks` section to the `NiwaApp` target (after `dependencies`):

```yaml
    dependencies:
      - target: NiwaWidget
      - sdk: EventKit.framework
```

- [ ] **Step 4: Regenerate and build**

Run: `xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add NiwaApp/NiwaApp.entitlements NiwaApp/Info.plist project.yml
git commit -m "feat(meetings): add calendar entitlement, usage description, EventKit framework"
```

---

## Chunk 2: CalendarManager Service

### Task 4: Create CalendarManager

**Files:**
- Create: `NiwaApp/Services/CalendarManager.swift`

- [ ] **Step 1: Create CalendarManager service**

```swift
// NiwaApp/Services/CalendarManager.swift
import Foundation
import EventKit
import SwiftData
import Observation

@MainActor
@Observable
final class CalendarManager {
    private let eventStore = EKEventStore()
    private let modelContext: ModelContext
    private let gamificationEngine: GamificationEngine
    private var refreshTimer: Timer?

    private(set) var todayEvents: [EKEvent] = []
    private(set) var isAuthorized: Bool = false
    private(set) var authorizationDenied: Bool = false
    private(set) var pendingReview: EKEvent?

    init(modelContext: ModelContext, gamificationEngine: GamificationEngine) {
        self.modelContext = modelContext
        self.gamificationEngine = gamificationEngine

        checkAuthorization()
        startRefreshTimer()
        observeCalendarChanges()
    }

    // MARK: - Authorization

    func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthorized = granted
                self.authorizationDenied = !granted
                if granted {
                    self.refreshEvents()
                }
            }
        }
    }

    private func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            isAuthorized = true
            refreshEvents()
        case .denied, .restricted:
            authorizationDenied = true
        case .notDetermined:
            break // Will request on first tab visit
        case .writeOnly:
            authorizationDenied = true
        @unknown default:
            break
        }
    }

    // MARK: - Event Fetching

    func refreshEvents() {
        guard isAuthorized else { return }

        let dayStart = XPConstants.habitDayStart()
        let calendar = Calendar.current
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let predicate = eventStore.predicateForEvents(
            withStart: dayStart,
            end: dayEnd,
            calendars: nil
        )

        todayEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        updatePendingReview()
    }

    // MARK: - Event Categorization

    var upcomingEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.startDate > now }
    }

    var currentEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.startDate <= now && $0.endDate > now }
    }

    var pastEvents: [EKEvent] {
        let now = Date()
        return todayEvents.filter { $0.endDate <= now }
    }

    // MARK: - Meeting Reviews

    func review(for eventIdentifier: String) -> MeetingReview? {
        let descriptor = FetchDescriptor<MeetingReview>(
            predicate: #Predicate { $0.eventIdentifier == eventIdentifier }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func hasReview(for eventIdentifier: String) -> Bool {
        review(for: eventIdentifier) != nil
    }

    func submitRating(for event: EKEvent, rating: Int) {
        let identifier = event.eventIdentifier ?? ""
        guard !identifier.isEmpty else { return }

        if let existing = review(for: identifier) {
            // Already reviewed — don't re-rate
            guard !existing.ratingXPAwarded else { return }
            existing.ratingXPAwarded = true
            try? modelContext.save()
        } else {
            let meetingReview = MeetingReview(
                eventIdentifier: identifier,
                rating: rating,
                eventTitle: event.title ?? "Untitled"
            )
            meetingReview.ratingXPAwarded = true
            modelContext.insert(meetingReview)
            try? modelContext.save()
        }

        gamificationEngine.awardXP(source: .meeting, amount: XPConstants.meetingRate, context: modelContext)
        updatePendingReview()
    }

    func submitNotes(for eventIdentifier: String, notes: String) {
        guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let existing = review(for: eventIdentifier) else { return }
        guard !existing.notesXPAwarded else { return }

        existing.notes = notes
        existing.notesXPAwarded = true
        try? modelContext.save()

        gamificationEngine.awardXP(source: .meeting, amount: XPConstants.meetingNotes, context: modelContext)
    }

    // MARK: - Pending Review

    private func updatePendingReview() {
        let now = Date()
        let thirtyMinAgo = now.addingTimeInterval(-30 * 60)

        pendingReview = pastEvents
            .filter { event in
                guard let endDate = event.endDate, endDate >= thirtyMinAgo else { return false }
                let identifier = event.eventIdentifier ?? ""
                return !identifier.isEmpty && !hasReview(for: identifier)
            }
            .last // Most recently ended
    }

    // MARK: - Refresh Timer

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
    }

    private func observeCalendarChanges() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
    }
}
```

- [ ] **Step 2: Regenerate and build**

Run: `xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Services/CalendarManager.swift
git commit -m "feat(meetings): add CalendarManager EventKit service"
```

---

## Chunk 3: UI — Views and Wiring

### Task 5: Create MeetingReviewCard component

**Files:**
- Create: `NiwaApp/Views/Components/MeetingReviewCard.swift`

- [ ] **Step 1: Create reusable review card**

```swift
// NiwaApp/Views/Components/MeetingReviewCard.swift
import SwiftUI

struct MeetingReviewCard: View {
    let eventTitle: String
    let onRate: (Int) -> Void
    let onSubmitNotes: (String) -> Void

    @State private var selectedRating: Int? = nil
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var notesSubmitted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("\(eventTitle) just ended — how was it?")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            // Rating buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                ratingButton(rating: 0, icon: "😕", label: "Bad", color: DesignTokens.Colors.textMuted)
                ratingButton(rating: 1, icon: "😐", label: "OK", color: Color(red: 224/255, green: 172/255, blue: 58/255))
                ratingButton(rating: 2, icon: "😊", label: "Good", color: DesignTokens.Colors.secondary)
            }

            // Notes field (shown after rating)
            if showNotes && !notesSubmitted {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Quick notes...", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.plain)
                        .font(DesignTokens.Typography.captionFont)
                        .padding(DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))

                    Button("Done") {
                        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSubmitNotes(trimmed)
                            notesSubmitted = true
                        }
                    }
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .buttonStyle(.plain)
                }
            }

            if notesSubmitted {
                Text("Notes saved +5 XP")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }

    private func ratingButton(rating: Int, icon: String, label: String, color: Color) -> some View {
        Button {
            guard selectedRating == nil else { return }
            selectedRating = rating
            showNotes = true
            onRate(rating)
        } label: {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(selectedRating == rating ? color : DesignTokens.Colors.textMuted)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                selectedRating == rating
                    ? color.opacity(0.15)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            .opacity(selectedRating != nil && selectedRating != rating ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(selectedRating != nil)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Views/Components/MeetingReviewCard.swift
git commit -m "feat(meetings): add MeetingReviewCard component"
```

---

### Task 6: Create MeetingsListView

**Files:**
- Create: `NiwaApp/Views/MeetingsListView.swift`

- [ ] **Step 1: Create meetings list view**

```swift
// NiwaApp/Views/MeetingsListView.swift
import SwiftUI
import EventKit

struct MeetingsListView: View {
    let calendarManager: CalendarManager
    let contentMaxHeight: CGFloat

    @State private var expandedReviewId: String?
    @State private var dismissedPendingId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !calendarManager.isAuthorized {
                    emptyStateNoAccess
                } else if calendarManager.todayEvents.isEmpty {
                    emptyStateNoMeetings
                } else {
                    meetingsList
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .frame(maxHeight: contentMaxHeight)
        .onAppear {
            if !calendarManager.isAuthorized && !calendarManager.authorizationDenied {
                calendarManager.requestAccess()
            }
        }
    }

    // MARK: - Meetings List

    @ViewBuilder
    private var meetingsList: some View {
        // Auto-prompt banner
        if let pending = calendarManager.pendingReview,
           let pendingId = pending.eventIdentifier,
           dismissedPendingId != pendingId,
           !calendarManager.hasReview(for: pendingId) {
            MeetingReviewCard(
                eventTitle: pending.title ?? "Meeting",
                onRate: { rating in
                    calendarManager.submitRating(for: pending, rating: rating)
                },
                onSubmitNotes: { notes in
                    calendarManager.submitNotes(for: pendingId, notes: notes)
                }
            )
            .padding(.bottom, DesignTokens.Spacing.sm)

            Button {
                dismissedPendingId = pendingId
            } label: {
                Text("Dismiss")
                    .font(.system(size: 9))
                    .foregroundStyle(DesignTokens.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.bottom, DesignTokens.Spacing.sm)
        }

        // Current meetings
        let current = calendarManager.currentEvents
        if !current.isEmpty {
            sectionHeader("Now")
            ForEach(current, id: \.eventIdentifier) { event in
                meetingRow(event: event, state: .current)
            }
        }

        // Upcoming meetings
        let upcoming = calendarManager.upcomingEvents
        if !upcoming.isEmpty {
            sectionHeader("Upcoming")
            ForEach(upcoming, id: \.eventIdentifier) { event in
                meetingRow(event: event, state: .upcoming)
            }
        }

        // Past meetings
        let past = calendarManager.pastEvents
        if !past.isEmpty {
            sectionHeader("Earlier")
            ForEach(past, id: \.eventIdentifier) { event in
                let identifier = event.eventIdentifier ?? ""
                let reviewed = calendarManager.hasReview(for: identifier)

                VStack(spacing: 0) {
                    meetingRow(event: event, state: reviewed ? .reviewed : .pastUnreviewed)

                    // Inline review when expanded
                    if expandedReviewId == identifier && !reviewed {
                        MeetingReviewCard(
                            eventTitle: event.title ?? "Meeting",
                            onRate: { rating in
                                calendarManager.submitRating(for: event, rating: rating)
                            },
                            onSubmitNotes: { notes in
                                calendarManager.submitNotes(for: identifier, notes: notes)
                            }
                        )
                        .padding(.top, DesignTokens.Spacing.xs)
                    }
                }
            }
        }
    }

    // MARK: - Meeting Row

    private enum MeetingState {
        case upcoming, current, pastUnreviewed, reviewed
    }

    private func meetingRow(event: EKEvent, state: MeetingState) -> some View {
        let barColor: Color = switch state {
        case .upcoming: DesignTokens.Colors.secondary
        case .current: DesignTokens.Colors.primary
        case .pastUnreviewed: DesignTokens.Colors.textMuted
        case .reviewed: DesignTokens.Colors.textMuted
        }

        return HStack(spacing: DesignTokens.Spacing.sm) {
            // Left color bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(barColor)
                .frame(width: 3, height: 28)

            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(DesignTokens.Typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        state == .reviewed
                            ? DesignTokens.Colors.textMuted
                            : DesignTokens.Colors.textPrimary
                    )

                Text(timeLabel(for: event, state: state))
                    .font(.system(size: 10))
                    .foregroundStyle(
                        state == .current
                            ? DesignTokens.Colors.secondary
                            : DesignTokens.Colors.textMuted
                    )
            }

            Spacer()

            // Badges and actions
            switch state {
            case .upcoming:
                if isSoon(event) {
                    Text("soon")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(DesignTokens.Colors.primary)
                        .clipShape(Capsule())
                }
            case .current:
                Circle()
                    .fill(DesignTokens.Colors.primary)
                    .frame(width: 6, height: 6)
            case .pastUnreviewed:
                Button {
                    let identifier = event.eventIdentifier ?? ""
                    expandedReviewId = expandedReviewId == identifier ? nil : identifier
                } label: {
                    Text("Review")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
                .buttonStyle(.plain)
            case .reviewed:
                if let identifier = event.eventIdentifier,
                   let rev = calendarManager.review(for: identifier) {
                    Text(ratingIcon(rev.rating))
                        .font(.system(size: 12))
                        .opacity(0.6)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(
            state == .current
                ? DesignTokens.Colors.backgroundSecondary
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xs)
    }

    private func timeLabel(for event: EKEvent, state: MeetingState) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        switch state {
        case .current:
            let end = formatter.string(from: event.endDate)
            return "Now · ends at \(end)"
        case .upcoming:
            let start = formatter.string(from: event.startDate)
            let duration = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
            return "\(start) · \(duration) min"
        case .pastUnreviewed, .reviewed:
            let start = formatter.string(from: event.startDate)
            let end = formatter.string(from: event.endDate)
            return "\(start) – \(end)"
        }
    }

    private func isSoon(_ event: EKEvent) -> Bool {
        let now = Date()
        let diff = event.startDate.timeIntervalSince(now)
        return diff > 0 && diff <= 15 * 60 // Within 15 minutes
    }

    private func ratingIcon(_ rating: Int) -> String {
        switch rating {
        case 0: return "😕"
        case 1: return "😐"
        case 2: return "😊"
        default: return "😐"
        }
    }

    // MARK: - Empty States

    private var emptyStateNoAccess: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)

            if calendarManager.authorizationDenied {
                Text("Connect your calendar in System Settings")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                    .multilineTextAlignment(.center)

                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.primary)
                .buttonStyle(.plain)
            } else {
                Button("Tap to enable calendar access") {
                    calendarManager.requestAccess()
                }
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.primary)
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
    }

    private var emptyStateNoMeetings: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()
            PlantView(level: 0)
                .scaleEffect(0.45)
                .frame(width: 40, height: 40)
                .opacity(0.6)
            Text("No meetings today — focus time!")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Views/MeetingsListView.swift
git commit -m "feat(meetings): add MeetingsListView with sections and review flow"
```

---

### Task 7: Wire everything together — ContentTabView, DropdownRootView, NiwaApp

**Files:**
- Modify: `NiwaApp/Views/ContentTabView.swift`
- Modify: `NiwaApp/Views/DropdownRootView.swift`
- Modify: `NiwaApp/NiwaApp.swift`

- [ ] **Step 1: Add Meetings tab to ContentTabView**

Replace entire `NiwaApp/Views/ContentTabView.swift` with:

```swift
import SwiftUI

enum ContentTab: String, CaseIterable {
    case tasks = "Tasks"
    case notes = "Notes"
    case meetings = "Meetings"
}

struct ContentTabView: View {
    let taskManager: TaskManager
    let noteManager: NoteManager
    let calendarManager: CalendarManager

    var contentMaxHeight: CGFloat = 600

    @State private var selectedTab: ContentTab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control
            HStack(spacing: 0) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? DesignTokens.Colors.primary
                                    : DesignTokens.Colors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .background(
                                selectedTab == tab
                                    ? DesignTokens.Colors.backgroundSecondary
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.xs)

            Divider()
                .background(DesignTokens.Colors.subtle)

            // Tab content
            switch selectedTab {
            case .tasks:
                TaskListView(taskManager: taskManager, contentMaxHeight: contentMaxHeight)
            case .notes:
                NotesListView(noteManager: noteManager, contentMaxHeight: contentMaxHeight)
            case .meetings:
                MeetingsListView(calendarManager: calendarManager, contentMaxHeight: contentMaxHeight)
            }
        }
    }
}
```

- [ ] **Step 2: Add calendarManager to DropdownRootView**

In `NiwaApp/Views/DropdownRootView.swift`, add after `let noteManager: NoteManager`:

```swift
    let calendarManager: CalendarManager
```

Find where `ContentTabView` is instantiated in DropdownRootView and add `calendarManager`:

```swift
ContentTabView(
    taskManager: taskManager,
    noteManager: noteManager,
    calendarManager: calendarManager,
    contentMaxHeight: contentMaxHeight
)
```

- [ ] **Step 3: Add CalendarManager to NiwaApp**

In `NiwaApp/NiwaApp.swift`, add property after `let soundManager: SoundManager`:

```swift
    let calendarManager: CalendarManager
```

In `init()`, after `soundManager = SoundManager(modelContext: context)`, add:

```swift
        calendarManager = CalendarManager(modelContext: context, gamificationEngine: engine)
```

Update the `DropdownRootView` initializer in `body` to include `calendarManager`:

```swift
DropdownRootView(
    appErrorState: appErrorState,
    gamificationEngine: gamificationEngine,
    timerEngine: timerEngine,
    healthManager: healthManager,
    profileManager: profileManager,
    soundManager: soundManager,
    taskManager: taskManager,
    noteManager: noteManager,
    calendarManager: calendarManager
)
```

- [ ] **Step 4: Regenerate, build, and run tests**

Run:
```bash
xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"
```

Expected: BUILD SUCCEEDED

Then run tests:
```bash
xcodebuild -scheme NiwaApp -destination 'platform=macOS' test CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "Executed|failed|BUILD"
```

Expected: 49 tests, 0 failures. BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add NiwaApp/Views/ContentTabView.swift NiwaApp/Views/DropdownRootView.swift NiwaApp/NiwaApp.swift
git commit -m "feat(meetings): wire CalendarManager through app, add Meetings tab"
```

---

## Chunk 4: Finalize

### Task 8: Update UserProfileManager.resetAllData for MeetingReview

**Files:**
- Modify: `NiwaApp/Services/UserProfileManager.swift`

- [ ] **Step 1: Add MeetingReview deletion to resetAllData**

In `UserProfileManager.swift`, inside the `resetAllData()` method, add after `try modelContext.delete(model: XPEvent.self)`:

```swift
            try modelContext.delete(model: MeetingReview.self)
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Services/UserProfileManager.swift
git commit -m "feat(meetings): include MeetingReview in resetAllData"
```

---

### Task 9: Run full test suite and verify

- [ ] **Step 1: Run all tests**

```bash
cd /Users/james/Claude\ Projects/Niwa/Niwa && xcodebuild -scheme NiwaApp -destination 'platform=macOS' test CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "Executed|failed|BUILD"
```

Expected: 49 tests, 0 failures. BUILD SUCCEEDED.

- [ ] **Step 2: Verify the app launches**

```bash
xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO && open /Users/james/Library/Developer/Xcode/DerivedData/Niwa-*/Build/Products/Debug/Niwa.app
```

Manual check: Open the app, verify the Meetings tab appears, click it, confirm the permission dialog or empty state displays correctly.

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A && git commit -m "fix(meetings): address any build or test issues"
```
