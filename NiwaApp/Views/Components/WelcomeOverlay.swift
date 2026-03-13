import SwiftUI
import AppKit

struct WelcomeOverlay: View {
    @Binding var isVisible: Bool
    @State private var name: String = ""
    let onComplete: (String) -> Void

    private var nameIsValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    // Header with sage gradient
                    VStack(spacing: 10) {
                        Text("⛩️")
                            .font(.system(size: 44))
                            .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 8, y: 2)

                        Text("Welcome to Niwa")
                            .font(DesignTokens.Typography.titleFont)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Your personal productivity garden")
                            .font(DesignTokens.Typography.captionFont)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            colors: [DesignTokens.Colors.secondary.opacity(0.12), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Feature list
                    VStack(spacing: 6) {
                        featureRow(icon: "timer", text: "Focus timer — earn XP per minute")
                        featureRow(icon: "checkmark.circle", text: "Tasks & notes — stay organised")
                        featureRow(icon: "heart.fill", text: "Health habits — water, stand, move")
                        featureRow(icon: "leaf.fill", text: "Grow your plant from seed to tree")
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, 12)
                    .padding(.bottom, 14)

                    // Divider
                    Rectangle()
                        .fill(DesignTokens.Colors.subtle)
                        .frame(width: 40, height: 1)
                        .padding(.bottom, 14)

                    // Name input
                    VStack(spacing: 10) {
                        TextField("Your name", text: $name)
                            .textFieldStyle(.plain)
                            .font(DesignTokens.Typography.bodyFont)
                            .padding(DesignTokens.Spacing.sm)
                            .background(DesignTokens.Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .stroke(DesignTokens.Colors.subtle, lineWidth: 1)
                            )
                            .onSubmit { if nameIsValid { submit() } }

                        Button {
                            submit()
                        } label: {
                            Text("Enter the garden")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(nameIsValid ? DesignTokens.Colors.primary : DesignTokens.Colors.primary.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                        }
                        .buttonStyle(.plain)
                        .disabled(!nameIsValid)
                        .accessibilityHint(nameIsValid ? "Opens the garden" : "Enter your name first")
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.md)
                }
                .frame(width: 280)
                .background(DesignTokens.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                .shadow(radius: 20, y: 8)
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.secondary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(DesignTokens.Colors.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Submit

    private func submit() {
        guard nameIsValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        onComplete(trimmed)
        isVisible = false
    }
}
