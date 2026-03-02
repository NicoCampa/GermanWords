//
//  CoreLogicTests.swift
//  aWordaDayTests
//
//  Unit tests for core business logic.
//

import XCTest
import SwiftData
@testable import aWordaDay

final class UserProgressTests: XCTestCase {

    // MARK: - Level Calculation Tests

    func testLevel1AtZeroXP() {
        let progress = UserProgress()
        progress.totalXP = 0
        XCTAssertEqual(progress.calculateLevel(), 1)
    }

    func testLevel2At50XP() {
        let progress = UserProgress()
        progress.totalXP = 50
        XCTAssertEqual(progress.calculateLevel(), 2)
    }

    func testLevel30AtMaxXP() {
        let progress = UserProgress()
        progress.totalXP = 14660
        XCTAssertEqual(progress.calculateLevel(), 30)
    }

    func testLevel1At49XP() {
        let progress = UserProgress()
        progress.totalXP = 49
        XCTAssertEqual(progress.calculateLevel(), 1)
    }

    func testLevelCalculationBoundary() {
        let progress = UserProgress()
        // Test exact boundary: 120 XP should be level 3
        progress.totalXP = 120
        XCTAssertEqual(progress.calculateLevel(), 3)
        // 119 XP should still be level 2
        progress.totalXP = 119
        XCTAssertEqual(progress.calculateLevel(), 2)
    }

    // MARK: - XP Required Tests

    func testXPRequiredForLevel1() {
        let progress = UserProgress()
        XCTAssertEqual(progress.xpRequiredForLevel(1), 0)
    }

    func testXPRequiredForLevel2() {
        let progress = UserProgress()
        XCTAssertEqual(progress.xpRequiredForLevel(2), 50)
    }

    func testXPRequiredForLevel30() {
        let progress = UserProgress()
        XCTAssertEqual(progress.xpRequiredForLevel(30), 13720)
    }

    // MARK: - XP Addition Tests

    func testAddXPReturnsNewLevelOnLevelUp() {
        let progress = UserProgress()
        progress.totalXP = 45
        progress.currentLevel = 1
        let newLevel = progress.addXP(10) // 55 XP, should be level 2
        XCTAssertEqual(newLevel, 2)
        XCTAssertEqual(progress.currentLevel, 2)
    }

    func testAddXPReturnsNilWhenNoLevelUp() {
        let progress = UserProgress()
        progress.totalXP = 0
        progress.currentLevel = 1
        let newLevel = progress.addXP(5) // 5 XP, still level 1
        XCTAssertNil(newLevel)
        XCTAssertEqual(progress.currentLevel, 1)
    }

    // MARK: - Streak Tests

    func testFirstWordStartsStreak() {
        let progress = UserProgress()
        progress.currentStreak = 0
        progress.lastWordDate = nil
        _ = progress.updateStreak()
        XCTAssertEqual(progress.currentStreak, 1)
    }

    func testConsecutiveDayIncreasesStreak() {
        let progress = UserProgress()
        progress.currentStreak = 5
        progress.longestStreak = 5
        // Set last word date to yesterday
        progress.lastWordDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        _ = progress.updateStreak()
        XCTAssertEqual(progress.currentStreak, 6)
        XCTAssertEqual(progress.longestStreak, 6)
    }

    func testMissedDayResetsStreak() {
        let progress = UserProgress()
        progress.currentStreak = 10
        progress.longestStreak = 10
        // Set last word date to 3 days ago (missed yesterday)
        progress.lastWordDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        _ = progress.updateStreak()
        XCTAssertEqual(progress.currentStreak, 1)
        XCTAssertEqual(progress.longestStreak, 10) // Longest should be preserved
    }

    func testSameDayDoesNotIncreaseStreak() {
        let progress = UserProgress()
        progress.currentStreak = 5
        progress.lastWordDate = Date()
        let milestone = progress.updateStreak()
        XCTAssertNil(milestone)
        XCTAssertEqual(progress.currentStreak, 5)
    }

    func testStreakMilestoneAt7Days() {
        let progress = UserProgress()
        progress.currentStreak = 6
        progress.longestStreak = 6
        progress.lastWordDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let milestone = progress.updateStreak()
        XCTAssertEqual(milestone, 7) // 7th day should return milestone
    }

    // MARK: - Daily Reset Tests

    func testDailyProgressResetsOnNewDay() {
        let progress = UserProgress()
        progress.dailyNewWordsCount = 3
        progress.dailyWordsSeenIds = ["a", "b", "c"]
        progress.dailyNewWordsDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())

