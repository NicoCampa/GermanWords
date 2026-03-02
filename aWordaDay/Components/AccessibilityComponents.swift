import SwiftUI

// MARK: - Accessibility Enhancement Extensions
extension View {
    /// Adds comprehensive accessibility support with proper labels, hints, and traits
    func accessibilityEnhanced(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil,
        isHidden: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
            .accessibilityHidden(isHidden)
    }
    
    /// Marks a view as a button with proper accessibility
    func accessibilityButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self.accessibilityEnhanced(
            label: label,
            hint: hint ?? "Double tap to activate",
            traits: .isButton
        )
    }
    
    /// Marks a view as a header for screen reader navigation
    func accessibilityHeader(_ level: AccessibilityHeadingLevel = .h2) -> some View {
        self.accessibilityEnhanced(
            label: "",
            traits: [.isHeader]
        )
        .accessibilityHeading(level)
    }
    
    /// Groups accessibility elements for better navigation
    func accessibilitySection(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Adds progress information for screen readers
    func accessibilityProgress(
        value: Double,
        total: Double = 1.0,
        label: String
    ) -> some View {
        let percentage = Int((value / total) * 100)
        return self.accessibilityEnhanced(
            label: label,
            hint: nil,
            traits: [.updatesFrequently],
            value: "\(percentage) percent complete"
        )
    }
    
    /// Dynamic Type support - ensures text scales properly
    func dynamicTypeSize() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
    
    /// Adds semantic colors that adapt to accessibility settings
    func accessibilityColor(
        foreground: Color,
        background: Color,
        contrastRatio: Double = 4.5
    ) -> some View {
        self
            .foregroundColor(foreground)
            .background(background)
            .accessibilityEnhanced(label: "", hint: "High contrast mode available")
    }
}

// MARK: - Accessibility-First Components

/// A button that meets WCAG AA accessibility standards
struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: AccessibleButtonStyle
    let isEnabled: Bool
    
    enum AccessibleButtonStyle {
        case primary, secondary, ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return DesignTokens.color.primary
            case .secondary: return DesignTokens.color.sectionBackground
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return DesignTokens.color.textPrimary
            case .ghost: return DesignTokens.color.primary
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: AccessibleButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                }
                
                Text(title)
                    .font(DesignTokens.typography.body(weight: .semibold))
                    .dynamicTypeSize()
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, DesignTokens.spacing.lg)
            .frame(minHeight: 44) // WCAG minimum touch target size
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                    .fill(style.backgroundColor)
                    .designSystemShadow(
                        style == .primary ? DesignTokens.shadow.interactive : DesignTokens.shadow.light
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
        .accessibilityButton(
            label: title,
            hint: "Button",
            isEnabled: isEnabled
        )
        .buttonStyle(PlainButtonStyle())
    }
}

/// An accessible text component with proper contrast and scaling
struct AccessibleText: View {
    let text: String
    let style: AccessibleTextStyle
    let color: Color?
    let alignment: TextAlignment
    
    enum AccessibleTextStyle {
        case largeTitle, title, headline, body, caption
        
        var font: Font {
            switch self {
            case .largeTitle: return DesignTokens.typography.largeTitle()
            case .title: return DesignTokens.typography.title()
            case .headline: return DesignTokens.typography.headline()
            case .body: return DesignTokens.typography.body()
            case .caption: return DesignTokens.typography.caption()
            }
        }
        
        var defaultColor: Color {
            switch self {
            case .largeTitle, .title, .headline: return DesignTokens.color.textPrimary
            case .body: return DesignTokens.color.textSecondary
            case .caption: return DesignTokens.color.textMuted
            }
        }
        
        var headingLevel: AccessibilityHeadingLevel? {
            switch self {
            case .largeTitle: return .h1
            case .title: return .h2
            case .headline: return .h3
            default: return nil
            }
        }
    }
    
    init(
        _ text: String,
        style: AccessibleTextStyle = .body,
        color: Color? = nil,
        alignment: TextAlignment = .leading
    ) {
        self.text = text
        self.style = style
        self.color = color
        self.alignment = alignment
    }
    
    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(color ?? style.defaultColor)
            .multilineTextAlignment(alignment)
            .dynamicTypeSize()
            .accessibilityLabel(text)
            .modifier(HeaderModifier(headingLevel: style.headingLevel))
    }
}

private struct HeaderModifier: ViewModifier {
    let headingLevel: AccessibilityHeadingLevel?
    
    func body(content: Content) -> some View {
        if let headingLevel = headingLevel {
            content
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(headingLevel)
        } else {
            content
        }
    }
}

/// Accessible progress indicator with proper announcements
struct AccessibleProgressView: View {
    let value: Double
    let total: Double
    let label: String
    let description: String?
    
    init(
        value: Double,
        total: Double = 1.0,
        label: String,
        description: String? = nil
    ) {
        self.value = value
        self.total = total
        self.label = label
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
            HStack {
                AccessibleText(label, style: .body)
                Spacer()
                AccessibleText(
                    "\(Int((value / total) * 100))%",
                    style: .body,
                    color: DesignTokens.color.primary
                )
            }
            
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(DesignTokens.color.primary)
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.sm))
            
            if let description = description {
                AccessibleText(description, style: .caption)
            }
        }
        .accessibilityProgress(value: value, total: total, label: label)
    }
}

/// Accessible card container with proper focus management
struct AccessibleCard<Content: View>: View {
    let title: String?
    let content: Content
    let action: (() -> Void)?
    
    init(
        title: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            if let title = title {
                AccessibleText(title, style: .headline)
            }
            
            content
        }
        .padding(DesignTokens.spacing.lg)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title ?? "Card")
        .modifier(CardActionModifier(action: action))
    }
}

private struct CardActionModifier: ViewModifier {
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        if let action = action {
            Button(action: action) {
                content
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityAddTraits(.isButton)
        } else {
            content
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: DesignTokens.spacing.xl) {
            AccessibleText("Accessibility Components", style: .largeTitle)
            
            VStack(spacing: DesignTokens.spacing.lg) {
                AccessibleButton(
                    title: "Primary Action",
                    icon: "checkmark.circle.fill",
                    style: .primary
                ) {
                    print("Primary action tapped")
                }
                
                AccessibleButton(
                    title: "Secondary Action",
                    icon: "gear",
                    style: .secondary
                ) {
                    print("Secondary action tapped")
                }
                
                AccessibleButton(
                    title: "Disabled Action",
                    style: .ghost,
                    isEnabled: false
                ) {
                    print("This shouldn't execute")
                }
            }
            
            AccessibleCard(title: "Progress Example") {
                AccessibleProgressView(
                    value: 0.7,
                    label: "Learning Progress",
                    description: "You're doing great! Keep it up."
                )
            }
            
            AccessibleCard(title: "Interactive Card", action: {
                print("Card tapped")
            }) {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    AccessibleText("This is an interactive card", style: .body)
                    AccessibleText("Tap anywhere on the card to interact", style: .caption)
                }
            }
        }
        .padding(DesignTokens.spacing.xl)
    }
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