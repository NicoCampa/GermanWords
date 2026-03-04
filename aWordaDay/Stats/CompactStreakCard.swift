//
//  CompactStreakCard.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct CompactStreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let weeklyProgress: Int
    let weeklyGoal: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(DesignTokens.color.flame)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(currentStreak)")
                            .font(DesignTokens.typography.largeTitle(weight: .bold))
                            .foregroundStyle(DesignTokens.color.headingPrimary)

                        Text(L10n.Stats.dayStreak)
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
                        .frame(width: 80, height: 80)
                        .shadow(color: DesignTokens.color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                    SharedCloudMascot(scale: 0.8)
                        .frame(width: 78, height: 78)
                }
            }
            .padding(20)

            HStack {
                Text(L10n.Stats.longestStreak(longestStreak))
                    .font(DesignTokens.typography.footnote())
                    .foregroundStyle(DesignTokens.color.textSubtle)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentStreak) day streak")
    }
}
