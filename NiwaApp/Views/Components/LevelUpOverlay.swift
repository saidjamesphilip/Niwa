import SwiftUI

// MARK: - Brand Colors

private let sage        = Color(red: 129/255, green: 178/255, blue: 154/255)
private let amber       = Color(red: 224/255, green: 172/255, blue: 58/255)
private let terracotta  = Color(red: 224/255, green: 122/255, blue: 95/255)
private let lavender    = Color(red: 168/255, green: 148/255, blue: 200/255)

// MARK: - ConfettiParticle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let startX: CGFloat
    let rotation: Double
    let delay: Double
}

// MARK: - LevelUpOverlay

struct LevelUpOverlay: View {
    let level: Int
    let previousLevel: Int
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Entrance animation
    @State private var animated = false
    @State private var cardScale: CGFloat = 0.6

    // Stage evolution
    @State private var oldPlantOffset: CGFloat = 0
    @State private var oldPlantOpacity: Double = 1
    @State private var newPlantOffset: CGFloat = 60
    @State private var newPlantOpacity: Double = 0

    // Confetti
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var confettiDropped = false

    // Auto-dismiss
    @State private var dismissTask: DispatchWorkItem? = nil

    private var stageChanged: Bool {
        XPConstants.plantStage(for: previousLevel) != XPConstants.plantStage(for: level)
    }

    var body: some View {
        if isVisible {
            ZStack {
                // Dimmed full-bleed background with sage glow
                RadialGradient(
                    colors: [sage.opacity(0.18), Color.black.opacity(0.72)],
                    center: .center,
                    startRadius: 40,
                    endRadius: 220
                )
                .ignoresSafeArea()
                .onTapGesture { performDismiss() }

                // Confetti layer
                if !reduceMotion {
                    ForEach(confettiParticles) { particle in
                        ConfettiView(particle: particle, dropped: confettiDropped)
                    }
                }

                // Central content
                VStack(spacing: 16) {
                    // Plant + ring
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            if stageChanged && !reduceMotion {
                                // Old plant fades left
                                PlantView(level: previousLevel)
                                    .frame(width: 100, height: 100)
                                    .offset(x: oldPlantOffset)
                                    .opacity(oldPlantOpacity)

                                // New plant springs in from right
                                PlantView(level: level)
                                    .frame(width: 100, height: 100)
                                    .offset(x: newPlantOffset)
                                    .opacity(newPlantOpacity)
                            } else {
                                PlantView(level: level)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .frame(width: 100, height: 100)

                        // Rainbow XP ring
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [sage, amber, terracotta, sage],
                                    center: .center
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 116, height: 116)
                            .offset(x: 8, y: -8)
                            .shadow(color: sage.opacity(0.3), radius: 30)

                        // Floating +XP badge
                        Text("+XP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(sage)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(sage.opacity(0.15)))
                            .offset(x: 10, y: animated ? -28 : -8)
                            .opacity(animated ? 0 : 1)
                    }
                    .scaleEffect(cardScale)

                    // Text stack
                    VStack(spacing: 6) {
                        Text("LEVEL UP")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(sage)
                            .textCase(.uppercase)
                            .kerning(1)

                        Text("Level \(level)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)

                        // Stage name badge
                        Text(XPConstants.plantStageName(for: level))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(sage)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(sage.opacity(0.15)))

                        Text("Tap anywhere to continue")
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .padding(.top, 4)
                    }
                    .scaleEffect(cardScale)
                }
            }
            .accessibilityLabel("Level up! You reached level \(level), \(XPConstants.plantStageName(for: level)) stage")
            .onAppear {
                startAnimations()
            }
        }
    }

    // MARK: - Animation

    private func startAnimations() {
        confettiParticles = makeConfetti()

        if reduceMotion {
            cardScale = 1
            animated = false
            scheduleDismiss()
            return
        }

        // Entrance spring
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cardScale = 1
        }

        // +XP badge float + fade
        withAnimation(.easeOut(duration: 2).delay(0.3)) {
            animated = true
        }

        // Drop confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            confettiDropped = true
        }

        // Stage evolution transition
        if stageChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    oldPlantOffset = -60
                    oldPlantOpacity = 0
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                    newPlantOffset = 0
                    newPlantOpacity = 1
                }
            }
        }

        scheduleDismiss()
    }

    private func scheduleDismiss() {
        let item = DispatchWorkItem { performDismiss() }
        dismissTask = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: item)
    }

    private func performDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        onDismiss()
    }

    // MARK: - Confetti Factory

    private func makeConfetti() -> [ConfettiParticle] {
        let colors: [Color] = [sage, amber, terracotta, lavender]
        return (0..<25).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                width: CGFloat.random(in: 3...6),
                height: CGFloat.random(in: 6...12),
                startX: CGFloat.random(in: -140...140),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}

// MARK: - ConfettiView

private struct ConfettiView: View {
    let particle: ConfettiParticle
    let dropped: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(particle.color)
            .frame(width: particle.width, height: particle.height)
            .rotationEffect(.degrees(dropped ? particle.rotation + 360 : particle.rotation))
            .offset(x: particle.startX, y: dropped ? -80 + 120 : -80)
            .opacity(dropped ? 0 : 1)
            .animation(
                .easeIn(duration: 2.5).delay(particle.delay),
                value: dropped
            )
    }
}
