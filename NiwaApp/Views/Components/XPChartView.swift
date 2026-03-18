import SwiftUI
import SwiftData

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
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(mins)m"
    }

    var headline: String {
        if totalXP == 0 { return "Your week starts now" }
        if priorWeekXP == 0 { return "Looking good so far" }
        let change = Double(totalXP - priorWeekXP) / Double(priorWeekXP) * 100
        switch change {
        case 20...: return "Crushing it this week"
        case 1..<20: return "Strong week so far"
        case -1..<1: return "Steady progress"
        case -20..<(-1): return "Below pace — you've got this"
        default: return "Quiet week — time to grow"
        }
    }

    var summary: String {
        if totalXP == 0 { return "Start a task or focus session to grow your garden 🌱" }

        let trendEmoji: String
        if priorWeekXP == 0 {
            trendEmoji = "🌱"
        } else {
            let pct = Double(totalXP - priorWeekXP) / Double(priorWeekXP) * 100
            trendEmoji = pct >= 10 ? "📈" : pct <= -10 ? "📉" : "💪"
        }

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

struct XPChartView: View {
    let xpEvents: [XPEvent]
    var meetingsReviewedThisWeek: Int = 0

    @State private var showInsights = false

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private func computeChartData() -> (days: [DayXP], maxTotal: Int) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let days: [DayXP] = (0..<7).reversed().map { daysAgo in
            let dayStart = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayEvents = xpEvents.filter { $0.earnedAt >= dayStart && $0.earnedAt < dayEnd }
            let label = String(Self.dayFormatter.string(from: dayStart).prefix(2))

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
        }

        let maxTotal = max(days.map(\.total).max() ?? 1, 1)
        return (days, maxTotal)
    }

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

    // MARK: - Chart Bars

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

    // MARK: - Insights View

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

    // MARK: - Helpers

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

    private func barSegment(value: Int, maxTotal: Int, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: max(0, CGFloat(value) / CGFloat(maxTotal) * 36))
    }
}
