//
//  AppState.swift
//  aWordaDay
//

import Foundation
import SwiftData

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
    var preferredDifficultyLevel: Int?
    var allowMixedDifficulty: Bool
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
        preferredDifficultyLevel = nil
        allowMixedDifficulty = false
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

    private static let levelThresholds: [Int] = [
        0, 50, 120, 220, 350, 510, 700, 920, 1170, 1450,
        1760, 2110, 2490, 2900, 3340, 3810, 4310, 4840, 5400, 5990,
        6610, 7280, 7980, 8710, 9470, 10260, 11080, 11930, 12810, 13720
    ]

    func calculateLevel() -> Int {
        let index = Self.levelThresholds.lastIndex(where: { totalXP >= $0 }) ?? 0
        return min(index + 1, 30)
    }

    func xpForNextLevel() -> Int {
        let nextLevel = min(calculateLevel() + 1, 30)
        return xpRequiredForLevel(nextLevel)
    }

    func xpRequiredForLevel(_ level: Int) -> Int {
        let index = max(0, min(level - 1, Self.levelThresholds.count - 1))
        return Self.levelThresholds[index]
    }

    @discardableResult
    func addXP(_ xp: Int) -> Int? {
        let oldLevel = currentLevel
        totalXP += xp
        currentLevel = calculateLevel()
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

    func recordWordShownToday(_ wordID: String, now: Date = Date()) {
        resetDailyWordProgressIfNeeded(now: now)
        if !dailyWordsSeenIDs.contains(wordID) {
            dailyWordsSeenIDs.append(wordID)
        }
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
            resetComponents.hour = time.hour ?? 9
            resetComponents.minute = time.minute ?? 0
        } else {
            resetComponents.hour = 9
            resetComponents.minute = 0
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
