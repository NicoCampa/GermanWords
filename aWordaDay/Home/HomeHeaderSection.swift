//
//  HomeHeaderSection.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    var compactStatsStrip: some View {
        return Button(action: { activeSheet = .stats }) {
            HStack(alignment: .center, spacing: 16) {
                SharedCloudMascot(scale: 0.7)
                    .frame(width: 72, height: 72)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(DesignTokens.color.surfaceInset)
                    )

                HStack(alignment: .top, spacing: 18) {
                    compactHeaderMetric(
                        icon: "flame.fill",
                        iconColor: currentProgress.currentStreak > 0 ? DesignTokens.color.flame : DesignTokens.color.textMuted,
                        value: "\(currentProgress.currentStreak)",
                        label: L10n.Stats.dayStreak
                    )

                    compactHeaderMetric(
                        icon: "star.fill",
                        iconColor: DesignTokens.color.levelBlue,
                        value: "\(currentProgress.currentLevel)",
                        label: L10n.Stats.level
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignTokens.color.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(DesignTokens.color.surfaceStrokeStrong, lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.color.panelShadow, radius: 18, x: 0, y: 10)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(currentProgress.currentStreak) days, Level \(currentProgress.currentLevel)")
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    private func compactHeaderMetric(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.color.headingPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(label)
                .font(DesignTokens.typography.body(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .lineLimit(2)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
