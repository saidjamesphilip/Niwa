import SwiftUI
import SwiftData

struct XPBarView: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var level: Int { profile?.currentLevel ?? 0 }
    private var totalXP: Int { profile?.totalXP ?? 0 }

    private var progress: (current: Int, needed: Int) {
        let result = XPConstants.xpForNextLevel(currentTotalXP: totalXP)
        return (current: result.currentLevelXP, needed: result.nextLevelXP)
    }

    private var fillFraction: Double {
        guard progress.needed > 0 else { return 0 }
        return Double(progress.current) / Double(progress.needed)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text("Level \(level)")
                    .font(DesignTokens.Typography.headingFont)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Text("\(progress.current) / \(progress.needed) XP")
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(DesignTokens.Colors.subtle)
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.primary,
                                    DesignTokens.Colors.primary.opacity(0.8),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * fillFraction), height: 8)
                        .animation(DesignTokens.Animation.xpBarFill, value: fillFraction)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}
