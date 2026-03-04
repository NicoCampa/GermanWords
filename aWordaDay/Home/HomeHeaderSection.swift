//
//  HomeHeaderSection.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    var compactStatsStrip: some View {
        let nextLevelXP = currentProgress.xpForNextLevel()
        let currentLevelXP = currentProgress.xpRequiredForLevel(currentProgress.currentLevel)
        let xpIntoCurrentLevel = max(currentProgress.totalXP - currentLevelXP, 0)
        let xpNeededForNext = max(nextLevelXP - currentLevelXP, 1)
        let fraction = Double(xpIntoCurrentLevel) / Double(xpNeededForNext)

        return Button(action: { activeSheet = .stats }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(DesignTokens.typography.footnote(weight: .bold))
                            .foregroundStyle(DesignTokens.color.textMuted)

                        Text("Learning progress")
                            .font(DesignTokens.typography.headline(weight: .bold))
                            .foregroundStyle(DesignTokens.color.headingPrimary)
                    }

                    Spacer(minLength: 0)

                    SharedCloudMascot(scale: 0.42)
                        .frame(width: 38, height: 38)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.94, green: 0.97, blue: 1.0))
                        )
                }

                HStack(spacing: 10) {
                    compactMetric(
                        icon: "flame.fill",
                        value: "\(currentProgress.currentStreak)",
                        label: L10n.Stats.dayStreak,
                        iconColor: currentProgress.currentStreak > 0 ? DesignTokens.color.flame : DesignTokens.color.textMuted
                    )

                    compactMetric(
                        icon: "star.fill",
                        value: "\(currentProgress.currentLevel)",
                        label: L10n.Stats.level,
                        iconColor: DesignTokens.color.levelBlue
                    )

                    compactMetric(
                        icon: "bolt.fill",
                        value: "\(currentProgress.totalXP)",
                        label: L10n.Stats.xp,
                        iconColor: DesignTokens.color.xpGold
                    )
                }

                VStack(alignment: .leading, spacing: 7) {
                    ProgressView(value: min(max(fraction, 0), 1))
                        .tint(DesignTokens.color.progressTint)
                        .background(Color(red: 0.9, green: 0.94, blue: 0.99), in: Capsule())

                    Text("\(xpIntoCurrentLevel) / \(xpNeededForNext) XP to level \(currentProgress.currentLevel + 1)")
                        .font(DesignTokens.typography.caption(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.95), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.16, green: 0.28, blue: 0.54).opacity(0.08), radius: 18, x: 0, y: 10)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(currentProgress.currentStreak) days, Level \(currentProgress.currentLevel), \(currentProgress.totalXP) XP")
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    private func compactMetric(icon: String, value: String, label: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(value)
                .font(DesignTokens.typography.headline(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)

            Text(label)
                .font(DesignTokens.typography.caption(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.97, green: 0.98, blue: 1.0))
        )
    }
}
