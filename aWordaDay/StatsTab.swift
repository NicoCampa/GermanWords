//
//  StatsTab.swift
//  aWordaDay
//
//  Unified stats screen combining streak, level, and progress.
//

import SwiftUI
import SwiftData

struct StatsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @Query private var userProgress: [UserProgress]

    private var currentProgress: UserProgress {
        UserProgress.current(in: modelContext, cached: userProgress)
    }

    private var availableWords: [Word] {
        words.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }

    private var learnedWords: [Word] {
        availableWords.filter { $0.timesViewed > 0 }
    }

    private var wordsSeenToday: [Word] {
        let ids = currentProgress.dailyWordsSeenIds ?? []
        return ids.compactMap { id in
            words.first { $0.id == id }
        }.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }

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
                        // MARK: - Streak Section
                        streakSection

                        // MARK: - Level Section
                        levelSection

                        // MARK: - Learning Stats Section
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
            FirebaseAnalyticsManager.shared.logScreenView("Stats")
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: DesignTokens.spacing.lg) {
            sectionLabel(L10n.Stats.streak)

            CompactStreakWidget(
                currentStreak: currentProgress.currentStreak,
                longestStreak: currentProgress.longestStreak,
                weeklyProgress: currentProgress.weeklyProgress,
                weeklyGoal: currentProgress.weeklyGoal
            )

            MonthlyStreakCalendar(currentStreak: currentProgress.currentStreak)
        }
    }

    // MARK: - Level Section

    private var levelSection: some View {
        let nextLevelXP = currentProgress.xpForNextLevel()
        let currentLevelXP = currentProgress.xpRequiredForLevel(currentProgress.currentLevel)
        let xpIntoCurrentLevel = max(currentProgress.totalXP - currentLevelXP, 0)
        let xpNeededForNext = max(nextLevelXP - currentLevelXP, 1)
        let fraction = Double(xpIntoCurrentLevel) / Double(xpNeededForNext)

        return VStack(spacing: DesignTokens.spacing.lg) {
            sectionLabel(L10n.Stats.level)

            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Stats.levelN(currentProgress.currentLevel))
                            .font(DesignTokens.typography.largeTitle(weight: .bold))
                            .foregroundStyle(DesignTokens.color.headingPrimary)

                        Text(L10n.Stats.xpTotal(currentProgress.totalXP))
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

                    Text(L10n.Stats.xpToLevel(xpIntoCurrentLevel, xpNeededForNext, currentProgress.currentLevel + 1))
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

    // MARK: - Learned Section

    private var learnedSection: some View {
        let discoveredCount = learnedWords.count
        let masteredCount = currentProgress.totalWordsLearned

        return VStack(spacing: DesignTokens.spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
                HStack(spacing: DesignTokens.spacing.xl) {
                    statColumn(value: "\(discoveredCount)", label: L10n.Stats.discovered)
                    statColumn(value: "\(masteredCount)", label: L10n.Stats.mastered)
                    statColumn(value: "\(currentProgress.totalXP)", label: L10n.Stats.xp)
                }

                if availableWords.count > 0 {
                    let ratio = Double(discoveredCount) / Double(max(availableWords.count, 1))
                    VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                        ProgressView(value: min(max(ratio, 0), 1))
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.color.learningGreen))

                        Text(L10n.Stats.discoveredOf(discoveredCount, availableWords.count))
                            .font(DesignTokens.typography.caption())
                            .foregroundStyle(DesignTokens.color.textLight)
                    }
                }

                if !learnedWords.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                        Text(L10n.Stats.recentlyDiscovered)
                            .font(DesignTokens.typography.caption(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textSecondary)

                        FlexibleChipView(words: learnedWords.suffix(6).map(\.word))
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

    // MARK: - Helpers

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
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