        progress.resetDailyWordProgressIfNeeded()

        XCTAssertEqual(progress.dailyNewWordsCount, 0)
        XCTAssertEqual(progress.dailyWordsSeenIds, [])
    }

    func testDailyProgressDoesNotResetSameDay() {
        let progress = UserProgress()
        progress.dailyNewWordsCount = 2
        progress.dailyWordsSeenIds = ["a", "b"]
        progress.dailyNewWordsDate = Date()

        progress.resetDailyWordProgressIfNeeded()

        XCTAssertEqual(progress.dailyNewWordsCount, 2)
        XCTAssertEqual(progress.dailyWordsSeenIds?.count, 2)
    }
}

// MARK: - SRS Algorithm Tests

final class WordSRSTests: XCTestCase {

    private func makeWord(
        word: String = "Hund",
        translation: String = "dog",
        difficulty: Int = 1,
        timesViewed: Int = 0,
        isLearned: Bool = false
    ) -> Word {
        let w = Word(word: word, translation: translation, difficultyLevel: difficulty)
        w.timesViewed = timesViewed
        w.isLearned = isLearned
        return w
    }

    func testApplyReviewQuality5IncreasesEaseFactor() {
        let word = makeWord()
        word.srsEaseFactor = 2.5
        word.srsRepetitions = 1
        word.srsIntervalDays = 1
        word.applyReview(quality: 5)

        XCTAssertGreaterThan(word.srsEaseFactor ?? 0, 2.5, "Quality 5 should increase ease factor")
        XCTAssertEqual(word.srsRepetitions, 2)
    }

    func testApplyReviewQuality0ResetsRepetitions() {
        let word = makeWord(timesViewed: 5, isLearned: true)
        word.srsEaseFactor = 2.5
        word.srsRepetitions = 4
        word.srsIntervalDays = 10
        word.applyReview(quality: 0)

        XCTAssertEqual(word.srsRepetitions, 0, "Quality < 3 should reset repetitions")
        XCTAssertEqual(word.srsIntervalDays, 1, "Quality < 3 should reset interval to 1")
    }

    func testApplyReviewQuality2ResetsRepetitions() {
        let word = makeWord(timesViewed: 5, isLearned: true)
        word.srsRepetitions = 3
        word.srsIntervalDays = 6
        word.applyReview(quality: 2)

        XCTAssertEqual(word.srsRepetitions, 0)
        XCTAssertEqual(word.srsIntervalDays, 1)
    }

    func testApplyReviewQuality3MaintainsProgress() {
        let word = makeWord(timesViewed: 3)
        word.srsEaseFactor = 2.5
        word.srsRepetitions = 2
        word.srsIntervalDays = 3
        word.applyReview(quality: 3)

        XCTAssertGreaterThan(word.srsRepetitions ?? 0, 2, "Quality >= 3 should increment repetitions")
        XCTAssertGreaterThanOrEqual(word.srsIntervalDays ?? 0, 3, "Interval should grow or stay")
    }

    func testEaseFactorNeverDropsBelowMinimum() {
        let word = makeWord()
        word.srsEaseFactor = 1.4
        word.srsRepetitions = 1
        // Apply many low-quality reviews
        for _ in 0..<10 {
            word.applyReview(quality: 0)
        }
        XCTAssertGreaterThanOrEqual(word.srsEaseFactor ?? 0, 1.3, "Ease factor should never drop below 1.3")
    }

    func testFirstReviewSetsInterval1() {
        let word = makeWord()
        word.applyReview(quality: 4)

        XCTAssertEqual(word.srsRepetitions, 1)
        XCTAssertEqual(word.srsIntervalDays, 1)
    }

    func testSecondReviewSetsInterval3() {
        let word = makeWord()
        word.srsRepetitions = 1
        word.srsIntervalDays = 1
        word.srsEaseFactor = 2.5
        word.applyReview(quality: 4)

        XCTAssertEqual(word.srsRepetitions, 2)
        XCTAssertEqual(word.srsIntervalDays, 3)
    }

    func testDueDateIsSetAfterReview() {
        let word = makeWord()
        let reviewDate = Date()
        word.applyReview(quality: 4, reviewDate: reviewDate)

        XCTAssertNotNil(word.srsDueDate)
        let interval = word.srsIntervalDays ?? 0
        let expected = Calendar.current.date(byAdding: .day, value: interval, to: reviewDate)!
        XCTAssertEqual(
            Calendar.current.startOfDay(for: word.srsDueDate!),
            Calendar.current.startOfDay(for: expected)
        )
    }

