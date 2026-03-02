//
//  Word.swift
//  aWordaDay
//
//  Extracted from Item.swift
//

import Foundation
import SwiftData

// Model version 1.0

@Model
final class Word {
    var id: String
    var word: String
    var translation: String
    var examples: [String]
    var exampleTranslations: [String]
    var difficultyLevel: Int
    var cefrLevel: String?
    var curiosityFacts: String?
    var notificationMessage: String?
    var sourceLanguage: String
    var pronunciationCode: String
    var dateAdded: Date
    var isFavorite: Bool
    var timesViewed: Int
    var xpValue: Int
    var isLearned: Bool
    var article: String?
    var gender: String?
    var partOfSpeech: String?
    var plural: String?
    var relatedWords: [RelatedWordEntry]
    var usageNotes: String?
    var practiceQuiz: PracticeQuiz?
    var srsEaseFactor: Double?
    var srsIntervalDays: Int?
    var srsRepetitions: Int?
    var srsDueDate: Date?
    var conjugation: String?
    var auxiliaryVerb: String?
    var pastParticiple: String?
    var antonym: String?
    var comparative: String?
    var superlative: String?
    // Chinese translation fields (optional, populated from JSON)
    var translationZh: String?
    var exampleTranslationsZh: [String]?
    var curiosityFactsZh: String?
    var usageNotesZh: String?
    var notificationMessageZh: String?

    init(
        id: String = UUID().uuidString,
        word: String,
        translation: String,
        examples: [String] = [],
        exampleTranslations: [String] = [],
        difficultyLevel: Int,
        cefrLevel: String? = nil,
        curiosityFacts: String? = nil,
        relatedWords: [RelatedWordEntry] = [],
        notificationMessage: String? = nil,
        sourceLanguage: String = AppLanguage.sourceCode,
        pronunciationCode: String = AppLanguage.pronunciationCode,
        article: String? = nil,
        gender: String? = nil,
        partOfSpeech: String? = nil,
        plural: String? = nil,
        usageNotes: String? = nil,
        practiceQuiz: PracticeQuiz? = nil,
        conjugation: String? = nil,
        auxiliaryVerb: String? = nil,
        pastParticiple: String? = nil,
        antonym: String? = nil,
        comparative: String? = nil,
        superlative: String? = nil,
        srsEaseFactor: Double? = nil,
        srsIntervalDays: Int? = nil,
        srsRepetitions: Int? = nil,
        srsDueDate: Date? = nil,
        translationZh: String? = nil,
        exampleTranslationsZh: [String]? = nil,
        curiosityFactsZh: String? = nil,
        usageNotesZh: String? = nil,
        notificationMessageZh: String? = nil
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.examples = examples
        self.exampleTranslations = exampleTranslations
        self.difficultyLevel = difficultyLevel
        self.cefrLevel = cefrLevel
        self.curiosityFacts = curiosityFacts
        self.relatedWords = relatedWords
        self.notificationMessage = notificationMessage
        self.sourceLanguage = sourceLanguage
        self.pronunciationCode = pronunciationCode
        self.dateAdded = Date()
        self.isFavorite = false
        self.timesViewed = 0
        self.xpValue = max(difficultyLevel, 1) * 10
        self.isLearned = false
        self.article = article
        self.gender = gender
        self.partOfSpeech = partOfSpeech
        self.plural = plural
        self.usageNotes = usageNotes
        self.practiceQuiz = practiceQuiz
        self.conjugation = conjugation
        self.auxiliaryVerb = auxiliaryVerb
        self.pastParticiple = pastParticiple
        self.antonym = antonym
        self.comparative = comparative
        self.superlative = superlative
        self.srsEaseFactor = srsEaseFactor
        self.srsIntervalDays = srsIntervalDays
        self.srsRepetitions = srsRepetitions
        self.srsDueDate = srsDueDate
        self.translationZh = translationZh
        self.exampleTranslationsZh = exampleTranslationsZh
        self.curiosityFactsZh = curiosityFactsZh
        self.usageNotesZh = usageNotesZh
        self.notificationMessageZh = notificationMessageZh
    }

    func markAsViewed() {
        timesViewed += 1

        if timesViewed >= 3 && !isLearned {
            isLearned = true
        }
    }

    func applyReview(quality rawQuality: Int, reviewDate: Date = Date()) {
        let quality = min(max(rawQuality, 0), 5)
        let previousEase = srsEaseFactor ?? 2.5
        var nextEase = previousEase + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        nextEase = max(1.3, nextEase)

        var repetitions = srsRepetitions ?? (isLearned ? 2 : min(timesViewed, 2))
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
                let seededInterval = max(previousInterval, 1)
                nextInterval = Int((Double(seededInterval) * nextEase).rounded())
            }
        }

        srsEaseFactor = nextEase
        srsRepetitions = repetitions
        srsIntervalDays = max(nextInterval, 1)
        srsDueDate = Calendar.current.date(byAdding: .day, value: max(nextInterval, 1), to: reviewDate) ?? reviewDate

        timesViewed += 1
        isLearned = repetitions >= 2
    }
}

