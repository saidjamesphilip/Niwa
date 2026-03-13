import SwiftUI
import SwiftData

struct XPChartView: View {
    @Query private var xpEvents: [XPEvent]

    private var last7DaysData: [(day: String, task: Int, timer: Int, note: Int, water: Int, stand: Int, creatine: Int, gym: Int)] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let dayStart = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayEvents = xpEvents.filter { $0.earnedAt >= dayStart && $0.earnedAt < dayEnd }

            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let label = String(formatter.string(from: dayStart).prefix(2))

            return (
                day: label,
                task: dayEvents.filter { $0.source == .task }.reduce(0) { $0 + $1.amount },
                timer: dayEvents.filter { $0.source == .timer }.reduce(0) { $0 + $1.amount },
                note: dayEvents.filter { $0.source == .note }.reduce(0) { $0 + $1.amount },
                water: dayEvents.filter { $0.source == .water }.reduce(0) { $0 + $1.amount },
                stand: dayEvents.filter { $0.source == .stand }.reduce(0) { $0 + $1.amount },
                creatine: dayEvents.filter { $0.source == .creatine }.reduce(0) { $0 + $1.amount },
                gym: dayEvents.filter { $0.source == .gym }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    private var maxDayTotal: Int {
        max(last7DaysData.map { $0.task + $0.timer + $0.note + $0.water + $0.stand + $0.creatine + $0.gym }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("XP — Last 7 Days")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(last7DaysData.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 2) {
                        // Stacked bar
                        VStack(spacing: 0) {
                            barSegment(value: day.gym, color: DesignTokens.Colors.primary)
                            barSegment(value: day.creatine, color: Color(red: 224/255, green: 172/255, blue: 58/255))
                            barSegment(value: day.stand, color: DesignTokens.Colors.secondary.opacity(0.6))
                            barSegment(value: day.water, color: DesignTokens.Colors.secondary)
                            barSegment(value: day.note, color: DesignTokens.Colors.primary.opacity(0.5))
                            barSegment(value: day.timer, color: DesignTokens.Colors.primary.opacity(0.75))
                            barSegment(value: day.task, color: DesignTokens.Colors.primary.opacity(0.35))
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

    private func barSegment(value: Int, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: max(0, CGFloat(value) / CGFloat(maxDayTotal) * 36))
    }
}
