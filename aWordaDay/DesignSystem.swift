import SwiftUI
import UIKit

// MARK: - Design System Tokens
struct DesignTokens {
    // MARK: - Spacing
    static let spacing: LayoutSpacing = LayoutSpacing()
    
    struct LayoutSpacing {
        let xs: CGFloat = 4      // Micro spacing
        let sm: CGFloat = 8      // Tight spacing
        let md: CGFloat = 12     // Base spacing unit
        let lg: CGFloat = 16     // Medium spacing
        let lg2: CGFloat = 20    // Medium-large spacing
        let xl: CGFloat = 24     // Large spacing
        let xxl: CGFloat = 32    // Extra large spacing
        let xxxl: CGFloat = 48   // Maximum spacing
    }
    
    // MARK: - Corner Radius
    static let cornerRadius: CornerRadius = CornerRadius()
    
    struct CornerRadius {
        let sm: CGFloat = 8      // Small elements
        let md: CGFloat = 12     // Chips, buttons
        let lg: CGFloat = 16     // Cards, inputs
        let xl: CGFloat = 20     // Main content cards
        let pill: CGFloat = 999  // Pill-shaped elements
    }
    
    // MARK: - Shadows
    static let shadow: ShadowSystem = ShadowSystem()
    
    struct ShadowSystem {
        let light = ShadowToken(
            color: Color.blue.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        
        let medium = ShadowToken(
            color: Color.blue.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )
        
        let heavy = ShadowToken(
            color: Color.blue.opacity(0.15),
            radius: 15,
            x: 0,
            y: 8
        )
        
        let interactive = ShadowToken(
            color: Color.blue.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    struct ShadowToken {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Colors
    static let color: ColorSystem = ColorSystem()
    
    struct ColorSystem {
        // Helper for adaptive colors
        private static func adaptive(light: UIColor, dark: UIColor) -> Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
        }

        // Primary palette
        let primary = Color(red: 0.2, green: 0.5, blue: 1.0)
        let primaryDark = Color(red: 0.1, green: 0.4, blue: 0.9)
        let accentBlue = Color(red: 0.32, green: 0.56, blue: 1.0)
        let skyBlue = Color(red: 0.36, green: 0.71, blue: 0.98)
        let translationBlue = adaptive(
            light: UIColor(red: 0.35, green: 0.55, blue: 0.82, alpha: 1),
            dark: UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1)
        )

        // Text colors
        let textPrimary = adaptive(
            light: UIColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1),
            dark: UIColor(red: 0.85, green: 0.88, blue: 0.95, alpha: 1)
        )
        let textSecondary = adaptive(
            light: UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1),
            dark: UIColor(red: 0.75, green: 0.8, blue: 0.88, alpha: 1)
        )
        let textTertiary = adaptive(
            light: UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1),
            dark: UIColor(red: 0.65, green: 0.7, blue: 0.8, alpha: 1)
        )
        let textMuted = adaptive(
            light: UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 1),
            dark: UIColor(red: 0.55, green: 0.6, blue: 0.7, alpha: 1)
        )
        let textLight = adaptive(
            light: UIColor(red: 0.45, green: 0.55, blue: 0.75, alpha: 1),
            dark: UIColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 1)
        )
        let textSubtle = adaptive(
            light: UIColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 1),
            dark: UIColor(red: 0.55, green: 0.6, blue: 0.75, alpha: 1)
        )
        let headingPrimary = adaptive(
            light: UIColor(red: 0.15, green: 0.25, blue: 0.6, alpha: 1),
            dark: UIColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 1)
        )
        let textDark = adaptive(
            light: UIColor(red: 0.18, green: 0.28, blue: 0.55, alpha: 1),
            dark: UIColor(red: 0.88, green: 0.92, blue: 1.0, alpha: 1)
        )

        // Status colors
        let success = Color(red: 0.2, green: 0.7, blue: 0.3)
        let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
        let error = Color(red: 0.9, green: 0.2, blue: 0.3)
        let info = Color(red: 0.3, green: 0.7, blue: 1.0)
        let highlight = Color(red: 0.95, green: 0.5, blue: 0.2)
        let gold = Color(red: 1.0, green: 0.8, blue: 0.2)
        let xpGold = Color(red: 0.96, green: 0.71, blue: 0.25)

        // Background colors
        let backgroundLight = adaptive(
            light: UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
        )
        let backgroundMedium = adaptive(
            light: UIColor(red: 0.92, green: 0.95, blue: 0.99, alpha: 1),
            dark: UIColor(red: 0.13, green: 0.13, blue: 0.16, alpha: 1)
        )
        let backgroundGradientTop = adaptive(
            light: UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 1)
        )
        let backgroundGradientBottom = adaptive(
            light: UIColor(red: 0.75, green: 0.88, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.08, green: 0.1, blue: 0.15, alpha: 1)
        )
        let cardBackground = adaptive(
            light: UIColor(white: 1.0, alpha: 0.9),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.2, alpha: 0.9)
        )
        let sectionBackground = adaptive(
            light: UIColor(white: 1.0, alpha: 0.8),
            dark: UIColor(red: 0.17, green: 0.17, blue: 0.2, alpha: 0.8)
        )
        let chipBackground = adaptive(
            light: UIColor(white: 1.0, alpha: 0.9),
            dark: UIColor(red: 0.2, green: 0.2, blue: 0.24, alpha: 0.9)
        )

        // Accent colors
        let purple = Color(red: 0.6, green: 0.3, blue: 1.0)
        let deepOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
        let interactiveBlue = Color(red: 0.3, green: 0.5, blue: 0.8)

        // Gender colors (for noun articles)
        let genderMasculine = Color(red: 0.2, green: 0.4, blue: 0.8)
        let genderFeminine = Color(red: 0.8, green: 0.3, blue: 0.5)
        let genderNeuter = Color(red: 0.3, green: 0.7, blue: 0.4)

        // Semantic colors
        let flame = Color(red: 1.0, green: 0.45, blue: 0.2)
        let flameSubtle = adaptive(
            light: UIColor(red: 1.0, green: 0.45, blue: 0.2, alpha: 0.15),
            dark: UIColor(red: 1.0, green: 0.45, blue: 0.2, alpha: 0.2)
        )
        let levelBlue = Color(red: 0.45, green: 0.55, blue: 1.0)
        let categoryPurple = Color(red: 0.5, green: 0.3, blue: 0.8)
        let pronunciationAccent = Color(red: 0.4, green: 0.35, blue: 0.8)
        let progressTint = Color(red: 0.35, green: 0.55, blue: 0.95)
        let learningGreen = Color(red: 0.3, green: 0.7, blue: 0.45)
        let relatedAccent = Color(red: 0.55, green: 0.45, blue: 0.85)
        let posGreen = Color(red: 0.4, green: 0.6, blue: 0.2)
        let difficultyGold = Color(red: 0.8, green: 0.6, blue: 0.0)
        let audioButtonBlue = Color(red: 0.25, green: 0.45, blue: 0.85)
        let difficultyEasy = Color(red: 0.2, green: 0.7, blue: 0.3)
        let difficultyMedium = Color(red: 1.0, green: 0.6, blue: 0.2)
        let difficultyHard = Color(red: 0.9, green: 0.2, blue: 0.3)
    }
    
    // MARK: - Typography
    static let typography: TypographySystem = TypographySystem()
    
    struct TypographySystem {
        func largeTitle(weight: Font.Weight = .bold) -> Font {
            .system(.largeTitle, design: .rounded, weight: weight)
        }

        func title(weight: Font.Weight = .bold) -> Font {
            .system(.title2, design: .rounded, weight: weight)
        }

        func headline(weight: Font.Weight = .bold) -> Font {
            .system(.title3, design: .rounded, weight: weight)
        }

        func body(weight: Font.Weight = .medium) -> Font {
            .system(.body, design: .rounded, weight: weight)
        }

        func callout(weight: Font.Weight = .medium) -> Font {
            .system(.callout, design: .rounded, weight: weight)
        }

        func caption(weight: Font.Weight = .medium) -> Font {
            .system(.footnote, design: .rounded, weight: weight)
        }

        func footnote(weight: Font.Weight = .medium) -> Font {
            .system(.caption, design: .rounded, weight: weight)
        }
    }
}

