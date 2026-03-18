# Weekly Insights Toggle — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a toggle button on the XP chart that swaps bars for a qualitative weekly insights view with stat pills and summary.

**Architecture:** All UI and logic in `XPChartView.swift`. Expand GamificationEngine fetch window to 15 days for prior-week comparison. Add `meetingsReviewedThisWeek` to CalendarManager. Pass through DropdownRootView.

**Tech Stack:** SwiftUI, SwiftData

**Spec:** `docs/superpowers/specs/2026-03-18-weekly-insights-design.md`

---

## Chunk 1: Data Layer

### Task 1: Expand GamificationEngine fetch window

**Files:**
- Modify: `NiwaShared/Engines/GamificationEngine.swift:21-28`

- [ ] **Step 1: Change fetch window from 8 to 15 days**

In `GamificationEngine.swift`, in `refreshRecentXPEvents()`, change:

```swift
let eightDaysAgo = calendar.date(byAdding: .day, value: -8, to: calendar.startOfDay(for: Date()))!
```

to:

```swift
let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: calendar.startOfDay(for: Date()))!
```

And update the predicate variable name:

```swift
let descriptor = FetchDescriptor<XPEvent>(
    predicate: #Predicate<XPEvent> { $0.earnedAt >= fifteenDaysAgo }
)
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/james/Claude\ Projects/Niwa/Niwa && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaShared/Engines/GamificationEngine.swift
git commit -m "feat(insights): expand XP event fetch window to 15 days for prior-week comparison"
```

---

### Task 2: Add meetingsReviewedThisWeek to CalendarManager

**Files:**
- Modify: `NiwaApp/Services/CalendarManager.swift`

- [ ] **Step 1: Add computed property after the `pastEvents` property (after line 105)**

```swift
    var meetingsReviewedThisWeek: Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        let descriptor = FetchDescriptor<MeetingReview>(
            predicate: #Predicate { $0.reviewedAt >= sevenDaysAgo }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Services/CalendarManager.swift
git commit -m "feat(insights): add meetingsReviewedThisWeek computed property"
```

---

## Chunk 2: UI — Insights View in XPChartView

### Task 3: Add insights model, view, and toggle to XPChartView

**Files:**
- Modify: `NiwaApp/Views/Components/XPChartView.swift`

- [ ] **Step 1: Add `meetingsReviewedThisWeek` parameter to XPChartView**

Change the struct declaration from:

```swift
struct XPChartView: View {
    let xpEvents: [XPEvent]
```

to:

```swift
struct XPChartView: View {
    let xpEvents: [XPEvent]
    var meetingsReviewedThisWeek: Int = 0

    @State private var showInsights = false
```

- [ ] **Step 2: Add the `WeeklyInsights` struct after `DayXP` (after line 17)**

```swift
private struct WeeklyInsights {
    let tasksCompleted: Int
    let focusMinutes: Int
    let meetingsReviewed: Int
    let watersLogged: Int
    let totalXP: Int
    let priorWeekXP: Int

    var focusFormatted: String {
        let hours = focusMinutes / 60
        let mins = focusMinutes % 60
        return hours > 0 ? "\(hours):\(String(format: "%02d", mins))" : "\(mins)m"
    }

    var headline: String {
        if totalXP == 0 { return "Your week starts now" }
        if priorWeekXP == 0 { return "Looking good so far" }
        let change = Double(totalXP - priorWeekXP) / Double(priorWeekXP) * 100
        switch change {
        case 20...: return "Crushing it this week"
        case 1..<20: return "Strong week so far"
        case -1..<1: return "Steady progress"
        case -20..<(-1): return "Slow start — you've got this"
        default: return "Quiet week — time to grow"
        }
    }

    var summary: String {
        if totalXP == 0 { return "Start a task or focus session to grow your garden 🌱" }

        // Pick the trend emoji
        let trendEmoji: String
        if priorWeekXP == 0 {
            trendEmoji = "🌱"
        } else {
            let pct = Double(totalXP - priorWeekXP) / Double(priorWeekXP) * 100
            trendEmoji = pct >= 10 ? "📈" : pct <= -10 ? "📉" : "💪"
        }

        // Rank highlights by value, pick top 2
        var ranked: [(label: String, value: Int)] = []
        if tasksCompleted > 0 { ranked.append(("\(tasksCompleted) tasks done", tasksCompleted)) }
        if focusMinutes > 0 { ranked.append(("\(focusFormatted) focused", focusMinutes)) }
        if meetingsReviewed > 0 { ranked.append(("\(meetingsReviewed) meetings reviewed", meetingsReviewed)) }
        if watersLogged > 0 { ranked.append(("\(watersLogged) waters", watersLogged)) }
        ranked.sort { $0.value > $1.value }

        let detail = ranked.prefix(2).map(\.label).joined(separator: ", ")
        return detail.isEmpty ? "\(trendEmoji) Your week starts now" : "\(trendEmoji) \(detail)"
    }
}
```

- [ ] **Step 3: Add `computeInsights()` method to XPChartView (before `body`)**

