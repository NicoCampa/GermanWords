import SwiftUI

// MARK: - Collapsible Section Component
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: DesignTokens.spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.primary)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 24, height: 24)

                    Text(title)
                        .font(DesignTokens.typography.headline(weight: .bold))
                        .foregroundStyle(DesignTokens.color.headingPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(.vertical, DesignTokens.spacing.md)
                .padding(.horizontal, DesignTokens.spacing.xs)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(title). \(isExpanded ? "Expanded" : "Collapsed"). Tap to \(isExpanded ? "collapse" : "expand")")

            // Collapsible content
            if isExpanded {
                content()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                    .padding(.top, DesignTokens.spacing.sm)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
    }
}

#Preview {
    VStack(spacing: 20) {
        CollapsibleSection(
            title: "Your Progress",
            icon: "chart.line.uptrend.xyaxis",
            isExpanded: .constant(true)
        ) {
            VStack(spacing: 16) {
                Text("Progress content goes here")
                    .font(DesignTokens.typography.callout(weight: .medium))
                    .foregroundStyle(.secondary)

                HStack {
                    Spacer()
                    Text("Streak: 5 days")
                        .font(DesignTokens.typography.caption(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.primary)
                    Spacer()
                    Text("Level: 3")
                        .font(DesignTokens.typography.caption(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.success)
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .padding(.horizontal)

        CollapsibleSection(
            title: "Today's Word",
            icon: "book.fill",
            isExpanded: .constant(false)
        ) {
            Text("Word content would be here")
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding(.horizontal)
    }
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
