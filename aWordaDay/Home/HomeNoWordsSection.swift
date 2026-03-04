//
//  HomeNoWordsSection.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    var noWordsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.96),
                                    Color(red: 0.91, green: 0.96, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    SharedCloudMascot(scale: 0.56)
                        .frame(width: 72, height: 72)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Home.noWordsYet)
                        .font(DesignTokens.typography.title(weight: .bold))
                        .foregroundStyle(DesignTokens.color.headingPrimary)

                    Text(L10n.Home.noWordsDesc)
                        .font(DesignTokens.typography.callout(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: { selectedTab = .settings }) {
                HStack(spacing: 10) {
                    Text(L10n.Home.openSettings)
                        .font(DesignTokens.typography.callout(weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .black))
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
                        .shadow(color: DesignTokens.color.primary.opacity(0.24), radius: 14, x: 0, y: 8)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.18, green: 0.35, blue: 0.7).opacity(0.12), radius: 24, x: 0, y: 14)
        )
        .padding(.horizontal, 20)
    }
}
