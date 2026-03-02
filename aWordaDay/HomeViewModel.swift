//
//  HomeViewModel.swift
//  aWordaDay
//
//  Extracted from ContentView to keep UI lean and testable.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

@MainActor
@Observable
final class HomeViewModel {
    // Observed data that the UI uses
    private(set) var todaysWord: Word?
    private(set) var wordsSeenToday: [Word] = []
    private(set) var learnedWords: [Word] = []
    
    // Internal storage
    private var modelContext: ModelContext?
    private var cachedWords: [Word] = []
    private var cachedProgress: UserProgress?
    
    private let learningManager: LearningManagerProtocol
    private let notificationManager: any NotificationManagerProtocol

    init(
        learningManager: LearningManagerProtocol = LearningManager.shared,
        notificationManager: (any NotificationManagerProtocol)? = nil
    ) {
        self.learningManager = learningManager
        self.notificationManager = notificationManager ?? NotificationManager.shared
    }
    
    // MARK: - Public Accessors
    
    var currentProgress: UserProgress {
        if let progress = cachedProgress {
            return progress
        }

        if let modelContext {
            let resolved = UserProgress.current(in: modelContext)
            cachedProgress = resolved
            return resolved
        }

        let fallback = UserProgress()
        cachedProgress = fallback
        return fallback
    }
    
    var canAccessReviewGame: Bool {
        learnedWords.count >= 3
    }
    
    var availableWords: [Word] {
        cachedWords.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }

    func setWordDirectly(_ word: Word) {
        setTodaysWord(word, animated: true)
    }

    // MARK: - Sync
    
    func sync(
        modelContext: ModelContext,
        words: [Word],
        userProgress: [UserProgress]
    ) {
        self.modelContext = modelContext
        cachedWords = words
        cachedProgress = resolveProgress(from: userProgress, in: modelContext)
        
        refreshDailyProgress()
        updateLearnedWordCollections()
        refreshDailyWordIfNeeded(force: todaysWord == nil)
        updateAnalyticsUserProperties()
    }
    
    // MARK: - Actions
    
    /// Step 1: Check limits and return the word to quiz on (the current word).
    /// Returns the word to quiz, or nil if no quiz should be shown (first word or limit reached).
    func prepareWordTransition() -> Word? {
        guard !availableWords.isEmpty else {
            setTodaysWord(nil)
            return nil
        }

        guard modelContext != nil else { return nil }

        // Return the current word to quiz on (nil if no current word yet)
        return todaysWord
    }

    /// Step 2: Called after quiz answer (or directly if no quiz is needed).
    /// Processes the previous word with quality, awards XP, then selects the next word.
    func completeWordTransition(
        word: Word?,
        quality: Int = 3,
        onXPGained: (Int) -> Void,
        onAchievement: (String) -> Void
    ) {
        guard let modelContext else { return }

        if let currentWord = word {
            let result = processWordReview(word: currentWord, quality: quality)

            if result.totalXPEarned > 0 {
                onXPGained(result.totalXPEarned)
            }
            for achievement in result.achievements {
                onAchievement(achievement)
            }

            do {
                try modelContext.save()
            } catch {
                ErrorPresenter.shared.present(error, context: "saving word progress")
            }
        }

        guard let nextWord = selectNextWord(excluding: word) else {
            setTodaysWord(nil, animated: true)
            return
        }

        currentProgress.wordOfTheDayId = nextWord.id
        currentProgress.wordOfTheDayDate = Date()
        setTodaysWord(nextWord, animated: true)
        currentProgress.recordWordViewedToday(nextWord)
        updateDailyCollections()
        do {
            try modelContext.save()
        } catch {
            ErrorPresenter.shared.present(error, context: "saving word progress")
        }
    }

    private struct WordReviewResult {
        var totalXPEarned: Int = 0
        var achievements: [String] = []
    }

    private func processWordReview(word: Word, quality: Int) -> WordReviewResult {
        var result = WordReviewResult()

        let reviewQuality = min(max(quality, 0), 5)
        let oldLevel = currentProgress.currentLevel
        let wasLearned = word.isLearned

        let viewXP = 5
        currentProgress.addXP(viewXP)
        result.totalXPEarned += viewXP

        if let streakMilestone = currentProgress.learnWord(word, quality: reviewQuality) {
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.logStreakAchieved(streak: streakMilestone)
            }
        }

        let wordText = word.word
        let lang = word.sourceLanguage
        let diff = word.difficultyLevel
        let views = word.timesViewed
        Task.detached(priority: .utility) {
            FirebaseAnalyticsManager.shared.logWordViewed(
                word: wordText,
                language: lang,
                difficulty: diff,
                timesViewed: views
            )
        }

