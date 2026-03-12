import SwiftUI

struct LevelUpOverlay: View {
    let level: Int
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiParticles: [ConfettiParticle] = []

    var body: some View {
        if isVisible {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                // Confetti
                if !reduceMotion {
                    ForEach(confettiParticles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }

                // Level-up card
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DesignTokens.Colors.primary)

                    Text("Level Up!")
                        .font(DesignTokens.Typography.titleFont)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("You reached Level \(level)")
                        .font(DesignTokens.Typography.bodyFont)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .padding(DesignTokens.Spacing.xl)
                .background(DesignTokens.Colors.background)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                .shadow(radius: 12)
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                if reduceMotion {
                    scale = 1
                    opacity = 1
                } else {
                    withAnimation(DesignTokens.Animation.levelUpBounce) {
                        scale = 1
                        opacity = 1
                    }
                    spawnConfetti()
                }

                // Auto-dismiss after 2.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        if reduceMotion {
            opacity = 0
            onDismiss()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
                scale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [
            DesignTokens.Colors.primary,
            DesignTokens.Colors.secondary,
            DesignTokens.Colors.primary.opacity(0.7),
            DesignTokens.Colors.secondary.opacity(0.7),
        ]

        confettiParticles = (0..<20).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                x: CGFloat.random(in: -120...120),
                y: CGFloat.random(in: -100...100),
                opacity: Double.random(in: 0.6...1.0)
            )
        }

        // Fade out confetti
        withAnimation(.easeOut(duration: 2.0)) {
            for i in confettiParticles.indices {
                confettiParticles[i].opacity = 0
                confettiParticles[i].y += CGFloat.random(in: 30...80)
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}
