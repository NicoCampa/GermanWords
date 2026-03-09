//
//  AppState.swift
//  aWordaDay
//

import Foundation
import SwiftData

enum LevelProgression {
    static let maxLevel = 50

    private static let fallbackCatalogWordCount = 9_539
    private static let completionXPPerWord = 25
    private static let easingExponent = 2.0

    private static let catalogWordCount: Int = {
        let bundledCount = SQLiteCatalogStore.shared.totalWordCount(for: AppLanguage.sourceCode)
        return bundledCount > 0 ? bundledCount : fallbackCatalogWordCount
    }()

    private static let completionXP: Int = max(catalogWordCount * completionXPPerWord, maxLevel - 1)

    static let levelThresholds: [Int] = {
        guard maxLevel > 1 else { return [0] }

        var thresholds = [0]
        thresholds.reserveCapacity(maxLevel)

        for index in 1..<maxLevel {
            if index == maxLevel - 1 {
                thresholds.append(completionXP)
                continue
            }

            let progress = Double(index) / Double(maxLevel - 1)
            let rawThreshold = Int((Double(completionXP) * pow(progress, easingExponent)).rounded())
            thresholds.append(max(rawThreshold, thresholds.last! + 1))
        }

        return thresholds
    }()
}

@Model
final class AppState {
    var currentStreak: Int
    var longestStreak: Int
    var totalWordsLearned: Int
    var weeklyGoal: Int
    var weeklyProgress: Int
    var weekStartDate: Date?
    var totalXP: Int
    var currentLevel: Int
    var lastWordDate: Date?
    var dailyWordsSeenIDs: [String]
    var wordOfTheDayID: String?
    var wordOfTheDayDate: Date?
    var targetLanguageCode: String
    var selectedLanguage: String
    var selectedWordySkinID: String?
    var unlockedWordySkinIDs: [String]
    var hasCompletedOnboarding: Bool

    init() {
        currentStreak = 0
        longestStreak = 0
        totalWordsLearned = 0
        weeklyGoal = 7
        weeklyProgress = 0
        weekStartDate = nil
        totalXP = 0
        currentLevel = 1
        lastWordDate = nil
        dailyWordsSeenIDs = []
        wordOfTheDayID = nil
        wordOfTheDayDate = nil
        targetLanguageCode = TargetLanguage.english.rawValue
        selectedLanguage = AppLanguage.sourceCode
        selectedWordySkinID = nil
        unlockedWordySkinIDs = []
        hasCompletedOnboarding = false
    }

    var targetLanguage: TargetLanguage {
        get { TargetLanguage(rawValue: targetLanguageCode) ?? .english }
        set { targetLanguageCode = newValue.rawValue }
    }

    var isAtMaxLevel: Bool {
        currentLevel >= LevelProgression.maxLevel
    }

    func calculateLevel() -> Int {
        let index = LevelProgression.levelThresholds.lastIndex(where: { totalXP >= $0 }) ?? 0
        return min(index + 1, LevelProgression.maxLevel)
    }

    func xpForNextLevel() -> Int {
        let nextLevel = min(calculateLevel() + 1, LevelProgression.maxLevel)
        return xpRequiredForLevel(nextLevel)
    }

    func xpRequiredForLevel(_ level: Int) -> Int {
        let index = max(0, min(level - 1, LevelProgression.levelThresholds.count - 1))
        return LevelProgression.levelThresholds[index]
    }

    func refreshLevelFromXP() {
        currentLevel = calculateLevel()
    }

    @discardableResult
    func addXP(_ xp: Int) -> Int? {
        let oldLevel = currentLevel
        totalXP += xp
        refreshLevelFromXP()
        return currentLevel > oldLevel ? currentLevel : nil
    }

    func markOnboardingComplete() {
        hasCompletedOnboarding = true
    }

    func resetDailyWordProgressIfNeeded(now: Date = Date()) {
        guard let referenceDate = wordOfTheDayDate ?? lastWordDate else {
            dailyWordsSeenIDs = []
            return
        }

        if referenceDate < effectiveResetBoundary(for: now) {
            dailyWordsSeenIDs = []
        }
    }

    @discardableResult
    func recordWordShownToday(_ wordID: String, now: Date = Date()) -> Bool {
        resetDailyWordProgressIfNeeded(now: now)
        guard !dailyWordsSeenIDs.contains(wordID) else { return false }
        dailyWordsSeenIDs.append(wordID)
        return true
    }

    @discardableResult
    func registerLearningActivity(now: Date = Date()) -> Int? {
        trackWeeklyActivity(now: now)
        return updateStreak(now: now)
    }

    private func trackWeeklyActivity(now: Date) {
        let calendar = Calendar.current

        if let startDate = weekStartDate,
           calendar.isDate(startDate, equalTo: now, toGranularity: .weekOfYear) {
            // Same week.
        } else {
            weekStartDate = calendar.startOfDay(for: now)
            weeklyProgress = 0
        }

        if let lastDate = lastWordDate, calendar.isDate(lastDate, inSameDayAs: now) {
            return
        }

        weeklyProgress += 1
    }

    @discardableResult
    private func updateStreak(now: Date) -> Int? {
        let calendar = Calendar.current

        if let lastDate = lastWordDate {
            if calendar.isDate(lastDate, inSameDayAs: now) {
                return nil
            } else if calendar.isDateInYesterday(lastDate) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
                longestStreak = max(longestStreak, currentStreak)
            }
        } else {
            currentStreak = 1
            longestStreak = 1
        }

        lastWordDate = now
        return currentStreak > 0 && currentStreak.isMultiple(of: 7) ? currentStreak : nil
    }

    private func effectiveResetBoundary(for now: Date) -> Date {
        let calendar = Calendar.current

        var resetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        if let timeData = UserDefaults.standard.data(forKey: "daily_notification_time"),
           let time = try? JSONDecoder().decode(DateComponents.self, from: timeData) {
            resetComponents.hour = time.hour ?? NotificationDefaults.reminderHour
            resetComponents.minute = time.minute ?? NotificationDefaults.reminderMinute
        } else {
            resetComponents.hour = NotificationDefaults.reminderHour
            resetComponents.minute = NotificationDefaults.reminderMinute
        }

        let todayReset = calendar.date(from: resetComponents) ?? now
        if now < todayReset {
            return calendar.date(byAdding: .day, value: -1, to: todayReset) ?? todayReset
        }
        return todayReset
    }
}

@MainActor
extension AppState {
    static func current(in modelContext: ModelContext, cached: [AppState] = []) -> AppState {
        if let existing = cached.first {
            return existing
        }

        do {
            var descriptor = FetchDescriptor<AppState>()
            descriptor.fetchLimit = 1
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch AppState: \(error)")
            #endif
        }

        let state = AppState()
        modelContext.insert(state)

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ Failed to persist initial AppState: \(error)")
            #endif
        }

        return state
    }
}