```swift
    private func computeInsights() -> WeeklyInsights {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: startOfToday)!

        let thisWeek = xpEvents.filter { $0.earnedAt >= sevenDaysAgo }
        let priorWeek = xpEvents.filter { $0.earnedAt >= fourteenDaysAgo && $0.earnedAt < sevenDaysAgo }

        return WeeklyInsights(
            tasksCompleted: thisWeek.filter { $0.source == .task }.count,
            focusMinutes: thisWeek.filter { $0.source == .timer }.reduce(0) { $0 + $1.amount },
            meetingsReviewed: meetingsReviewedThisWeek,
            watersLogged: thisWeek.filter { $0.source == .water }.count,
            totalXP: thisWeek.reduce(0) { $0 + $1.amount },
            priorWeekXP: priorWeek.reduce(0) { $0 + $1.amount }
        )
    }
```

- [ ] **Step 4: Replace the `body` with toggle support**

Replace the entire `var body: some View` with:

```swift
    var body: some View {
        let chartData = computeChartData()

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header with toggle button
            HStack {
                Text(showInsights ? "Weekly Insights" : "XP — Last 7 Days")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showInsights.toggle()
                    }
                } label: {
                    Text(showInsights ? "📊" : "💡")
                        .font(.system(size: 11))
                        .padding(3)
                        .background(DesignTokens.Colors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(showInsights ? "Show chart" : "Show weekly insights")
            }

            if showInsights {
                insightsView
            } else {
                chartBarsView(chartData: chartData)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .onAppear { showInsights = false }
    }
```

- [ ] **Step 5: Extract chart bars into a private view**

```swift
    private func chartBarsView(chartData: (days: [DayXP], maxTotal: Int)) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(chartData.days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 2) {
                    VStack(spacing: 0) {
                        barSegment(value: day.gym, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary)
                        barSegment(value: day.meeting, maxTotal: chartData.maxTotal, color: Color(red: 224/255, green: 172/255, blue: 58/255).opacity(0.7))
                        barSegment(value: day.creatine, maxTotal: chartData.maxTotal, color: Color(red: 224/255, green: 172/255, blue: 58/255))
                        barSegment(value: day.stand, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.secondary.opacity(0.6))
                        barSegment(value: day.water, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.secondary)
                        barSegment(value: day.coffee, maxTotal: chartData.maxTotal, color: Color(red: 139/255, green: 90/255, blue: 43/255))
                        barSegment(value: day.note, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary.opacity(0.5))
                        barSegment(value: day.timer, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary.opacity(0.75))
                        barSegment(value: day.task, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary.opacity(0.35))
                    }
                    .frame(height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                    Text(day.day)
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
```

- [ ] **Step 6: Add the insights view**

```swift
    private var insightsView: some View {
        let insights = computeInsights()

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(insights.headline)
                .font(DesignTokens.Typography.captionFont)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                statPill(value: "\(insights.tasksCompleted)", label: "tasks", color: DesignTokens.Colors.primary)
                statPill(value: insights.focusFormatted, label: "focused", color: DesignTokens.Colors.secondary)
                statPill(value: "\(insights.meetingsReviewed)", label: "meetings", color: Color(red: 224/255, green: 172/255, blue: 58/255))
                statPill(value: "\(insights.watersLogged)", label: "waters", color: DesignTokens.Colors.secondary)
            }

            Text(insights.summary)
                .font(.system(size: 9))
                .foregroundStyle(DesignTokens.Colors.textMuted)
                .lineLimit(2)
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(DesignTokens.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }
```

- [ ] **Step 7: Build to verify**

Run: `xcodegen generate && xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"`

Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add NiwaApp/Views/Components/XPChartView.swift
git commit -m "feat(insights): add weekly insights toggle to XP chart"
```

---

## Chunk 3: Wiring & Verification

### Task 4: Pass meetingsReviewedThisWeek through the view chain

**Files:**
- Modify: `NiwaApp/Views/DropdownRootView.swift:165`

- [ ] **Step 1: Update XPChartView call in DropdownRootView**

Change:

```swift
XPChartView(xpEvents: gamificationEngine.recentXPEvents)
```

to:

```swift
XPChartView(xpEvents: gamificationEngine.recentXPEvents, meetingsReviewedThisWeek: calendarManager.meetingsReviewedThisWeek)
```

- [ ] **Step 2: Build and run tests**

Run:
```bash
xcodebuild -scheme NiwaApp -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "error:|BUILD"
```

Then:
```bash
xcodebuild -scheme NiwaApp -destination 'platform=macOS' test CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO 2>&1 | grep -E "Executed|failed|BUILD"
```

Expected: BUILD SUCCEEDED, 49 tests, 0 failures.

- [ ] **Step 3: Commit**

```bash
git add NiwaApp/Views/DropdownRootView.swift
git commit -m "feat(insights): wire meetingsReviewedThisWeek to XPChartView"
```

---

### Task 5: Manual verification

- [ ] **Step 1: Launch the app**

```bash
pkill -x Niwa 2>/dev/null; sleep 1; open "$(find ~/Library/Developer/Xcode/DerivedData/Niwa-*/Build/Products/Debug/Niwa.app -maxdepth 0 2>/dev/null | head -1)"
```

- [ ] **Step 2: Verify**

1. Open dropdown — XP chart shows with 💡 button in header
2. Click 💡 — chart swaps to insights with stat pills and summary
3. Header changes to "Weekly Insights" with 📊 button
4. Click 📊 — swaps back to chart
5. Close and reopen dropdown — should default to chart view
