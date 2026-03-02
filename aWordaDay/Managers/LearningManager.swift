//
//  LearningManager.swift
//  aWordaDay
//
//  Created by Claude on 09.09.25.
//

import Foundation
import SwiftData

class LearningManager: LearningManagerProtocol {
    static let shared = LearningManager()

    // Track recently shown words to avoid repetition
    private var recentlyShownWords: [String] = []
    private let maxRecentHistory = 20 // Remember last 20 words

    private init() {
        self.recentlyShownWords = UserDefaults.standard.stringArray(forKey: "recentlyShownWordIds") ?? []
    }

    // MARK: - Word Selection

    /// Gets new words to learn (never seen before)
    func getNewWordsToLearn(from words: [Word], language: String, limit: Int = 5) -> [Word] {
        let languageWords = words.filter { $0.sourceLanguage == language }
        let newWords = languageWords.filter { $0.timesViewed == 0 }

        // Sort new words by difficulty (easier first for beginners)
        let sortedWords = newWords.sorted { $0.difficultyLevel < $1.difficultyLevel }

        return Array(sortedWords.prefix(limit))
    }

    // MARK: - Learning Analytics

    /// Calculates learning statistics for the user
    func getLearningStats(from words: [Word], language: String) -> LearningStats {
        let languageWords = words.filter { $0.sourceLanguage == language }

        let totalWords = languageWords.count
        let reviewedWords = languageWords.filter { $0.timesViewed > 0 }.count
        let learnedWords = languageWords.filter { $0.isLearned }.count

        return LearningStats(
            totalWords: totalWords,
            reviewedWords: reviewedWords,
            learnedWords: learnedWords
        )
    }

    // MARK: - Smart Word Selection

    /// Selects the best word to show next based on learning algorithm with anti-repetition
    func selectNextWord(from words: [Word], language: String, lastWord: Word? = nil, preferredDifficulty: Int? = nil, allowMixed: Bool = false) -> Word? {
        // Filter by language
        var languageWords = words.filter { $0.sourceLanguage == language }

        // Apply difficulty filter if preference is set
        if let difficulty = preferredDifficulty, !allowMixed {
            // Allow ±1 difficulty for variety while staying within user's comfort zone
            languageWords = languageWords.filter { word in
                abs(word.difficultyLevel - difficulty) <= 1
            }
        }

        if languageWords.isEmpty {
            return nil
        }

        // Add last word to history if provided
        if let lastWord = lastWord {
            addToHistory(lastWord.id)
        }

        // Exclude recently shown words to avoid repetition
        let availableWords = languageWords.filter { word in
            !recentlyShownWords.contains(word.id)
        }

        // If we've exhausted all words (shown them all recently), reset history and use all words
        let wordsToChooseFrom = availableWords.isEmpty ? languageWords : availableWords

        // Strategy 0: Prioritize words due for spaced-repetition review.
        let dueWords = wordsToChooseFrom.filter { $0.isDueForReview }
        if !dueWords.isEmpty {
            return selectFromCandidates(
                dueWords,
                sortedBy: { lhs, rhs in
                    (lhs.srsDueDate ?? .distantFuture) < (rhs.srsDueDate ?? .distantFuture)
                },
                poolSize: 3
            )
        }

        // Strategy 1: New words (never viewed) - prioritize easier ones
        let newWords = wordsToChooseFrom.filter { $0.timesViewed == 0 }
        if !newWords.isEmpty {
            return selectFromCandidates(newWords, sortedBy: { $0.difficultyLevel < $1.difficultyLevel })
        }

        // Strategy 2: Words that haven't been viewed much
        let lessViewedWords = wordsToChooseFrom.filter { $0.timesViewed < 3 }
        if !lessViewedWords.isEmpty {
            return selectFromCandidates(lessViewedWords, sortedBy: { $0.timesViewed < $1.timesViewed })
        }

        // Strategy 3: Any available word, prioritize least viewed
        return selectFromCandidates(wordsToChooseFrom, sortedBy: { $0.timesViewed < $1.timesViewed })
    }

    /// Helper method to select from candidates with smart randomization
    /// Takes top candidates and randomly picks one to add variety
    private func selectFromCandidates(_ candidates: [Word], sortedBy areInIncreasingOrder: (Word, Word) -> Bool, poolSize requestedPoolSize: Int = 5) -> Word? {
        guard !candidates.isEmpty else { return nil }

        // Sort by priority
        let sorted = candidates.sorted(by: areInIncreasingOrder)

        // Use weighted random selection from top candidates
        // This adds variety while still prioritizing important words
        let poolSize = min(candidates.count, requestedPoolSize)
        let topCandidates = Array(sorted.prefix(poolSize))

        // Weighted selection: first candidate has highest weight
        let weights = (0..<topCandidates.count).map { Double(topCandidates.count - $0) }
        let totalWeight = weights.reduce(0, +)

        let random = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0

        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random < cumulative {
                return topCandidates[index]
            }
        }

        return topCandidates.first
    }

    /// Add a word to the recently shown history
    private func addToHistory(_ wordId: String) {
        recentlyShownWords.append(wordId)

        // Keep only the most recent N words
        if recentlyShownWords.count > maxRecentHistory {
            recentlyShownWords.removeFirst(recentlyShownWords.count - maxRecentHistory)
        }
        persistHistory()
    }

    private func persistHistory() {
        UserDefaults.standard.set(recentlyShownWords, forKey: "recentlyShownWordIds")
    }

    /// Clear the history (useful when changing language or resetting)
    func clearHistory() {
        recentlyShownWords.removeAll()
        persistHistory()
    }

    /// Get count of recently shown words (for debugging/stats)
    func getHistoryCount() -> Int {
        return recentlyShownWords.count
    }

}

// MARK: - Learning Statistics Model

struct LearningStats {
    let totalWords: Int
    let reviewedWords: Int
    let learnedWords: Int

    var progressPercentage: Double {
        return totalWords > 0 ? Double(learnedWords) / Double(totalWords) : 0.0
    }
}
