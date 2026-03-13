import SwiftUI
import AppKit

struct WelcomeOverlay: View {
    @Binding var isVisible: Bool
    @State private var name: String = ""
    let onComplete: (String) -> Void

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: DesignTokens.Spacing.lg) {
                    // App icon
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.top, DesignTokens.Spacing.md)

                    Text("Welcome to Niwa")
                        .font(DesignTokens.Typography.titleFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("Your garden awaits. What should we call you?")
                        .font(DesignTokens.Typography.captionFont)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)

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
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .onSubmit { submit() }

                    Button {
                        submit()
                    } label: {
                        Text("Let's grow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(DesignTokens.Colors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.md)
                }
                .frame(width: 260)
                .background(DesignTokens.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                .shadow(radius: 20, y: 8)
            }
        }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        onComplete(trimmed.isEmpty ? "" : trimmed)
        withAnimation(DesignTokens.Animation.viewTransition) {
            isVisible = false
        }
    }
}