// MARK: - View Extensions for Design System
extension View {
    func designSystemShadow(_ shadow: DesignTokens.ShadowToken) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.xl)
                    .fill(DesignTokens.color.cardBackground)
                    .designSystemShadow(DesignTokens.shadow.medium)
            )
    }
    
    func chipStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                    .fill(DesignTokens.color.chipBackground)
                    .designSystemShadow(DesignTokens.shadow.light)
            )
    }
    
    func sectionStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                    .fill(DesignTokens.color.sectionBackground)
                    .designSystemShadow(DesignTokens.shadow.light)
            )
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Spacing Extensions (Removed to avoid conflicts with SwiftUI)
// These extensions were causing ambiguous init conflicts
// Use DesignTokens.spacing.md directly in spacing parameters instead

#Preview {
    VStack(spacing: DesignTokens.spacing.xl) {
        Text("Design System Preview")
            .font(DesignTokens.typography.largeTitle())
            .foregroundStyle(DesignTokens.color.textPrimary)

        HStack(spacing: DesignTokens.spacing.md) {
            Text("Chip")
                .font(DesignTokens.typography.caption(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .padding(.horizontal, DesignTokens.spacing.md)
                .frame(height: 28)
                .chipStyle()

            Text("Button")
                .font(DesignTokens.typography.body(weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.spacing.lg)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                        .fill(DesignTokens.color.primary)
                        .designSystemShadow(DesignTokens.shadow.interactive)
                )
        }

        VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
            Text("Card Title")
                .font(DesignTokens.typography.headline())
                .foregroundStyle(DesignTokens.color.textPrimary)

            Text("This is a sample card content using the design system tokens for consistent spacing, typography, and visual hierarchy.")
                .font(DesignTokens.typography.body())
                .foregroundStyle(DesignTokens.color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.spacing.xl)
        .cardStyle()
    }
    .padding(DesignTokens.spacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            colors: [
                DesignTokens.color.backgroundGradientTop,
                DesignTokens.color.backgroundGradientBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
