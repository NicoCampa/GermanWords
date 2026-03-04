//
//  HomeViewModel.swift
//  aWordaDay
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    private(set) var todaysWord: LearnWordPayload?
    private(set) var availableWordCount: Int = 0

    private var modelContext: ModelContext?
    private var candidatePool: [CatalogWord] = []
    private var stateByID: [String: UserWordStateSnapshot] = [:]
    private var cachedAppState: AppState?
    private var lastAnalyticsSnapshot: AnalyticsSnapshot?
    private var hasLoadedNotificationPermission = false
    private var lastLoadedDifficulty: Int?
    private var lastLoadedAllowMixed = false
    private var lastLoadedLanguage = AppLanguage.sourceCode

    private let learnService: LearnService
    private let catalogStore: CatalogStoreProtocol
    private let userStateStore: UserStateStoreProtocol
    private let notificationManager: any NotificationManagerProtocol

    init(
        learnService: LearnService = LearnService(),
        catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared,
        userStateStore: UserStateStoreProtocol? = nil,
        notificationManager: (any NotificationManagerProtocol)? = nil
    ) {
        self.learnService = learnService
        self.catalogStore = catalogStore
        self.userStateStore = userStateStore ?? SwiftDataUserStateStore()
        self.notificationManager = notificationManager ?? NotificationManager.shared
    }

    var currentProgress: AppState {
        if let cachedAppState {
            return cachedAppState
        }

        guard let modelContext else {
            let fallback = AppState()
            cachedAppState = fallback
            return fallback
        }

        let resolved = userStateStore.loadAppState(in: modelContext)
        cachedAppState = resolved
        return resolved
    }

    func sync(modelContext: ModelContext) {
        self.modelContext = modelContext
        cachedAppState = userStateStore.loadAppState(in: modelContext)
        reloadUserStateSnapshots()
        let didReloadCandidatePool = reloadCandidatePoolIfNeeded(force: candidatePool.isEmpty)
        availableWordCount = candidatePool.count
        currentProgress.resetDailyWordProgressIfNeeded()
        refreshDailyWordIfNeeded(force: todaysWord == nil || didReloadCandidatePool)
        updateAnalyticsUserProperties()
    }

    func requestNewWord(
        onXPGained: (Int) -> Void,
        onAchievement: (String) -> Void
    ) {
        guard availableWordCount > 0, let modelContext else {
            todaysWord = nil
            return
        }

        var totalXPEarned = 0

        if let current = todaysWord {
            let reviewResult = userStateStore.saveWordReview(
                in: modelContext,
                wordID: current.id,
                quality: 3,
                date: Date()
            )
            stateByID[current.id] = reviewResult.snapshot

            totalXPEarned += 5
            if let newLevel = currentProgress.addXP(5) {
                let totalXP = currentProgress.totalXP
                onAchievement("🎉 Level \(newLevel) reached!")
                Task.detached(priority: .utility) {
                    FirebaseAnalyticsManager.shared.logLevelUp(newLevel: newLevel, totalXP: totalXP)
                }
            }

            if let streakMilestone = currentProgress.registerLearningActivity() {
                Task.detached(priority: .utility) {
                    FirebaseAnalyticsManager.shared.logStreakAchieved(streak: streakMilestone)
                }
            }

            if reviewResult.becameLearned {
                let masteryXP = max(current.difficultyLevel, 1) * 10
                totalXPEarned += masteryXP
                if let newLevel = currentProgress.addXP(masteryXP) {
                    let totalXP = currentProgress.totalXP
                    onAchievement("🎉 Level \(newLevel) reached!")
                    Task.detached(priority: .utility) {
                        FirebaseAnalyticsManager.shared.logLevelUp(newLevel: newLevel, totalXP: totalXP)
                    }
                }
                currentProgress.totalWordsLearned += 1

                let learnedCount = currentProgress.totalWordsLearned
                Task.detached(priority: .utility) {
                    FirebaseAnalyticsManager.shared.logWordLearned(
                        word: current.word,
                        language: current.sourceLanguage,
                        difficulty: current.difficultyLevel,
                        totalLearned: learnedCount
                    )
                }

                if learnedCount.isMultiple(of: 10) {
                    onAchievement("🎉 \(learnedCount) words learned!")
                }
            }

            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.logWordViewed(
                    word: current.word,
                    language: current.sourceLanguage,
                    difficulty: current.difficultyLevel,
                    timesViewed: reviewResult.snapshot.reviewCount
                )
            }
        }

        guard let nextWord = selectNextWord(excluding: todaysWord?.id) else {
            todaysWord = nil
            persistChangesIfNeeded(modelContext: modelContext)
            return
        }

        currentProgress.wordOfTheDayID = nextWord.id
        currentProgress.wordOfTheDayDate = Date()
        currentProgress.recordWordShownToday(nextWord.id)

        if totalXPEarned > 0 {
            onXPGained(totalXPEarned)
        }

        todaysWord = learnService.makePayload(wordID: nextWord.id, statesByID: stateByID)
        persistChangesIfNeeded(modelContext: modelContext)
        updateAnalyticsUserProperties()
    }

    func presentWord(id wordID: String, markAsShown: Bool = true) {
        guard let modelContext else { return }
        reloadUserStateSnapshots()

        guard let payload = learnService.makePayload(wordID: wordID, statesByID: stateByID) else { return }

        if markAsShown {
            currentProgress.wordOfTheDayID = wordID
            currentProgress.wordOfTheDayDate = Date()
            currentProgress.recordWordShownToday(wordID)
        }

        todaysWord = payload
        persistChangesIfNeeded(modelContext: modelContext)
        updateAnalyticsUserProperties()
    }

    func refreshDailyWordIfNeeded(force: Bool = false) {
        guard availableWordCount > 0, let modelContext else {
            todaysWord = nil
            return
        }

        let appState = currentProgress
        appState.resetDailyWordProgressIfNeeded()

        if !force,
           let storedWordID = appState.wordOfTheDayID,
           let storedDate = appState.wordOfTheDayDate,
           Calendar.current.isDateInToday(storedDate) {
            if todaysWord?.id != storedWordID {
                todaysWord = learnService.makePayload(wordID: storedWordID, statesByID: stateByID)
            }
            return
        }

        guard let nextWord = selectNextWord(excluding: nil) else {
            todaysWord = nil
            persistChangesIfNeeded(modelContext: modelContext)
            return
        }

        appState.wordOfTheDayID = nextWord.id
        appState.wordOfTheDayDate = Date()
        appState.recordWordShownToday(nextWord.id)
        todaysWord = learnService.makePayload(wordID: nextWord.id, statesByID: stateByID)
        persistChangesIfNeeded(modelContext: modelContext)
        updateAnalyticsUserProperties()
    }

    private func selectNextWord(excluding currentWordID: String?) -> CatalogWord? {
        let pool = candidatePool.filter { $0.id != currentWordID }
        let context = LearnSelectionContext(
            currentWordID: currentWordID,
            preferredDifficulty: currentProgress.preferredDifficultyLevel,
            allowMixedDifficulty: currentProgress.allowMixedDifficulty,
            recentWordIDs: [],
            todaySeenIDs: currentProgress.dailyWordsSeenIDs
        )
        return learnService.selectNextWord(candidates: pool, statesByID: stateByID, context: context)
    }

    private func reloadUserStateSnapshots() {
        guard let modelContext else { return }
        stateByID = Dictionary(
            uniqueKeysWithValues: userStateStore
                .loadWordStates(in: modelContext)
                .map { ($0.wordID, $0.snapshot) }
        )
    }

    @discardableResult
    private func reloadCandidatePoolIfNeeded(force: Bool) -> Bool {
        let preferredDifficulty = currentProgress.preferredDifficultyLevel
        let allowMixed = currentProgress.allowMixedDifficulty
        let language = AppLanguage.sourceCode
        let needsReload = force
            || preferredDifficulty != lastLoadedDifficulty
            || allowMixed != lastLoadedAllowMixed
            || language != lastLoadedLanguage

        guard needsReload else { return false }

        candidatePool = learnService.loadCandidatePool(
            language: language,
            preferredDifficulty: preferredDifficulty,
            allowMixedDifficulty: allowMixed
        )
        availableWordCount = candidatePool.count
        lastLoadedDifficulty = preferredDifficulty
        lastLoadedAllowMixed = allowMixed
        lastLoadedLanguage = language
        return true
    }

    private func persistChangesIfNeeded(modelContext: ModelContext) {
        guard modelContext.hasChanges else { return }
        do {
            try modelContext.save()
        } catch {
            ErrorPresenter.shared.present(error, context: "saving app state")
        }
    }

    private struct AnalyticsSnapshot: Equatable {
        let level: Int
        let totalWordsLearned: Int
        let currentStreak: Int
        let notificationsEnabled: Bool
        let viewedWordCount: Int
        let casesProfile: String
        let tenseProfile: String
    }

    private func updateAnalyticsUserProperties() {
        let viewedStates = stateByID.values.filter { $0.reviewCount > 0 }
        let viewedWordDetails = catalogStore.fetchWords(ids: viewedStates.map(\.wordID))

        let snapshot = AnalyticsSnapshot(
            level: currentProgress.currentLevel,
            totalWordsLearned: currentProgress.totalWordsLearned,
            currentStreak: currentProgress.currentStreak,
            notificationsEnabled: notificationManager.isNotificationsEnabled,
            viewedWordCount: viewedStates.count,
            casesProfile: germanCaseProfile(from: viewedWordDetails),
            tenseProfile: germanVerbTenseProfile(from: viewedWordDetails)
        )

        if snapshot != lastAnalyticsSnapshot {
            lastAnalyticsSnapshot = snapshot
            Task.detached(priority: .utility) {
                FirebaseAnalyticsManager.shared.setUserProperties(
                    level: snapshot.level,
                    totalWordsLearned: snapshot.totalWordsLearned,
                    currentStreak: snapshot.currentStreak,
                    notificationsEnabled: snapshot.notificationsEnabled,
                    casesProfile: snapshot.casesProfile,
                    tenseProfile: snapshot.tenseProfile
                )
            }
        }

        if !hasLoadedNotificationPermission {
            hasLoadedNotificationPermission = true
            Task {
                let status = await notificationManager.checkPermissionStatus()
                let enabled = status == .authorized || status == .provisional
                await MainActor.run {
                    notificationManager.isNotificationsEnabled = enabled
                    updateAnalyticsUserProperties()
                }
            }
        }
    }

    private func germanCaseProfile(from words: [CatalogWordDetail]) -> String {
        let nouns = words.filter { $0.partOfSpeech?.lowercased() == "noun" }
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

    private func germanVerbTenseProfile(from words: [CatalogWordDetail]) -> String {
        let verbs = words.filter { $0.partOfSpeech?.lowercased() == "verb" }
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

        return "tense_\(tenseScores.max(by: { $0.value < $1.value })?.key ?? "praesens")"
    }
}
