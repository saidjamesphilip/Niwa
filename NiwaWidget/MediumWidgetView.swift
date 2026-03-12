import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: NiwaWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left: Timer
            VStack(spacing: 4) {
                Image(systemName: entry.plantIconName)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 224/255, green: 122/255, blue: 95/255))

                if entry.timerActive, let start = entry.timerStartDate, let end = entry.timerEndDate {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 224/255, green: 122/255, blue: 95/255))
                        .monospacedDigit()

                    Text(entry.sessionLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 122/255, green: 110/255, blue: 99/255))
                } else {
                    Text("--:--")
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 168/255, green: 155/255, blue: 140/255))
                }

                Text("Lv \(entry.currentLevel)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 61/255, green: 50/255, blue: 41/255))
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Tasks + Health
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.topTasks.prefix(3).enumerated()), id: \.offset) { _, task in
                    HStack(spacing: 4) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(task.isCompleted
                                ? Color(red: 129/255, green: 178/255, blue: 154/255)
                                : Color(red: 168/255, green: 155/255, blue: 140/255))
                        Text(task.title)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 61/255, green: 50/255, blue: 41/255))
                            .lineLimit(1)
                    }
                }

                if entry.topTasks.isEmpty {
                    Text("No tasks")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 168/255, green: 155/255, blue: 140/255))
                }

                Spacer()

                // Health pills
                HStack(spacing: 6) {
                    healthPill(icon: "drop.fill", text: "\(entry.waterCount)")
                    if entry.isStanding {
                        healthPill(icon: "figure.stand", text: "Up")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .containerBackground(Color(red: 250/255, green: 246/255, blue: 241/255), for: .widget)
    }

    private func healthPill(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 9))
        }
        .foregroundStyle(Color(red: 129/255, green: 178/255, blue: 154/255))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(red: 129/255, green: 178/255, blue: 154/255).opacity(0.15))
        .clipShape(Capsule())
    }
}
