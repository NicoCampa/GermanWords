//
//  ProgressStatDetailView.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct ProgressStatDetailView: View {
    let stat: ProgressStat
    let progress: UserProgress
    let learnedWords: [Word]
    let todaysWords: [Word]
    let totalWordsAvailable: Int
    let onBrowseWords: () -> Void
    let onReviewToday: () -> Void
    let onStartPractice: () -> Void

    @Environment(\.dismiss) private var dismiss

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
                    VStack(spacing: 24) {
                        if stat != .streak {
                            summaryHeader
                        }
                        detailSections
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .padding(.top, stat == .streak ? 20 : 0)
                }
            }
            .navigationTitle(stat.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            Text(summaryTitle)
                .font(DesignTokens.typography.headline(weight: .bold))
                .foregroundStyle(DesignTokens.color.textDark)
                .frame(maxWidth: .infinity, alignment: .leading)

            summaryCard
        }
    }

    @ViewBuilder
    private var detailSections: some View {
        switch stat {
        case .streak:
            streakSection
        case .learned:
            learnedSection
        case .level:
            levelSection
        }
    }

    private var summaryTitle: String {
        switch stat {
        case .streak:
            return L10n.StatDetail.keepStreakOnFire
        case .learned:
            return L10n.StatDetail.learningAchievements
        case .level:
            return L10n.StatDetail.levelProgressOverview
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summaryHeadline)
                .font(DesignTokens.typography.largeTitle(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)

            Text(summarySubtitle)
                .font(DesignTokens.typography.callout())
                .foregroundStyle(DesignTokens.color.textSubtle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 12)
        )
    }

    private var summaryHeadline: String {
        switch stat {
        case .streak:
            return "\(progress.currentStreak)d"
        case .learned:
            return "\(learnedWords.count)"
        case .level:
            return "Lvl \(progress.currentLevel)"
        }
    }

    private var summarySubtitle: String {
        switch stat {
        case .streak:
            return L10n.StatDetail.streakSubtitle(progress.currentStreak, progress.longestStreak)
        case .learned:
            if learnedWords.isEmpty {
                return L10n.StatDetail.learnedSubtitleEmpty()
            }
            let mastered = progress.totalWordsLearned
            if mastered == 0 {
                return L10n.StatDetail.learnedSubtitleNoMastered()
            }
            return L10n.StatDetail.learnedSubtitleMastered(mastered)
        case .level:
            let nextLevelXP = progress.xpForNextLevel()
            let remaining = max(nextLevelXP - progress.totalXP, 0)
            return L10n.StatDetail.levelSubtitle(remaining, progress.currentLevel + 1)
        }
    }

    private var streakSection: some View {
        VStack(spacing: 16) {
            CompactStreakWidget(
                currentStreak: progress.currentStreak,
                longestStreak: progress.longestStreak,
                weeklyProgress: progress.weeklyProgress,
                weeklyGoal: progress.weeklyGoal
            )

            MonthlyStreakCalendar(currentStreak: progress.currentStreak)

            if !todaysWords.isEmpty {
                primaryActionButton(
                    title: L10n.StatDetail.reviewTodaysWords,
                    icon: "sparkles",
                    action: onReviewToday
                )
            }
        }
    }

    private var learnedSection: some View {
        VStack(spacing: 18) {
            let discoveredCount = learnedWords.count
            let masteredCount = progress.totalWordsLearned
            statHighlightCard(
                title: L10n.StatDetail.learningMilestones,
                rows: [
                    (L10n.StatDetail.wordsDiscovered, "\(discoveredCount)"),
                    (L10n.StatDetail.fullyLearned, "\(masteredCount)"),
                    (L10n.StatDetail.xpCollected, "\(progress.totalXP) XP")
                ]
            )

            if learnedWords.isEmpty {
                secondaryMessage(
                    text: L10n.StatDetail.discoverNewWords
                )
            } else {
                wordChipsSection(
                    title: L10n.Stats.recentlyDiscovered,
                    words: Array(learnedWords.suffix(6))
                )

                if totalWordsAvailable > 0 {
                    let ratio = Double(discoveredCount) / Double(max(totalWordsAvailable, 1))
                    progressBar(
                        title: L10n.StatDetail.collectionDiscovered,
                        progress: ratio,
                        footer: L10n.StatDetail.discoveredOfWords(discoveredCount, totalWordsAvailable)
                    )
                }

                primaryActionButton(
                    title: L10n.StatDetail.browseDiscoveredWords,
                    icon: "books.vertical",
                    action: onBrowseWords
                )
            }
        }
    }

    private var levelSection: some View {
        VStack(spacing: 18) {
            let nextLevelXP = progress.xpForNextLevel()
            let currentLevelXP = progress.xpRequiredForLevel(progress.currentLevel)
            let xpIntoCurrentLevel = max(progress.totalXP - currentLevelXP, 0)
            let xpNeededForNext = max(nextLevelXP - currentLevelXP, 1)
            let fraction = Double(xpIntoCurrentLevel) / Double(xpNeededForNext)

            statHighlightCard(
                title: L10n.StatDetail.experienceTracker,
                rows: [
                    (L10n.StatDetail.currentLevel, L10n.Stats.levelN(progress.currentLevel)),
                    (L10n.StatDetail.xpEarned, "\(progress.totalXP) XP"),
                    (L10n.StatDetail.nextLevelTarget, "\(nextLevelXP) XP total")
                ]
            )

            progressBar(
                title: L10n.StatDetail.xpProgress,
                progress: fraction,
                footer: L10n.StatDetail.xpThisLevel(xpIntoCurrentLevel, xpNeededForNext)
            )

            if let recentWord = todaysWords.last ?? learnedWords.last {
                secondaryMessage(
                    text: L10n.StatDetail.practiceBoost(recentWord.word)
                )
            }

            primaryActionButton(
                title: L10n.StatDetail.practiceWordNow,
                icon: "gamecontroller.fill",
                action: onStartPractice
            )
        }
    }

    private func statHighlightCard(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignTokens.typography.callout(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(DesignTokens.typography.caption())
                        .foregroundStyle(DesignTokens.color.textLight)
                    Spacer()
                    Text(row.1)
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textDark)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private func wordChipsSection(title: String, words: [Word]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DesignTokens.typography.callout(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            FlexibleChipView(words: words.map { $0.word })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func progressBar(title: String, progress: Double, footer: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DesignTokens.typography.callout(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            ProgressView(value: min(max(progress, 0), 1))
                .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.color.progressTint))

            Text(footer)
                .font(DesignTokens.typography.caption())
                .foregroundStyle(DesignTokens.color.textLight)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }

    private func primaryActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { performAndDismiss(action) }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(DesignTokens.typography.callout(weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        DesignTokens.color.accentBlue,
                        DesignTokens.color.primaryDark
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func secondaryMessage(text: String) -> some View {
        Text(text)
            .font(DesignTokens.typography.caption())
            .foregroundStyle(DesignTokens.color.textLight)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
    }

    private func performAndDismiss(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: action)
    }
}
