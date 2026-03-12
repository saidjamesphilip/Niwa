import SwiftUI
import SwiftData

/// A growing plant visualization that evolves with the user's level.
/// Stages: seed (0), sprout (1-3), seedling (4-7), young plant (8-12),
/// bush (13-18), small tree (19-25), full tree (26-35), ancient tree (36+)
struct PlantView: View {
    let level: Int

    private var stage: PlantStage {
        switch level {
        case 0: return .seed
        case 1...3: return .sprout
        case 4...7: return .seedling
        case 8...12: return .youngPlant
        case 13...18: return .bush
        case 19...25: return .smallTree
        case 26...35: return .fullTree
        default: return .ancientTree
        }
    }

    var body: some View {
        ZStack {
            // Ground
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 139/255, green: 119/255, blue: 93/255).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 12)
                .offset(y: 38)

            // Plant
            plantBody
                .animation(DesignTokens.Animation.viewTransition, value: level)
        }
        .frame(width: 80, height: 90)
    }

    @ViewBuilder
    private var plantBody: some View {
        switch stage {
        case .seed:
            seedView
        case .sprout:
            sproutView
        case .seedling:
            seedlingView
        case .youngPlant:
            youngPlantView
        case .bush:
            bushView
        case .smallTree:
            smallTreeView
        case .fullTree:
            fullTreeView
        case .ancientTree:
            ancientTreeView
        }
    }

    // MARK: - Seed (Level 0)
    private var seedView: some View {
        Circle()
            .fill(Color(red: 139/255, green: 119/255, blue: 93/255))
            .frame(width: 8, height: 8)
            .offset(y: 32)
    }

    // MARK: - Sprout (Level 1-3)
    private var sproutView: some View {
        VStack(spacing: 0) {
            Spacer()
            // Two tiny leaves
            HStack(spacing: 2) {
                leaf(width: 8, height: 12, rotation: -30, color: DesignTokens.Colors.secondary)
                leaf(width: 8, height: 12, rotation: 30, color: DesignTokens.Colors.secondary)
            }
            // Stem
            RoundedRectangle(cornerRadius: 1)
                .fill(DesignTokens.Colors.secondary)
                .frame(width: 2, height: 14)
        }
        .offset(y: 4)
    }

    // MARK: - Seedling (Level 4-7)
    private var seedlingView: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                // Upper leaves
                HStack(spacing: 0) {
                    leaf(width: 12, height: 16, rotation: -40, color: DesignTokens.Colors.secondary)
                        .offset(x: -2, y: -8)
                    leaf(width: 12, height: 16, rotation: 40, color: DesignTokens.Colors.secondary)
                        .offset(x: 2, y: -8)
                }
                // Lower leaves
                HStack(spacing: 0) {
                    leaf(width: 10, height: 14, rotation: -55, color: DesignTokens.Colors.secondary.opacity(0.8))
                        .offset(x: -6, y: 2)
                    leaf(width: 10, height: 14, rotation: 55, color: DesignTokens.Colors.secondary.opacity(0.8))
                        .offset(x: 6, y: 2)
                }
                // Stem
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(DesignTokens.Colors.secondary.opacity(0.7))
                    .frame(width: 3, height: 24)
                    .offset(y: 12)
            }
        }
        .offset(y: 2)
    }

    // MARK: - Young Plant (Level 8-12)
    private var youngPlantView: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                // Top cluster
                ForEach(0..<5, id: \.self) { i in
                    let angle = Double(i) * 72 - 90
                    leaf(width: 11, height: 15, rotation: angle * 0.5, color: DesignTokens.Colors.secondary)
                        .offset(
                            x: CGFloat(cos(angle * .pi / 180)) * 8,
                            y: CGFloat(sin(angle * .pi / 180)) * 6 - 14
                        )
                }
                // Mid leaves
                leaf(width: 13, height: 17, rotation: -50, color: DesignTokens.Colors.secondary.opacity(0.85))
                    .offset(x: -10, y: 0)
                leaf(width: 13, height: 17, rotation: 50, color: DesignTokens.Colors.secondary.opacity(0.85))
                    .offset(x: 10, y: 0)
                // Stem
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 110/255, green: 90/255, blue: 65/255))
                    .frame(width: 4, height: 32)
                    .offset(y: 14)
            }
        }
        .offset(y: 0)
    }

    // MARK: - Bush (Level 13-18)
    private var bushView: some View {
        ZStack {
            // Canopy layers
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.5))
                .frame(width: 50, height: 35)
                .offset(y: -2)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.7))
                .frame(width: 42, height: 30)
                .offset(y: -6)
            Ellipse()
                .fill(DesignTokens.Colors.secondary)
                .frame(width: 32, height: 24)
                .offset(y: -10)
            // Highlight
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.3))
                .frame(width: 14, height: 10)
                .offset(x: -6, y: -16)
            // Trunk
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 100/255, green: 80/255, blue: 55/255))
                .frame(width: 6, height: 22)
                .offset(y: 20)
        }
        .offset(y: -4)
    }

    // MARK: - Small Tree (Level 19-25)
    private var smallTreeView: some View {
        ZStack {
            // Canopy
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.4))
                .frame(width: 58, height: 38)
                .offset(y: -10)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.65))
                .frame(width: 48, height: 32)
                .offset(y: -14)
            Ellipse()
                .fill(DesignTokens.Colors.secondary)
                .frame(width: 36, height: 26)
                .offset(y: -18)
            // Highlight
            Ellipse()
                .fill(Color.white.opacity(0.1))
                .frame(width: 16, height: 10)
                .offset(x: -8, y: -24)
            // Trunk
            trunkShape(width: 7, height: 30)
                .offset(y: 16)
            // Branch left
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(red: 90/255, green: 72/255, blue: 50/255))
                .frame(width: 3, height: 12)
                .rotationEffect(.degrees(-40))
                .offset(x: -10, y: 4)
            // Branch right
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(red: 90/255, green: 72/255, blue: 50/255))
                .frame(width: 3, height: 10)
                .rotationEffect(.degrees(35))
                .offset(x: 8, y: 6)
        }
        .offset(y: -2)
    }

    // MARK: - Full Tree (Level 26-35)
    private var fullTreeView: some View {
        ZStack {
            // Large canopy
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.35))
                .frame(width: 68, height: 44)
                .offset(y: -12)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.55))
                .frame(width: 56, height: 38)
                .offset(y: -16)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.75))
                .frame(width: 44, height: 32)
                .offset(y: -20)
            Ellipse()
                .fill(DesignTokens.Colors.secondary)
                .frame(width: 30, height: 22)
                .offset(y: -24)
            // Highlights
            Ellipse()
                .fill(Color.white.opacity(0.08))
                .frame(width: 18, height: 12)
                .offset(x: -10, y: -28)
            // Small fruit/flowers
            Circle()
                .fill(DesignTokens.Colors.primary.opacity(0.7))
                .frame(width: 4, height: 4)
                .offset(x: 12, y: -14)
            Circle()
                .fill(DesignTokens.Colors.primary.opacity(0.5))
                .frame(width: 3, height: 3)
                .offset(x: -14, y: -10)
            Circle()
                .fill(DesignTokens.Colors.primary.opacity(0.6))
                .frame(width: 3.5, height: 3.5)
                .offset(x: 6, y: -26)
            // Trunk
            trunkShape(width: 8, height: 34)
                .offset(y: 16)
            // Branches
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 85/255, green: 68/255, blue: 48/255))
                .frame(width: 3.5, height: 16)
                .rotationEffect(.degrees(-45))
                .offset(x: -14, y: 0)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 85/255, green: 68/255, blue: 48/255))
                .frame(width: 3.5, height: 14)
                .rotationEffect(.degrees(40))
                .offset(x: 12, y: 2)
        }
        .offset(y: -2)
    }

    // MARK: - Ancient Tree (Level 36+)
    private var ancientTreeView: some View {
        ZStack {
            // Massive canopy
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.3))
                .frame(width: 76, height: 48)
                .offset(y: -14)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.5))
                .frame(width: 64, height: 42)
                .offset(y: -18)
            Ellipse()
                .fill(DesignTokens.Colors.secondary.opacity(0.7))
                .frame(width: 50, height: 36)
                .offset(y: -22)
            Ellipse()
                .fill(DesignTokens.Colors.secondary)
                .frame(width: 36, height: 26)
                .offset(y: -26)
            // Golden glow
            Ellipse()
                .fill(DesignTokens.Colors.primary.opacity(0.1))
                .frame(width: 72, height: 46)
                .offset(y: -16)
            // Fruits
            ForEach(0..<5, id: \.self) { i in
                let positions: [(CGFloat, CGFloat)] = [
                    (14, -16), (-16, -12), (8, -28), (-8, -30), (18, -24)
                ]
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.7))
                    .frame(width: 5, height: 5)
                    .offset(x: positions[i].0, y: positions[i].1)
            }
            // Thick trunk
            trunkShape(width: 10, height: 36)
                .offset(y: 16)
            // Heavy branches
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(red: 80/255, green: 64/255, blue: 44/255))
                .frame(width: 4, height: 20)
                .rotationEffect(.degrees(-50))
                .offset(x: -16, y: -2)
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(red: 80/255, green: 64/255, blue: 44/255))
                .frame(width: 4, height: 18)
                .rotationEffect(.degrees(45))
                .offset(x: 14, y: 0)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 80/255, green: 64/255, blue: 44/255))
                .frame(width: 3, height: 12)
                .rotationEffect(.degrees(-30))
                .offset(x: -8, y: -6)
        }
        .offset(y: -2)
    }

    // MARK: - Helpers

    private func leaf(width: CGFloat, height: CGFloat, rotation: Double, color: Color) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(rotation))
    }

    private func trunkShape(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width / 3)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 100/255, green: 80/255, blue: 55/255),
                        Color(red: 80/255, green: 64/255, blue: 44/255)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
    }

    private enum PlantStage {
        case seed, sprout, seedling, youngPlant, bush, smallTree, fullTree, ancientTree
    }
}
