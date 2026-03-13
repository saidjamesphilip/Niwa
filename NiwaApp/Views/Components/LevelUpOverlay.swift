import SwiftUI

// MARK: - LevelUpOverlay (Zen Garden)

struct LevelUpOverlay: View {
    let level: Int
    let previousLevel: Int
    let isVisible: Bool
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false
    @State private var dismissTask: DispatchWorkItem? = nil

    // Stage evolution
    @State private var oldPlantOffset: CGFloat = 0
    @State private var oldPlantOpacity: Double = 1
    @State private var newPlantOffset: CGFloat = 40
    @State private var newPlantOpacity: Double = 0

    private var stageChanged: Bool {
        XPConstants.plantStage(for: previousLevel) != XPConstants.plantStage(for: level)
    }

    var body: some View {
        if isVisible {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .onTapGesture { performDismiss() }

                // Central content
                VStack(spacing: 24) {
                    // Top rule
                    rule

                    // Plant — large, with subtle sage shadow
                    ZStack {
                        if stageChanged && !reduceMotion {
                            PlantView(level: previousLevel)
                                .frame(width: 120, height: 120)
                                .offset(x: oldPlantOffset)
                                .opacity(oldPlantOpacity)

                            PlantView(level: level)
                                .frame(width: 120, height: 120)
                                .offset(x: newPlantOffset)
                                .opacity(newPlantOpacity)
                        } else {
                            PlantView(level: level)
                                .frame(width: 120, height: 120)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .shadow(color: DesignTokens.Colors.secondary.opacity(0.25), radius: 20, y: 4)

                    // Text stack
                    VStack(spacing: 10) {
                        Text("LEVEL UP")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DesignTokens.Colors.textMuted)
                            .kerning(3)

                        Text("\(level)")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text(XPConstants.plantStageName(for: level))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .kerning(1)
                    }

                    // Bottom rule
                    rule

                    Text("Click anywhere to continue")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.textMuted)
                }
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
            }
            .accessibilityLabel("Level up! You reached level \(level), \(XPConstants.plantStageName(for: level)) stage")
            .onAppear { startAnimations() }
        }
    }

    // MARK: - Components

    private var rule: some View {
        Rectangle()
            .fill(DesignTokens.Colors.textMuted.opacity(0.3))
            .frame(width: 60, height: 1)
    }

    // MARK: - Animation

    private func startAnimations() {
        if reduceMotion {
            appeared = true
            oldPlantOpacity = 0
            newPlantOffset = 0
            newPlantOpacity = 1
            scheduleDismiss()
            return
        }

        withAnimation(.easeOut(duration: 0.4)) {
            appeared = true
        }

        // Stage evolution
        if stageChanged {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    oldPlantOffset = -40
                    oldPlantOpacity = 0
                }
                withAnimation(.easeOut(duration: 0.5)) {
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
}
