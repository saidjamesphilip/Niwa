import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: NiwaWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            // Plant icon + level
            HStack {
                Image(systemName: entry.plantIconName)
                    .font(.system(size: 14))
                    .foregroundStyle(WidgetDesignTokens.primary)
                Text("Lv \(entry.currentLevel)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetDesignTokens.textPrimary)
                Spacer()
            }

            Spacer()

            // Timer
            if entry.timerActive, let start = entry.timerStartDate, let end = entry.timerEndDate {
                Text(timerInterval: start...end, countsDown: true)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(WidgetDesignTokens.primary)
                    .monospacedDigit()

                Text(entry.sessionLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetDesignTokens.textSecondary)
            } else {
                Text("--:--")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(WidgetDesignTokens.textMuted)

                Text("Ready")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetDesignTokens.textSecondary)
            }

            Spacer()

            // XP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetDesignTokens.xpTrack)
                        .frame(height: 4)
                    Capsule()
                        .fill(WidgetDesignTokens.primary)
                        .frame(width: geo.size.width * entry.xpProgress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .containerBackground(WidgetDesignTokens.background, for: .widget)
    }
}
