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
            light: UIColor(red: 0.17, green: 0.27, blue: 0.47, alpha: 1),
            dark: UIColor(red: 0.75, green: 0.8, blue: 0.88, alpha: 1)
        )
        let textTertiary = adaptive(
            light: UIColor(red: 0.24, green: 0.35, blue: 0.56, alpha: 1),
            dark: UIColor(red: 0.72, green: 0.76, blue: 0.86, alpha: 1)
        )
        let textMuted = adaptive(
            light: UIColor(red: 0.4, green: 0.5, blue: 0.63, alpha: 1),
            dark: UIColor(red: 0.64, green: 0.69, blue: 0.79, alpha: 1)
        )
        let textLight = adaptive(
            light: UIColor(red: 0.34, green: 0.46, blue: 0.68, alpha: 1),
            dark: UIColor(red: 0.72, green: 0.77, blue: 0.87, alpha: 1)
        )
        let textSubtle = adaptive(
            light: UIColor(red: 0.3, green: 0.42, blue: 0.63, alpha: 1),
            dark: UIColor(red: 0.68, green: 0.74, blue: 0.84, alpha: 1)
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
            light: UIColor(red: 0.91, green: 0.95, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1)
        )
        let backgroundMedium = adaptive(
            light: UIColor(red: 0.86, green: 0.91, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 1)
        )
        let backgroundGradientTop = adaptive(
            light: UIColor(red: 0.77, green: 0.87, blue: 0.99, alpha: 1),
            dark: UIColor(red: 0.06, green: 0.09, blue: 0.17, alpha: 1)
        )
        let backgroundGradientBottom = adaptive(
            light: UIColor(red: 0.64, green: 0.8, blue: 0.96, alpha: 1),
            dark: UIColor(red: 0.05, green: 0.07, blue: 0.13, alpha: 1)
        )
        let cardBackground = adaptive(
            light: UIColor(white: 1.0, alpha: 0.96),
            dark: UIColor(red: 0.13, green: 0.15, blue: 0.21, alpha: 0.94)
        )
        let sectionBackground = adaptive(
            light: UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 0.96),
            dark: UIColor(red: 0.16, green: 0.19, blue: 0.26, alpha: 0.94)
        )
        let chipBackground = adaptive(
            light: UIColor(white: 1.0, alpha: 0.97),
            dark: UIColor(red: 0.19, green: 0.22, blue: 0.3, alpha: 0.94)
        )
        let surfaceElevated = adaptive(
            light: UIColor(white: 1.0, alpha: 0.97),
            dark: UIColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.92)
        )
        let surfaceInset = adaptive(
            light: UIColor(red: 0.92, green: 0.96, blue: 0.995, alpha: 1),
            dark: UIColor(red: 0.18, green: 0.21, blue: 0.29, alpha: 1)
        )
        let surfaceStroke = adaptive(
            light: UIColor(red: 0.69, green: 0.79, blue: 0.93, alpha: 1),
            dark: UIColor(red: 0.35, green: 0.42, blue: 0.57, alpha: 0.72)
        )
        let surfaceStrokeStrong = adaptive(
            light: UIColor(red: 0.78, green: 0.85, blue: 0.97, alpha: 1),
            dark: UIColor(red: 0.46, green: 0.54, blue: 0.71, alpha: 0.68)
        )
        let progressTrack = adaptive(
            light: UIColor(red: 0.78, green: 0.85, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.19, green: 0.22, blue: 0.3, alpha: 1)
        )
        let panelShadow = adaptive(
            light: UIColor(red: 0.12, green: 0.22, blue: 0.45, alpha: 0.16),
            dark: UIColor(red: 0.01, green: 0.03, blue: 0.08, alpha: 0.48)
        )
        let homeBackgroundMiddle = adaptive(
            light: UIColor(red: 0.82, green: 0.9, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.08, green: 0.11, blue: 0.19, alpha: 1)
        )
        let homeHighlight = adaptive(
            light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6),
            dark: UIColor(red: 0.34, green: 0.48, blue: 0.76, alpha: 0.28)
        )
        let homeGlassFill = adaptive(
            light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.16),
            dark: UIColor(red: 0.34, green: 0.44, blue: 0.64, alpha: 0.12)
        )
        let homeGlassStroke = adaptive(
            light: UIColor(red: 0.74, green: 0.84, blue: 0.97, alpha: 0.62),
            dark: UIColor(red: 0.5, green: 0.6, blue: 0.82, alpha: 0.18)
        )
        let homeTopOverlay = adaptive(
            light: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.22),
            dark: UIColor(red: 0.39, green: 0.49, blue: 0.67, alpha: 0.12)
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
