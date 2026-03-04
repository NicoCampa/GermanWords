//
//  ManagerProtocols.swift
//  aWordaDay
//
//  Protocol abstractions for dependency injection and testing.
//

import Foundation
import SwiftData
import UserNotifications

// MARK: - Learning Manager Protocol
protocol LearningManagerProtocol {
    func selectNextWord(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String,
        lastWordID: String?,
        preferredDifficulty: Int?,
        allowMixed: Bool
    ) -> CatalogWord?
    func getNewWordsToLearn(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String,
        limit: Int
    ) -> [CatalogWord]
    func getLearningStats(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String
    ) -> LearningStats
    func clearHistory()
    func getHistoryCount() -> Int
}

// MARK: - Notification Manager Protocol
@MainActor
protocol NotificationManagerProtocol: AnyObject {
    var isNotificationsEnabled: Bool { get set }
    func checkPermissionStatus() async -> UNAuthorizationStatus
    func requestPermission() async -> Bool
    func scheduleDailyWordNotification(with modelContext: ModelContext) async
    func cancelAllNotifications()
}

// MARK: - Analytics Manager Protocol
protocol AnalyticsManagerProtocol {
    func logWordViewed(word: String, language: String, difficulty: Int, timesViewed: Int)
    func logWordLearned(word: String, language: String, difficulty: Int, totalLearned: Int)
    func logStreakAchieved(streak: Int)
    func logLevelUp(newLevel: Int, totalXP: Int)
    func logAchievementUnlocked(achievementName: String, wordsLearned: Int)
    func logScreenView(_ screenName: String, screenClass: String?)
    func setUserProperties(level: Int, totalWordsLearned: Int, currentStreak: Int, notificationsEnabled: Bool, casesProfile: String, tenseProfile: String)
    func logError(_ error: Error, context: String)
}

// MARK: - Speech Synthesizer Protocol
@MainActor
protocol SpeechSynthesizerProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speak(text: String, language: String, style: SpeechPlaybackStyle)
    func stopSpeaking()
}

// MARK: - Error Presenter Protocol
protocol ErrorPresenterProtocol: AnyObject {
    var currentError: AppError? { get }
    var showError: Bool { get set }
    func present(_ error: Error, context: String)
    func presentMessage(_ title: String, message: String)
    func dismiss()
}

// MARK: - Word Data Loader Protocol
protocol WordDataLoaderProtocol {
    func loadBundledWords(into modelContext: ModelContext)
    func syncBundledUpdates(into modelContext: ModelContext)
    func hasWordsForLanguage(_ languageCode: String, in modelContext: ModelContext) -> Bool
    func wordCount(for languageCode: String, in modelContext: ModelContext) -> Int
}
