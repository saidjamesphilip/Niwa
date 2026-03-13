import SwiftUI

struct GreetingBanner: View {
    let message: String
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Colors.secondary)

                Text(message)
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.secondary.opacity(0.1))
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(DesignTokens.Animation.viewTransition) {
                        isVisible = false
                    }
                }
            }
            .onTapGesture {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    isVisible = false
                }
            }
        }
    }
}

enum GreetingMessages {
    static func randomGreeting(name: String) -> String {
        let displayName = name.isEmpty ? "" : ", \(name)"

        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default: timeGreeting = "Good evening"
        }

        let messages = [
            "\(timeGreeting)\(displayName). The garden awaits.",
            "\(timeGreeting)\(displayName). What will you grow today?",
            "\(timeGreeting)\(displayName). Every task is a seed planted.",
            "\(timeGreeting)\(displayName). A new day to tend your garden.",
            "\(timeGreeting)\(displayName). Even small steps help the garden grow.",
            "\(timeGreeting)\(displayName). Let your focus bloom.",
            "\(timeGreeting)\(displayName). Ready to cultivate something great?",
            "\(timeGreeting)\(displayName). Your garden has been waiting for you.",
            "\(timeGreeting)\(displayName). One task at a time, one leaf at a time.",
            "\(timeGreeting)\(displayName). The best time to plant is now.",
            "\(timeGreeting)\(displayName). Patience and focus grow the tallest trees.",
            "\(timeGreeting)\(displayName). Today is full of possibility.",
            "\(timeGreeting)\(displayName). Water your intentions with action.",
            "\(timeGreeting)\(displayName). The path through the garden begins with a single step.",
            "\(timeGreeting)\(displayName). Your garden reflects the care you give it.",
        ]

        return messages.randomElement() ?? "\(timeGreeting)\(displayName). Let's begin."
    }
}
