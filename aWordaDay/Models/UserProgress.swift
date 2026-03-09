//
//  UserProgress.swift
//  aWordaDay
//
//  Extracted from Item.swift
//

import Foundation
import SwiftData

@Model
final class UserProgress {
    var currentStreak: Int
    var longestStreak: Int
    var totalWordsLearned: Int
    var currentDifficultyLevel: Int
    var lastWordDate: Date?
    var weeklyGoal: Int
    var weeklyProgress: Int
    var weekStartDate: Date?
    var totalXP: Int
    var currentLevel: Int
    var achievements: [String]
    var dailyGoalMet: Bool
    var perfectWeeks: Int
    var selectedLanguage: String
    var isFirstLaunch: Bool
    var dailyNewWordsCount: Int?
    var dailyNewWordsDate: Date?
    var dailyWordsSeenIds: [String]?
    var selectedWordySkinID: String?
    var unlockedWordySkinIDs: [String]?
    var wordOfTheDayId: String?
    var wordOfTheDayDate: Date?
    var targetLanguageCode: String?

    /// Convenience computed property wrapping targetLanguageCode.
    var targetLanguage: TargetLanguage {
        get {
            guard let code = targetLanguageCode else { return .english }
            return TargetLanguage(rawValue: code) ?? .english
        }
        set {
            targetLanguageCode = newValue.rawValue
        }
    }

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalWordsLearned = 0
        self.currentDifficultyLevel = 1
        self.lastWordDate = nil
        self.weeklyGoal = 7
        self.weeklyProgress = 0
        self.weekStartDate = nil
        self.totalXP = 0
        self.currentLevel = 1
        self.achievements = []
        self.dailyGoalMet = false
        self.perfectWeeks = 0
        self.selectedLanguage = AppLanguage.sourceCode
        self.isFirstLaunch = true
        self.dailyNewWordsCount = 0
        self.dailyNewWordsDate = nil
        self.dailyWordsSeenIds = []
        self.selectedWordySkinID = nil
        self.unlockedWordySkinIDs = nil
        self.wordOfTheDayId = nil
        self.wordOfTheDayDate = nil
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

    /// Returns the new level if a level-up occurred, nil otherwise.
    @discardableResult
    func addXP(_ xp: Int) -> Int? {
        let oldLevel = currentLevel
        totalXP += xp
        currentLevel = calculateLevel()
        if currentLevel > oldLevel {
            return currentLevel
        }
        return nil
    }

    /// Returns the streak count if a streak milestone was reached, nil otherwise.
    @discardableResult
    func learnWord(_ word: Word, quality: Int = 3) -> Int? {
        let wasLearned = word.isLearned
        word.applyReview(quality: quality)

        // Track weekly activity before updateStreak mutates lastWordDate.
        trackDailyActivity()
        let streakMilestone = updateStreak()

        if !wasLearned && word.isLearned {
            addXP(word.xpValue)
            totalWordsLearned += 1
        }

        return streakMilestone
    }

    func trackDailyActivity() {
        let calendar = Calendar.current
        let today = Date()

        // Check for new week
        if let startDate = weekStartDate, calendar.isDate(startDate, equalTo: today, toGranularity: .weekOfYear) {
            // Same week, no reset needed
        } else {
            if weeklyProgress >= weeklyGoal && weekStartDate != nil {
                perfectWeeks += 1
            }
            weekStartDate = calendar.startOfDay(for: today)
            weeklyProgress = 0
        }

        // Don't double-count same day.
        if let lastDate = lastWordDate, calendar.isDateInToday(lastDate) { return }
        weeklyProgress += 1
    }

    func resetDailyWordProgressIfNeeded() {
        if dailyWordsSeenIds == nil {
            dailyWordsSeenIds = []
        }
        if dailyNewWordsCount == nil {
            dailyNewWordsCount = 0
        }
        let calendar = Calendar.current
        let today = Date()

        guard let lastDate = dailyNewWordsDate else {
            dailyNewWordsDate = today
            dailyNewWordsCount = dailyWordsSeenIds?.count ?? 0
            return
        }

        let resetHour: Int
        let resetMinute: Int

        if let timeData = UserDefaults.standard.data(forKey: "daily_notification_time"),
           let time = try? JSONDecoder().decode(DateComponents.self, from: timeData) {
            resetHour = time.hour ?? NotificationDefaults.reminderHour
            resetMinute = time.minute ?? NotificationDefaults.reminderMinute
        } else {
            resetHour = NotificationDefaults.reminderHour
            resetMinute = NotificationDefaults.reminderMinute
        }

        var lastResetComponents = calendar.dateComponents([.year, .month, .day], from: today)
        lastResetComponents.hour = resetHour
        lastResetComponents.minute = resetMinute

        guard let lastResetTime = calendar.date(from: lastResetComponents) else {
            return
        }

        let effectiveResetTime: Date
        if today < lastResetTime {
            effectiveResetTime = calendar.date(byAdding: .day, value: -1, to: lastResetTime) ?? lastResetTime
        } else {
            effectiveResetTime = lastResetTime
        }

        if lastDate < effectiveResetTime {
            print("✅ Resetting daily word progress (last: \(lastDate), reset time: \(effectiveResetTime))")
            dailyNewWordsDate = today
            dailyNewWordsCount = 0
            dailyWordsSeenIds = []
        }
    }

    func recordWordViewedToday(_ word: Word) {
        resetDailyWordProgressIfNeeded()
        var ids = dailyWordsSeenIds ?? []
        if !ids.contains(word.id) {
            ids.append(word.id)
        }
        dailyWordsSeenIds = ids
        dailyNewWordsCount = ids.count
        dailyNewWordsDate = Date()
    }

    func clearDailyWordProgress() {
        dailyNewWordsCount = 0
        dailyWordsSeenIds = []
        dailyNewWordsDate = Date()
    }

    /// Returns the streak count if a milestone was reached (divisible by 7), nil otherwise.
    @discardableResult
    func updateStreak() -> Int? {
        let calendar = Calendar.current
        let today = Date()

        if let lastDate = lastWordDate {
            if calendar.isDateInToday(lastDate) {
                return nil
            } else if calendar.isDateInYesterday(lastDate) {
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }

                lastWordDate = today

                if currentStreak % 7 == 0 {
                    return currentStreak
                }
                return nil
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
            longestStreak = 1
        }

        lastWordDate = today
        return nil
    }
}

@MainActor
extension UserProgress {
    /// Returns the single progress record used across the app, creating it only once if needed.
    static func current(in modelContext: ModelContext, cached: [UserProgress] = []) -> UserProgress {
        if let existing = cached.first {
            return existing
        }

        do {
            var descriptor = FetchDescriptor<UserProgress>()
            descriptor.fetchLimit = 1
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch UserProgress: \(error)")
            #endif
        }

        let progress = UserProgress()
        modelContext.insert(progress)

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ Failed to persist initial UserProgress: \(error)")
            #endif
        }

        return progress
    }
}
