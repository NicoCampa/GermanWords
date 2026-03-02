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
            VStack(spacing: 0) {
                // Top row: Streak + Mascot
                HStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(currentProgress.currentStreak > 0 ? DesignTokens.color.flame : DesignTokens.color.textMuted)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(currentProgress.currentStreak)")
                                .font(DesignTokens.typography.largeTitle(weight: .bold))
                                .foregroundStyle(DesignTokens.color.headingPrimary)

                            Text("day streak")
                                .font(DesignTokens.typography.caption(weight: .semibold))
                                .foregroundStyle(DesignTokens.color.textLight)
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.color.backgroundLight,
                                        DesignTokens.color.cardBackground
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: DesignTokens.color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                        SharedCloudMascot(scale: 0.7)
                            .frame(width: 68, height: 68)
                    }
                }
                .padding(20)

                // Divider
                Rectangle()
                    .fill(DesignTokens.color.textMuted.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Bottom row: Level + XP + Progress
                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(DesignTokens.color.levelBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Level \(currentProgress.currentLevel)")
                                    .font(DesignTokens.typography.callout(weight: .bold))
                                    .foregroundStyle(DesignTokens.color.headingPrimary)
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(DesignTokens.color.xpGold)
                            Text("\(currentProgress.totalXP) XP")
                                .font(DesignTokens.typography.callout(weight: .bold))
                                .foregroundStyle(DesignTokens.color.headingPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: min(max(fraction, 0), 1))
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.color.progressTint))

                        Text("\(xpIntoCurrentLevel) / \(xpNeededForNext) XP to level \(currentProgress.currentLevel + 1)")
                            .font(DesignTokens.typography.caption())
                            .foregroundStyle(DesignTokens.color.textLight)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(currentProgress.currentStreak) days, Level \(currentProgress.currentLevel), \(currentProgress.totalXP) XP")
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

}
