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

    var total: Int { task + timer + note + water + coffee + stand + creatine + gym }
}

struct XPChartView: View {
    let xpEvents: [XPEvent]

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
                gym: dayEvents.filter { $0.source == .gym }.reduce(0) { $0 + $1.amount }
            )
        }

        let maxTotal = max(days.map(\.total).max() ?? 1, 1)
        return (days, maxTotal)
    }

    var body: some View {
        let chartData = computeChartData()

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("XP — Last 7 Days")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(chartData.days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 2) {
                        // Stacked bar
                        VStack(spacing: 0) {
                            barSegment(value: day.gym, maxTotal: chartData.maxTotal, color: DesignTokens.Colors.primary)
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
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private func barSegment(value: Int, maxTotal: Int, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: max(0, CGFloat(value) / CGFloat(maxTotal) * 36))
    }
}
