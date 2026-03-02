//
//  HomeBottomCTA.swift
//  aWordaDay
//
//  Floating "Next" FAB anchored to bottom-right of the home screen.
//

import SwiftUI

extension ContentView {
    var floatingNextButton: some View {
        Button(action: {
            HapticFeedback.medium()
            handleNewWordRequest()
            if let proxy = scrollProxy {
                withAnimation(.easeInOut(duration: 0.6)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                Text(L10n.Common.next)
                    .font(DesignTokens.typography.callout(weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.color.accentBlue,
                                DesignTokens.color.primaryDark
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: DesignTokens.color.accentBlue.opacity(0.4), radius: 16, x: 0, y: 8)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(availableWords.isEmpty)
        .opacity(availableWords.isEmpty ? 0.55 : 1.0)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}