        if !wasLearned && word.isLearned {
            // XP for newly learned words is already applied inside UserProgress.learnWord(_:).
            result.totalXPEarned += word.xpValue

            let totalLearned = currentProgress.totalWordsLearned
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.logWordLearned(
                    word: wordText,
                    language: lang,
                    difficulty: diff,
                    totalLearned: totalLearned
                )
            }
        }

        let newLevel = currentProgress.currentLevel
        if newLevel > oldLevel {
            let totalXP = currentProgress.totalXP
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.logLevelUp(newLevel: newLevel, totalXP: totalXP)
            }
            result.achievements.append("🎉 Level \(newLevel) reached!")
        }

        let wordsLearned = currentProgress.totalWordsLearned
        if wordsLearned > 0 && wordsLearned % 10 == 0 {
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.logAchievementUnlocked(
                    achievementName: "\(wordsLearned)_words_milestone",
                    wordsLearned: wordsLearned
                )
            }
            result.achievements.append("🎉 \(wordsLearned) words learned!")
        }

        return result
    }

    /// Legacy convenience that combines both steps (no quiz).
    func requestNewWord(
        onXPGained: (Int) -> Void,
        onAchievement: (String) -> Void
    ) {
        let previousWord = prepareWordTransition()
        // If prepareWordTransition returned nil and todaysWord is also nil, nothing to do
        if previousWord == nil && todaysWord == nil && !availableWords.isEmpty {
            // First word case - no quiz needed
            completeWordTransition(word: nil, quality: 3, onXPGained: onXPGained, onAchievement: onAchievement)
            return
        }
        if previousWord == nil { return }
        completeWordTransition(word: previousWord, quality: 3, onXPGained: onXPGained, onAchievement: onAchievement)
    }
    
    func refreshDailyWordIfNeeded(force: Bool = false) {
        guard !availableWords.isEmpty else {
            setTodaysWord(nil)
            return
        }

        guard modelContext != nil else {
            if todaysWord == nil, let stored = latestWordFromDailyHistory() {
                setTodaysWord(stored)
            }
            return
        }

        // Check stored word of the day from UserProgress
        if !force,
           let lastWord = latestWordFromDailyHistory(),
           let storedDate = currentProgress.wordOfTheDayDate,
           Calendar.current.isDateInToday(storedDate) {
            if todaysWord?.id != lastWord.id {
                setTodaysWord(lastWord)
                updateDailyCollections()
            }
            return
        }

        // Check if we should update (either forced or new day)
        let shouldUpdate: Bool
        if force {
            shouldUpdate = true
        } else if let storedDate = currentProgress.wordOfTheDayDate {
            shouldUpdate = !Calendar.current.isDateInToday(storedDate)
        } else {
            shouldUpdate = true
        }
        guard shouldUpdate else {
            if todaysWord == nil, let stored = latestWordFromDailyHistory() {
                setTodaysWord(stored)
            }
            return
        }

        if let newWord = selectNextWord(excluding: nil) {
            currentProgress.wordOfTheDayId = newWord.id
            currentProgress.wordOfTheDayDate = Date()
            setTodaysWord(newWord)
            currentProgress.recordWordViewedToday(newWord)
            updateDailyCollections()
        }
    }
    
    // MARK: - Private Helpers
    
    private func resolveProgress(from stored: [UserProgress], in context: ModelContext) -> UserProgress {
        UserProgress.current(in: context, cached: stored)
    }
    
    private func selectNextWord(excluding current: Word?) -> Word? {
        if let intelligentChoice = learningManager.selectNextWord(
            from: availableWords,
            language: AppLanguage.sourceCode,
            lastWord: current,
            preferredDifficulty: currentProgress.preferredDifficultyLevel,
            allowMixed: currentProgress.allowMixedDifficulty ?? false
        ) {
            return intelligentChoice
        }
        
        let filtered = availableWords.filter { $0.id != current?.id }
        guard !filtered.isEmpty else { return availableWords.first }
        
        let sortedByDifficulty = filtered.sorted { lhs, rhs in
            if lhs.difficultyLevel != rhs.difficultyLevel {
                return lhs.difficultyLevel < rhs.difficultyLevel
            }
            return lhs.timesViewed < rhs.timesViewed
        }
        
        let topChoices = Array(sortedByDifficulty.prefix(5))
        return topChoices.randomElement() ?? sortedByDifficulty.first
    }
    
    private func refreshDailyProgress() {
        currentProgress.resetDailyWordProgressIfNeeded()
        updateDailyCollections()
    }
    
    private func updateDailyCollections() {
        let ids = currentProgress.dailyWordsSeenIds ?? []
        wordsSeenToday = ids.compactMap { id in
            cachedWords.first { $0.id == id }
        }.filter { $0.sourceLanguage == AppLanguage.sourceCode }
        
        learnedWords = availableWords.filter { $0.timesViewed > 0 }
    }
    
    private func updateLearnedWordCollections() {
        learnedWords = availableWords.filter { $0.timesViewed > 0 }
        wordsSeenToday = (currentProgress.dailyWordsSeenIds ?? []).compactMap { id in
            cachedWords.first { $0.id == id }
        }.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }
    
    private func setTodaysWord(_ word: Word?, animated: Bool = false) {
        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                todaysWord = word
            }
        } else {
            todaysWord = word
        }
        WidgetDataWriter.updateWidgetData(word: word, progress: currentProgress)
    }
    
    private func latestWordFromDailyHistory() -> Word? {
        guard let lastId = currentProgress.dailyWordsSeenIds?.last else {
            return todaysWord
        }
        return cachedWords.first { $0.id == lastId }
    }
    
    private func updateAnalyticsUserProperties() {
        let manager = notificationManager
        let level = currentProgress.currentLevel
        let totalWords = currentProgress.totalWordsLearned
        let streak = currentProgress.currentStreak
        let notificationsEnabled = manager.isNotificationsEnabled
        let casesProfile = germanCaseProfile(from: cachedWords)
        let tenseProfile = germanVerbTenseProfile(from: cachedWords)
        
        Task.detached(priority: .utility) {
            FirebaseAnalyticsManager.shared.setUserProperties(
                level: level,
                totalWordsLearned: totalWords,
                currentStreak: streak,
                notificationsEnabled: notificationsEnabled,
                casesProfile: casesProfile,
                tenseProfile: tenseProfile
            )
        }

        Task {
            let status = await manager.checkPermissionStatus()
            let enabled = status == .authorized || status == .provisional
            await MainActor.run {
                manager.isNotificationsEnabled = enabled
            }
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.setUserProperties(
                    level: level,
                    totalWordsLearned: totalWords,
                    currentStreak: streak,
                    notificationsEnabled: enabled,
                    casesProfile: casesProfile,
                    tenseProfile: tenseProfile
                )
            }
        }
    }
    
    private func germanCaseProfile(from words: [Word]) -> String {
        let nouns = words.filter {
            ($0.partOfSpeech?.lowercased() == "noun") && $0.timesViewed > 0
        }
        
        guard !nouns.isEmpty else { return "cases_none" }
        
        let keywordMap: [(String, String)] = [
            ("akkusativ", "akkusativ"),
            ("dativ", "dativ"),
            ("genitiv", "genitiv"),
            ("nominativ", "nominativ")
        ]
        
        var coveredCases = Set<String>()
        for noun in nouns {
            if let notes = noun.usageNotes?.lowercased() {
                for (keyword, label) in keywordMap where notes.contains(keyword) {
                    coveredCases.insert(label)
                }
            }
        }
        
        if coveredCases.isEmpty { return "cases_intro" }
        if coveredCases.count >= 3 { return "cases_vollprofi" }
        return coveredCases.sorted().joined(separator: "_")
    }
    
    private func germanVerbTenseProfile(from words: [Word]) -> String {
        let verbs = words.filter {
            ($0.partOfSpeech?.lowercased() == "verb") && $0.timesViewed > 0
        }
        guard !verbs.isEmpty else { return "tense_none" }
        
        var tenseScores: [String: Int] = [
            "praesens": 0,
            "perfekt": 0,
            "praeteritum": 0,
            "futur": 0
        ]
        
        for verb in verbs {
            if let notes = verb.usageNotes?.lowercased() {
                if notes.contains("perfekt") { tenseScores["perfekt", default: 0] += 1 }
                if notes.contains("präteritum") || notes.contains("praeteritum") {
                    tenseScores["praeteritum", default: 0] += 1
                }
                if notes.contains("futur") { tenseScores["futur", default: 0] += 1 }
            }
            tenseScores["praesens", default: 0] += 1
        }
        
        if tenseScores.values.allSatisfy({ $0 == 0 }) {
            return "tense_intro"
        }
        
        let dominant = tenseScores.max { $0.value < $1.value }?.key ?? "praesens"
        return "tense_\(dominant)"
    }
}
