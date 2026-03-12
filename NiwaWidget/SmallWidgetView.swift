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
                    .foregroundStyle(Color(red: 224/255, green: 122/255, blue: 95/255))
                Text("Lv \(entry.currentLevel)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 61/255, green: 50/255, blue: 41/255))
                Spacer()
            }

            Spacer()

            // Timer
            if entry.timerActive, let start = entry.timerStartDate, let end = entry.timerEndDate {
                Text(timerInterval: start...end, countsDown: true)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 224/255, green: 122/255, blue: 95/255))
                    .monospacedDigit()

                Text(entry.sessionLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 122/255, green: 110/255, blue: 99/255))
            } else {
                Text("--:--")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 168/255, green: 155/255, blue: 140/255))

                Text("Ready")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 122/255, green: 110/255, blue: 99/255))
            }

            Spacer()

            // XP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 212/255, green: 197/255, blue: 178/255))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color(red: 224/255, green: 122/255, blue: 95/255))
                        .frame(width: geo.size.width * entry.xpProgress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .containerBackground(Color(red: 250/255, green: 246/255, blue: 241/255), for: .widget)
    }
}
