import SwiftUI

// MARK: - Niwa Design Tokens
// Authoritative source: design-system.md

enum DesignTokens {

    // MARK: - Colors

    enum Colors {
        // Light mode
        static let backgroundLight = Color(red: 250/255, green: 246/255, blue: 241/255)
        static let backgroundSecondaryLight = Color(red: 240/255, green: 234/255, blue: 224/255)
        static let primaryLight = Color(red: 224/255, green: 122/255, blue: 95/255)
        static let primaryHoverLight = Color(red: 201/255, green: 107/255, blue: 82/255)
        static let secondaryLight = Color(red: 129/255, green: 178/255, blue: 154/255)
        static let secondaryHoverLight = Color(red: 110/255, green: 158/255, blue: 134/255)
        static let textPrimaryLight = Color(red: 61/255, green: 50/255, blue: 41/255)
        static let textSecondaryLight = Color(red: 122/255, green: 110/255, blue: 99/255)
        static let textMutedLight = Color(red: 168/255, green: 155/255, blue: 140/255)
        static let subtleLight = Color(red: 212/255, green: 197/255, blue: 178/255)
        static let dangerLight = Color(red: 196/255, green: 69/255, blue: 54/255)

        // Dark mode
        static let backgroundDark = Color(red: 28/255, green: 25/255, blue: 23/255)
        static let backgroundSecondaryDark = Color(red: 44/255, green: 37/255, blue: 32/255)
        static let primaryDark = Color(red: 224/255, green: 122/255, blue: 95/255)
        static let primaryHoverDark = Color(red: 232/255, green: 144/255, blue: 122/255)
        static let secondaryDark = Color(red: 129/255, green: 178/255, blue: 154/255)
        static let secondaryHoverDark = Color(red: 150/255, green: 196/255, blue: 173/255)
        static let textPrimaryDark = Color(red: 250/255, green: 246/255, blue: 241/255)
        static let textSecondaryDark = Color(red: 191/255, green: 179/255, blue: 165/255)
        static let textMutedDark = Color(red: 122/255, green: 110/255, blue: 99/255)
        static let subtleDark = Color(red: 61/255, green: 50/255, blue: 41/255)
        static let dangerDark = Color(red: 224/255, green: 85/255, blue: 69/255)

        // Adaptive colors (resolve based on color scheme)
        static let background = Color("background")
        static let backgroundSecondary = Color("backgroundSecondary")
        static let primary = Color("primary")
        static let primaryHover = Color("primaryHover")
        static let secondary = Color("secondary")
        static let secondaryHover = Color("secondaryHover")
        static let textPrimary = Color("textPrimary")
        static let textSecondary = Color("textSecondary")
        static let textMuted = Color("textMuted")
        static let subtle = Color("subtle")
        static let danger = Color("danger")
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: - Corner Radii

    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows

    enum Shadow {
        static let subtleRadius: CGFloat = 8
        static let subtleY: CGFloat = 2
        static let elevatedRadius: CGFloat = 16
        static let elevatedY: CGFloat = 4

        static func subtleColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black.opacity(0.3)
                : Color(red: 61/255, green: 50/255, blue: 41/255).opacity(0.08)
        }

        static func elevatedColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.black.opacity(0.5)
                : Color(red: 61/255, green: 50/255, blue: 41/255).opacity(0.12)
        }
    }

    // MARK: - Typography

    enum Typography {
        static let titleFont: Font = .system(size: 18, weight: .semibold, design: .rounded)
        static let headingFont: Font = .system(size: 15, weight: .medium, design: .rounded)
        static let bodyFont: Font = .system(size: 13, weight: .regular)
        static let captionFont: Font = .system(size: 11, weight: .regular)
        static let monoFont: Font = .system(size: 12, weight: .regular, design: .monospaced)
        static let monoLargeFont: Font = .system(size: 36, weight: .medium, design: .monospaced)
    }

    // MARK: - Animation

    enum Animation {
        static let xpBarFill: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
        static let levelUpBounce: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.6)
        static let viewTransition: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.85)
        static let buttonPress: SwiftUI.Animation = .easeInOut(duration: 0.15)
    }
}
