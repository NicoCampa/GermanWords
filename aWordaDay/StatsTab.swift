//
//  StatsTab.swift
//  aWordaDay
//

import SwiftData
import SwiftUI

struct StatsTab: View {
    @Environment(\.modelContext) private var modelContext

    @State private var summary = StatsSummary(
        appState: AppState(),
        totalWordsAvailable: 0,
        discoveredCount: 0,
        recentWordLabels: []
    )

    private let statsService = StatsService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        DesignTokens.color.backgroundLight,
                        DesignTokens.color.backgroundLight
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.spacing.xl) {
                        streakSection
                        levelSection
                        learnedSection
                    }
                    .padding(.horizontal, DesignTokens.spacing.lg2)
                    .padding(.top, DesignTokens.spacing.sm)
                    .padding(.bottom, DesignTokens.spacing.xxl)
                }
            }
            .navigationTitle(L10n.Stats.stats)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            refreshSummary()
            FirebaseAnalyticsManager.shared.logScreenView("Stats")
        }
    }

    private var streakSection: some View {
        VStack(spacing: DesignTokens.spacing.lg) {
            sectionLabel(L10n.Stats.streak)

            CompactStreakCard(
                currentStreak: summary.appState.currentStreak,
                longestStreak: summary.appState.longestStreak,
                weeklyProgress: summary.appState.weeklyProgress,
                weeklyGoal: summary.appState.weeklyGoal
            )

            MonthlyStreakCalendar(currentStreak: summary.appState.currentStreak)
        }
    }

    private var levelSection: some View {
        let nextLevelXP = summary.appState.xpForNextLevel()
        let currentLevelXP = summary.appState.xpRequiredForLevel(summary.appState.currentLevel)
        let xpIntoCurrentLevel = max(summary.appState.totalXP - currentLevelXP, 0)
        let xpNeededForNext = max(nextLevelXP - currentLevelXP, 1)
        let fraction = Double(xpIntoCurrentLevel) / Double(xpNeededForNext)

        return VStack(spacing: DesignTokens.spacing.lg) {
            sectionLabel(L10n.Stats.level)

            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Stats.levelN(summary.appState.currentLevel))
                            .font(DesignTokens.typography.largeTitle(weight: .bold))
                            .foregroundStyle(DesignTokens.color.headingPrimary)

                        Text(L10n.Stats.xpTotal(summary.appState.totalXP))
                            .font(DesignTokens.typography.caption())
                            .foregroundStyle(DesignTokens.color.textLight)
                    }

                    Spacer()

                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(DesignTokens.color.levelBlue)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    ProgressView(value: min(max(fraction, 0), 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.color.progressTint))

                    Text(L10n.Stats.xpToLevel(xpIntoCurrentLevel, xpNeededForNext, summary.appState.currentLevel + 1))
                        .font(DesignTokens.typography.caption())
                        .foregroundStyle(DesignTokens.color.textLight)
                }
            }
            .padding(DesignTokens.spacing.lg2)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .designSystemShadow(DesignTokens.shadow.medium)
            )
        }
    }

    private var learnedSection: some View {
        let discoveredCount = summary.discoveredCount
        let masteredCount = summary.appState.totalWordsLearned

        return VStack(spacing: DesignTokens.spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
                HStack(spacing: DesignTokens.spacing.xl) {
                    statColumn(value: "\(discoveredCount)", label: L10n.Stats.discovered)
                    statColumn(value: "\(masteredCount)", label: L10n.Stats.mastered)
                    statColumn(value: "\(summary.appState.totalXP)", label: L10n.Stats.xp)
                }

                if summary.totalWordsAvailable > 0 {
                    let ratio = Double(discoveredCount) / Double(max(summary.totalWordsAvailable, 1))
                    VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                        ProgressView(value: min(max(ratio, 0), 1))
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.color.learningGreen))

                        Text(L10n.Stats.discoveredOf(discoveredCount, summary.totalWordsAvailable))
                            .font(DesignTokens.typography.caption())
                            .foregroundStyle(DesignTokens.color.textLight)
                    }
                }
            }
            .padding(DesignTokens.spacing.lg2)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .designSystemShadow(DesignTokens.shadow.medium)
            )
        }
    }

    private func refreshSummary() {
        summary = statsService.makeSummary(modelContext: modelContext)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.typography.headline(weight: .bold))
            .foregroundStyle(DesignTokens.color.textDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignTokens.typography.title(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)
            Text(label)
                .font(DesignTokens.typography.footnote())
                .foregroundStyle(DesignTokens.color.textLight)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    StatsTab()
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
