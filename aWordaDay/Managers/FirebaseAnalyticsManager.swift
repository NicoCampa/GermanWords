//
//  FirebaseAnalyticsManager.swift
//  aWordaDay
//
//  Created by Claude on 15.10.25.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Centralized manager for Firebase Analytics and Crashlytics
class FirebaseAnalyticsManager: AnalyticsManagerProtocol {
    static let shared = FirebaseAnalyticsManager()
    private static var isConfigured = false

    private init() {}

    // MARK: - Setup

    /// Configure Firebase only when the SDK is linked in this build.
    func configureIfAvailable() {
        #if canImport(FirebaseCore)
        guard !Self.isConfigured else { return }
        FirebaseApp.configure()
        Self.isConfigured = true
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        #endif
    }

    // MARK: - User Properties

    /// Set user properties tailored to German learning depth
    func setUserProperties(
        level: Int,
        totalWordsLearned: Int,
        currentStreak: Int,
        notificationsEnabled: Bool,
        casesProfile: String,
        tenseProfile: String
    ) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty("\(level)", forName: "user_level")
        Analytics.setUserProperty("\(totalWordsLearned)", forName: "words_learned")
        Analytics.setUserProperty("\(currentStreak)", forName: "streak")
        Analytics.setUserProperty(notificationsEnabled ? "yes" : "no", forName: "notifications_enabled")
        Analytics.setUserProperty(casesProfile, forName: "cases_profile")
        Analytics.setUserProperty(tenseProfile, forName: "tense_profile")
        #endif

        // Also set for Crashlytics for better crash context
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(level, forKey: "level")
        crashlytics.setCustomValue(totalWordsLearned, forKey: "words_learned")
        crashlytics.setCustomValue(casesProfile, forKey: "cases_profile")
        crashlytics.setCustomValue(tenseProfile, forKey: "tense_profile")
        #endif
    }

    // MARK: - Learning Events

    /// Track when a word is viewed
    func logWordViewed(word: String, language: String, difficulty: Int, timesViewed: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("word_viewed", parameters: [
            "word": word,
            "language": language,
            "difficulty_level": difficulty,
            "times_viewed": timesViewed,
            AnalyticsParameterContentType: "vocabulary"
        ])
        #endif
    }

    /// Track when user listens to pronunciation
    func logWordListened(word: String, language: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("word_listened", parameters: [
            "word": word,
            "language": language,
            AnalyticsParameterContentType: "pronunciation"
        ])
        #endif
    }

    /// Track when a word is marked as learned
    func logWordLearned(word: String, language: String, difficulty: Int, totalLearned: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("word_learned", parameters: [
            "word": word,
            "language": language,
            "difficulty_level": difficulty,
            "total_words_learned": totalLearned,
            AnalyticsParameterContentType: "achievement"
        ])
        #endif
    }

    // MARK: - User Actions

    /// Track when user requests a new word
    func logNewWordRequested(language: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("new_word_requested", parameters: [
            "language": language,
            AnalyticsParameterContentType: "button_tap"
        ])
        #endif
    }

    // MARK: - Gamification Events

    /// Track streak milestones
    func logStreakAchieved(streak: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("streak_achieved", parameters: [
            "streak_days": streak,
            AnalyticsParameterContentType: "achievement"
        ])
        #endif
    }

    /// Track level ups
    func logLevelUp(newLevel: Int, totalXP: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventLevelUp, parameters: [
            AnalyticsParameterLevel: newLevel,
            "total_xp": totalXP,
            AnalyticsParameterContentType: "achievement"
        ])
        #endif
    }

    /// Track achievements
    func logAchievementUnlocked(achievementName: String, wordsLearned: Int) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventUnlockAchievement, parameters: [
            AnalyticsParameterAchievementID: achievementName,
            "words_learned": wordsLearned,
            AnalyticsParameterContentType: "milestone"
        ])
        #endif
    }

    // MARK: - Feature Usage

    /// Track review mode usage
    func logReviewModeStarted(wordCount: Int, language: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("review_mode_started", parameters: [
            "word_count": wordCount,
            "language": language,
            AnalyticsParameterContentType: "study_session"
        ])
        #endif
    }

    /// Track settings opened
    func logSettingsOpened() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("settings_opened", parameters: [
            AnalyticsParameterContentType: "navigation"
        ])
        #endif
    }

    /// Track notification settings
    func logNotificationToggled(enabled: Bool, time: Date?) {
        #if canImport(FirebaseAnalytics)
        var params: [String: Any] = [
            "enabled": enabled,
            AnalyticsParameterContentType: "settings"
        ]

        if let time = time {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            params["notification_time"] = formatter.string(from: time)
        }

        Analytics.logEvent("notification_settings_changed", parameters: params)
        #endif
    }

    // MARK: - Onboarding

    /// Track onboarding completion
    func logOnboardingCompleted(language: String? = nil) {
        #if canImport(FirebaseAnalytics)
        var params: [String: Any] = [
            AnalyticsParameterContentType: "onboarding"
        ]

        if let language = language {
            params["selected_language"] = language
        }

        Analytics.logEvent("onboarding_completed", parameters: params)
        #endif
    }

    /// Track onboarding step
    func logOnboardingStep(step: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("onboarding_step", parameters: [
            "step_name": step,
            AnalyticsParameterContentType: "onboarding"
        ])
        #endif
    }

    // MARK: - Screen Tracking

    /// Track screen views
    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
        #endif
    }

    /// Backward-compatible overload for existing call sites.
    func logScreenView(screen screenName: String, screenClass: String? = nil) {
        logScreenView(screenName, screenClass: screenClass)
    }

    // MARK: - Error Tracking

    /// Log non-fatal errors to Crashlytics
    func logError(_ error: Error, context: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().record(error: error)
        Crashlytics.crashlytics().log("Error in \(context): \(error.localizedDescription)")
        #endif
    }

    /// Log custom message to Crashlytics
    func logMessage(_ message: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #endif
    }

    // MARK: - Session Management

    /// Track app session start
    func logAppOpened() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            AnalyticsParameterContentType: "app_lifecycle"
        ])
        #endif
    }

    /// Track first open
    func logFirstOpen() {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent("first_open", parameters: [
            AnalyticsParameterContentType: "app_lifecycle"
        ])
        #endif
    }

    // MARK: - Custom Events

    /// Log a custom event with parameters
    func logCustomEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }
}

// MARK: - Analytics Event Names (for consistency)
extension FirebaseAnalyticsManager {
    enum Event {
        static let wordViewed = "word_viewed"
        static let wordListened = "word_listened"
        static let wordLearned = "word_learned"
        static let newWordRequested = "new_word_requested"
        static let streakAchieved = "streak_achieved"
        static let reviewModeStarted = "review_mode_started"
        static let settingsOpened = "settings_opened"
        static let onboardingCompleted = "onboarding_completed"
    }

    enum Screen {
        static let home = "Home"
        static let settings = "Settings"
        static let reviewMode = "Review Mode"
        static let onboarding = "Onboarding"
        static let games = "Games"
    }
}