// MARK: - Helpers
extension Word {
    var isDueForReview: Bool {
        guard let dueDate = srsDueDate else { return false }
        return dueDate <= Date()
    }

    var primaryExample: String {
        examples.first ?? ""
    }

    var primaryExampleTranslation: String {
        exampleTranslations.first ?? ""
    }

    var examplePairs: [(String, String)] {
        let count = min(examples.count, exampleTranslations.count)
        return (0..<count).map { index in
            (examples[index], exampleTranslations[index])
        }
    }

    // MARK: - Localized Accessors (fall back to English if Chinese is nil)

    var localizedTranslation: String {
        if AppLanguage.activeTargetLanguage == .chinese,
           let zh = translationZh, !zh.isEmpty {
            return zh
        }
        return translation
    }

    var localizedExampleTranslations: [String] {
        if AppLanguage.activeTargetLanguage == .chinese,
           let zh = exampleTranslationsZh, !zh.isEmpty {
            return zh
        }
        return exampleTranslations
    }

    var localizedExamplePairs: [(String, String)] {
        let translations = localizedExampleTranslations
        let count = min(examples.count, translations.count)
        return (0..<count).map { index in
            (examples[index], translations[index])
        }
    }

    var localizedCuriosityFacts: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let zh = curiosityFactsZh, !zh.isEmpty {
            return zh
        }
        return curiosityFacts
    }

    var localizedUsageNotes: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let zh = usageNotesZh, !zh.isEmpty {
            return zh
        }
        return usageNotes
    }

    var localizedNotificationMessage: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let zh = notificationMessageZh, !zh.isEmpty {
            return zh
        }
        return notificationMessage
    }

    // MARK: - Display Helpers

    var displayArticle: String? {
        if let stored = article?.trimmingCharacters(in: .whitespacesAndNewlines), !stored.isEmpty {
            return stored.lowercased()
        }

        // Fallback: try to detect article embedded in the word string
        let knownArticles = ["der", "die", "das", "den", "dem", "des"]
        let components = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ")
        guard let first = components.first else { return nil }
        let firstComponent = String(first)
        if knownArticles.contains(firstComponent) {
            return firstComponent
        }
        return nil
    }

    var displayGender: String? {
        guard let rawGender = gender?.trimmingCharacters(in: .whitespacesAndNewlines), !rawGender.isEmpty else {
            return nil
        }

        let normalized = rawGender.lowercased()
        switch normalized {
        case "masculine", "maskulin", "masc", "m":
            return L10n.WordDisplay.masculine
        case "feminine", "feminin", "fem", "f":
            return L10n.WordDisplay.feminine
        case "neuter", "neutral", "neut", "n":
            return L10n.WordDisplay.neuter
        default:
            return rawGender.capitalized
        }
    }

    /// Display text for difficulty - shows CEFR level if available, otherwise Easy/Medium/Hard
    var displayDifficulty: String {
        if let cefrLevel = cefrLevel, !cefrLevel.isEmpty {
            return cefrLevel.uppercased()
        }

        switch difficultyLevel {
        case 1: return L10n.Difficulty.easy
        case 2: return L10n.Difficulty.medium
        case 3: return L10n.Difficulty.hard
        default: return L10n.Difficulty.easy
        }
    }

    var displayWord: String {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let article = displayArticle, !article.isEmpty else {
            return trimmedWord
        }

        let loweredWord = trimmedWord.lowercased()
        let loweredPrefix = article.lowercased() + " "
        if loweredWord.hasPrefix(loweredPrefix) {
            return String(trimmedWord.dropFirst(loweredPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmedWord
    }

    /// Parses the serialized conjugation string into (pronoun, form) pairs for display.
    var conjugationPairs: [(pronoun: String, form: String)] {
        guard let conjugation, !conjugation.isEmpty else { return [] }
        return conjugation.components(separatedBy: ", ").compactMap { entry in
            let parts = entry.components(separatedBy: " ")
            guard parts.count >= 2 else { return nil }
            // Handle "er/sie/es geht" (3 parts where first is multi-word pronoun)
            // Format: "ich gehe", "du gehst", "er/sie/es geht", etc.
            let pronoun = parts.dropLast().joined(separator: " ")
            let form = parts.last!
            return (pronoun, form)
        }
    }

    var antonymParts: (word: String, note: String)? {
        guard let antonym, !antonym.isEmpty else { return nil }
        let parts = antonym.components(separatedBy: " — ")
        guard parts.count >= 2 else { return (antonym, "") }
        return (parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var relatedWordsText: String? {
        guard !relatedWords.isEmpty else { return nil }

        let lines = relatedWords.map { entry -> String in
            let trimmedNote = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if trimmedNote.isEmpty {
                return "- \(entry.word)"
            } else {
                return "- \(entry.word) — \(trimmedNote)"
            }
        }

        return lines.joined(separator: "\n")
    }
}
