//
//  LearningManager.swift
//  aWordaDay
//
//  Created by Claude on 09.09.25.
//

import Foundation

class LearningManager: LearningManagerProtocol {
    static let shared = LearningManager()

    // Track recently shown words to avoid repetition
    private var recentlyShownWords: [String] = []
    private var recentlyShownWordIDs: Set<String> = []
    private let maxRecentHistory = 20 // Remember last 20 words

    private init() {
        self.recentlyShownWords = UserDefaults.standard.stringArray(forKey: "recentlyShownWordIds") ?? []
        self.recentlyShownWordIDs = Set(recentlyShownWords)
    }

    // MARK: - Word Selection

    /// Gets new words to learn (never seen before)
    func getNewWordsToLearn(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String,
        limit: Int = 5
    ) -> [CatalogWord] {
        let languageWords = words.filter { $0.sourceLanguage == language }
        let newWords = languageWords.filter { (statesByID[$0.id]?.reviewCount ?? 0) == 0 }

        // Sort new words by difficulty (easier first for beginners)
        let sortedWords = newWords.sorted { $0.difficultyLevel < $1.difficultyLevel }

        return Array(sortedWords.prefix(limit))
    }

    // MARK: - Learning Analytics

    /// Calculates learning statistics for the user
    func getLearningStats(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String
    ) -> LearningStats {
        let languageWords = words.filter { $0.sourceLanguage == language }

        let totalWords = languageWords.count
        let reviewedWords = languageWords.filter { (statesByID[$0.id]?.reviewCount ?? 0) > 0 }.count
        let learnedWords = languageWords.filter { statesByID[$0.id]?.isLearned == true }.count

        return LearningStats(
            totalWords: totalWords,
            reviewedWords: reviewedWords,
            learnedWords: learnedWords
        )
    }

    // MARK: - Smart Word Selection

    /// Selects the best word to show next based on learning algorithm with anti-repetition
    func selectNextWord(
        from words: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        language: String,
        lastWordID: String? = nil,
        preferredDifficulty: Int? = nil,
        allowMixed: Bool = false
    ) -> CatalogWord? {
        var filteredWords: [CatalogWord] = []
        filteredWords.reserveCapacity(words.count)

        for word in words {
            guard word.sourceLanguage == language else { continue }
            if let difficulty = preferredDifficulty,
               !allowMixed,
               let selectedBucket = DifficultyBucket(selection: difficulty),
               word.difficultyBucket != selectedBucket {
                continue
            }
            filteredWords.append(word)
        }

        if filteredWords.isEmpty {
            return nil
        }

        // Add last word to history if provided
        if let lastWordID {
            addToHistory(lastWordID)
        }

        var nonRecentWords: [CatalogWord] = []
        nonRecentWords.reserveCapacity(filteredWords.count)
        for word in filteredWords where !recentlyShownWordIDs.contains(word.id) {
            nonRecentWords.append(word)
        }

        let wordsToChooseFrom = nonRecentWords.isEmpty ? filteredWords : nonRecentWords

        var dueWords: [CatalogWord] = []
        var newWords: [CatalogWord] = []
        var lessViewedWords: [CatalogWord] = []

        for word in wordsToChooseFrom {
            let state = statesByID[word.id]

            if state?.isDueForReview == true {
                dueWords.append(word)
                continue
            }

            if (state?.reviewCount ?? 0) == 0 {
                newWords.append(word)
                continue
            }

            if (state?.reviewCount ?? 0) < 3 {
                lessViewedWords.append(word)
            }
        }

        if !dueWords.isEmpty {
            return selectFromCandidates(
                dueWords,
                sortedBy: { lhs, rhs in
                    let lhsDue = statesByID[lhs.id]?.srsDueDate ?? .distantFuture
                    let rhsDue = statesByID[rhs.id]?.srsDueDate ?? .distantFuture
                    return lhsDue < rhsDue
                },
                poolSize: 3
            )
        }

        if !newWords.isEmpty {
            return selectFromCandidates(newWords, sortedBy: {
                $0.difficultyBucket.rawValue < $1.difficultyBucket.rawValue
            })
        }

        if !lessViewedWords.isEmpty {
            return selectFromCandidates(lessViewedWords, sortedBy: {
                (statesByID[$0.id]?.reviewCount ?? 0) < (statesByID[$1.id]?.reviewCount ?? 0)
            })
        }

        // Strategy 3: Any available word, prioritize least viewed
        return selectFromCandidates(wordsToChooseFrom, sortedBy: {
            (statesByID[$0.id]?.reviewCount ?? 0) < (statesByID[$1.id]?.reviewCount ?? 0)
        })
    }

    /// Helper method to select from candidates with smart randomization
    /// Takes top candidates and randomly picks one to add variety
    private func selectFromCandidates(
        _ candidates: [CatalogWord],
        sortedBy areInIncreasingOrder: (CatalogWord, CatalogWord) -> Bool,
        poolSize requestedPoolSize: Int = 5
    ) -> CatalogWord? {
        guard !candidates.isEmpty else { return nil }

        // Shuffle first, then keep that randomized order for equal-priority candidates.
        let shuffledCandidates = candidates.shuffled()
        let sorted = shuffledCandidates
            .enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) {
                    return true
                }
                if areInIncreasingOrder(rhs.element, lhs.element) {
                    return false
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)

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
        recentlyShownWordIDs.insert(wordId)

        // Keep only the most recent N words
        if recentlyShownWords.count > maxRecentHistory {
            recentlyShownWords.removeFirst(recentlyShownWords.count - maxRecentHistory)
            recentlyShownWordIDs = Set(recentlyShownWords)
        }
        persistHistory()
    }

    private func persistHistory() {
        UserDefaults.standard.set(recentlyShownWords, forKey: "recentlyShownWordIds")
    }

    /// Clear the history (useful when changing language or resetting)
    func clearHistory() {
        recentlyShownWords.removeAll()
        recentlyShownWordIDs.removeAll()
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