    func testTimesViewedIncrementsOnReview() {
        let word = makeWord(timesViewed: 3)
        word.applyReview(quality: 4)
        XCTAssertEqual(word.timesViewed, 4)
    }

    func testInitialXPMatchesDifficulty() {
        XCTAssertEqual(makeWord(difficulty: 1).xpValue, 10)
        XCTAssertEqual(makeWord(difficulty: 2).xpValue, 20)
        XCTAssertEqual(makeWord(difficulty: 3).xpValue, 30)
    }

    func testWordBecomesLearnedAfter3Views() {
        let word = makeWord(timesViewed: 2)
        XCTAssertFalse(word.isLearned)
        word.applyReview(quality: 4) // timesViewed becomes 3
        XCTAssertTrue(word.isLearned, "Word should become learned after 3 views")
    }

    func testQualityClamping() {
        let word = makeWord()
        word.srsEaseFactor = 2.5
        // Quality should be clamped to [0, 5]
        word.applyReview(quality: -5)
        XCTAssertGreaterThanOrEqual(word.srsEaseFactor ?? 0, 1.3)

        word.srsEaseFactor = 2.5
        word.applyReview(quality: 100)
        // Should behave like quality 5
        XCTAssertGreaterThan(word.srsEaseFactor ?? 0, 2.5)
    }
}

// MARK: - Learning Manager Tests

final class LearningManagerTests: XCTestCase {

    func testHistoryPersistsThroughClear() {
        let manager = LearningManager.shared
        // Clear first
        manager.clearHistory()
        XCTAssertEqual(manager.getHistoryCount(), 0)

        // History count should be 0 after clear
        let savedHistory = UserDefaults.standard.stringArray(forKey: "recentlyShownWordIds")
        XCTAssertTrue(savedHistory?.isEmpty ?? true)
    }

    func testSelectNextWordReturnsNilForEmptyList() {
        let manager = LearningManager.shared
        manager.clearHistory()
        let result = manager.selectNextWord(from: [], language: "de")
        XCTAssertNil(result)
    }

    func testSelectNextWordReturnsSomething() {
        let manager = LearningManager.shared
        manager.clearHistory()
        let words = [
            Word(word: "Hund", translation: "dog", difficultyLevel: 1),
            Word(word: "Katze", translation: "cat", difficultyLevel: 1),
            Word(word: "Vogel", translation: "bird", difficultyLevel: 2)
        ]
        let result = manager.selectNextWord(from: words, language: AppLanguage.sourceCode)
        XCTAssertNotNil(result)
    }

    func testSelectNextWordPrioritizesNewWords() {
        let manager = LearningManager.shared
        manager.clearHistory()

        let viewedWord = Word(word: "Alt", translation: "old", difficultyLevel: 1)
        viewedWord.timesViewed = 5

        let newWord = Word(word: "Neu", translation: "new", difficultyLevel: 1)
        newWord.timesViewed = 0

        // With only these two, the new word should be prioritized
        var selectedNew = 0
        for _ in 0..<20 {
            manager.clearHistory()
            if let result = manager.selectNextWord(from: [viewedWord, newWord], language: AppLanguage.sourceCode) {
                if result.word == "Neu" { selectedNew += 1 }
            }
        }
        // New word should be selected most of the time
        XCTAssertGreaterThan(selectedNew, 10, "New words should be prioritized over viewed words")
    }

    func testSelectNextWordRespectsLanguageFilter() {
        let manager = LearningManager.shared
        manager.clearHistory()

        let germanWord = Word(word: "Hund", translation: "dog", difficultyLevel: 1, sourceLanguage: "de")
        let frenchWord = Word(word: "Chien", translation: "dog", difficultyLevel: 1, sourceLanguage: "fr")

        let result = manager.selectNextWord(from: [germanWord, frenchWord], language: "de")
        XCTAssertEqual(result?.word, "Hund")
    }

    func testSelectNextWordRespectsDifficultyFilter() {
        let manager = LearningManager.shared
        manager.clearHistory()

        let easyWord = Word(word: "Ja", translation: "yes", difficultyLevel: 1)
        let hardWord = Word(word: "Geschwindigkeit", translation: "speed", difficultyLevel: 3)

        // Preferred difficulty 1, not mixed — should filter to ±1
        let result = manager.selectNextWord(
            from: [easyWord, hardWord],
            language: AppLanguage.sourceCode,
            preferredDifficulty: 1,
            allowMixed: false
        )
        XCTAssertEqual(result?.word, "Ja", "Should prefer words within ±1 of preferred difficulty")
    }
}
