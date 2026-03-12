import SwiftUI

struct WidgetXPSparkline: View {
    let data: [Int]

    private var maxValue: Int {
        max(data.max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 224/255, green: 122/255, blue: 95/255))
                        .frame(height: max(2, CGFloat(value) / CGFloat(maxValue) * 40))

                    Text(dayLabel(index))
                        .font(.system(size: 7))
                        .foregroundStyle(Color(red: 168/255, green: 155/255, blue: 140/255))
                }
            }
        }
    }

    private func dayLabel(_ index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
