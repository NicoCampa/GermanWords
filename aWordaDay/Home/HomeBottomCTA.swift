import SwiftUI

extension ContentView {
    @ViewBuilder
    var swipeFeedHint: some View {
        if canAdvanceWordFeed {
            Label("Swipe up for the next word", systemImage: "arrow.up")
                .font(DesignTokens.typography.caption(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(DesignTokens.color.cardBackground.opacity(0.98))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
                )
                .padding(.bottom, 8)
        }
    }
}
