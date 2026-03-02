//
//  HomeNoWordsSection.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    var noWordsSection: some View {
        VStack(spacing: 18) {
            SharedCloudMascot(scale: 0.6)
                .frame(width: 90, height: 90)

            Text(L10n.Home.noWordsYet)
                .font(DesignTokens.typography.title(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)

            Text(L10n.Home.noWordsDesc)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSubtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button(action: { selectedTab = .settings }) {
                Text(L10n.Home.openSettings)
                    .font(DesignTokens.typography.callout(weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
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
                            .shadow(color: DesignTokens.color.primary.opacity(0.2), radius: 12, x: 0, y: 6)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .designSystemShadow(DesignTokens.shadow.heavy)
        )
        .padding(.horizontal, 20)
    }
}
