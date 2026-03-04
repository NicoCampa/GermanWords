//
//  UserWordState.swift
//  aWordaDay
//

import Foundation
import SwiftData

struct UserWordStateSnapshot: Hashable {
    let wordID: String
    let isFavorite: Bool
    let reviewCount: Int
    let isLearned: Bool
    let srsEaseFactor: Double?
    let srsIntervalDays: Int?
    let srsRepetitions: Int?
    let srsDueDate: Date?
    let lastReviewedAt: Date?
    let firstReviewedAt: Date?

    var isDueForReview: Bool {
        guard let srsDueDate else { return false }
        return srsDueDate <= Date()
    }

    static func empty(wordID: String) -> UserWordStateSnapshot {
        UserWordStateSnapshot(
            wordID: wordID,
            isFavorite: false,
            reviewCount: 0,
            isLearned: false,
            srsEaseFactor: nil,
            srsIntervalDays: nil,
            srsRepetitions: nil,
            srsDueDate: nil,
            lastReviewedAt: nil,
            firstReviewedAt: nil
        )
    }
}

struct UserWordReviewResult {
    let snapshot: UserWordStateSnapshot
    let becameViewed: Bool
    let becameLearned: Bool
}

@Model
final class UserWordState {
    @Attribute(.unique) var wordID: String
    var isFavorite: Bool
    var reviewCount: Int
    var isLearned: Bool
    var srsEaseFactor: Double?
    var srsIntervalDays: Int?
    var srsRepetitions: Int?
    var srsDueDate: Date?
    var lastReviewedAt: Date?
    var firstReviewedAt: Date?

    init(wordID: String) {
        self.wordID = wordID
        isFavorite = false
        reviewCount = 0
        isLearned = false
        srsEaseFactor = nil
        srsIntervalDays = nil
        srsRepetitions = nil
        srsDueDate = nil
        lastReviewedAt = nil
        firstReviewedAt = nil
    }

    var snapshot: UserWordStateSnapshot {
        UserWordStateSnapshot(
            wordID: wordID,
            isFavorite: isFavorite,
            reviewCount: reviewCount,
            isLearned: isLearned,
            srsEaseFactor: srsEaseFactor,
            srsIntervalDays: srsIntervalDays,
            srsRepetitions: srsRepetitions,
            srsDueDate: srsDueDate,
            lastReviewedAt: lastReviewedAt,
            firstReviewedAt: firstReviewedAt
        )
    }

    var isDueForReview: Bool {
        guard let srsDueDate else { return false }
        return srsDueDate <= Date()
    }

    func applyReview(quality rawQuality: Int, reviewDate: Date = Date()) -> UserWordReviewResult {
        let quality = min(max(rawQuality, 0), 5)
        let wasViewed = reviewCount > 0
        let wasLearned = isLearned
        let previousEase = srsEaseFactor ?? 2.5

        var nextEase = previousEase + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        nextEase = max(1.3, nextEase)

        var repetitions = srsRepetitions ?? (isLearned ? 2 : min(reviewCount, 2))
        let previousInterval = max(srsIntervalDays ?? (isLearned ? 3 : 0), 0)
        let nextInterval: Int

        if quality < 3 {
            repetitions = 0
            nextInterval = 1
        } else {
            repetitions += 1
            switch repetitions {
            case 1:
                nextInterval = 1
            case 2:
                nextInterval = 3
            default:
                nextInterval = Int((Double(max(previousInterval, 1)) * nextEase).rounded())
            }
        }

        srsEaseFactor = nextEase
        srsRepetitions = repetitions
        srsIntervalDays = max(nextInterval, 1)
        srsDueDate = Calendar.current.date(byAdding: .day, value: max(nextInterval, 1), to: reviewDate) ?? reviewDate
        reviewCount += 1
        isLearned = repetitions >= 2
        lastReviewedAt = reviewDate
        if firstReviewedAt == nil {
            firstReviewedAt = reviewDate
        }

        return UserWordReviewResult(
            snapshot: snapshot,
            becameViewed: !wasViewed && reviewCount > 0,
            becameLearned: !wasLearned && isLearned
        )
    }
}
