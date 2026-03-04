//
//  CatalogModels.swift
//  aWordaDay
//

import Foundation

protocol WordDisplayable {
    var id: String { get }
    var word: String { get }
    var translation: String { get }
    var translationZh: String? { get }
    var examples: [String] { get }
    var exampleTranslations: [String] { get }
    var exampleTranslationsZh: [String]? { get }
    var difficultyLevel: Int { get }
    var cefrLevel: String? { get }
    var curiosityFacts: String? { get }
    var curiosityFactsZh: String? { get }
    var notificationMessage: String? { get }
    var notificationMessageZh: String? { get }
    var sourceLanguage: String { get }
    var pronunciationCode: String { get }
    var dateAdded: Date { get }
    var article: String? { get }
    var gender: String? { get }
    var partOfSpeech: String? { get }
    var plural: String? { get }
    var relatedWords: [RelatedWordEntry] { get }
    var usageNotes: String? { get }
    var usageNotesZh: String? { get }
    var practiceQuiz: PracticeQuiz? { get }
    var conjugation: String? { get }
    var auxiliaryVerb: String? { get }
    var pastParticiple: String? { get }
    var antonym: String? { get }
    var comparative: String? { get }
    var superlative: String? { get }
}

struct CatalogWord: Identifiable, Hashable {
    let id: String
    let word: String
    let translation: String
    let sourceLanguage: String
    let pronunciationCode: String
    let difficultyLevel: Int
    let cefrLevel: String?
    let partOfSpeech: String?
    let usageNotes: String?
    let dateAdded: Date

    var difficultyBucket: DifficultyBucket {
        DifficultyBucket.from(cefrLevel: cefrLevel, fallbackDifficultyLevel: difficultyLevel)
    }
}

struct CatalogWordDetail: Identifiable, Hashable, WordDisplayable {
    let id: String
    let word: String
    let translation: String
    let translationZh: String?
    let examples: [String]
    let exampleTranslations: [String]
    let exampleTranslationsZh: [String]?
    let difficultyLevel: Int
    let cefrLevel: String?
    let curiosityFacts: String?
    let curiosityFactsZh: String?
    let notificationMessage: String?
    let notificationMessageZh: String?
    let sourceLanguage: String
    let pronunciationCode: String
    let dateAdded: Date
    let article: String?
    let gender: String?
    let partOfSpeech: String?
    let plural: String?
    let relatedWords: [RelatedWordEntry]
    let usageNotes: String?
    let usageNotesZh: String?
    let practiceQuiz: PracticeQuiz?
    let conjugation: String?
    let auxiliaryVerb: String?
    let pastParticiple: String?
    let antonym: String?
    let comparative: String?
    let superlative: String?

    var summary: CatalogWord {
        CatalogWord(
            id: id,
            word: word,
            translation: translation,
            sourceLanguage: sourceLanguage,
            pronunciationCode: pronunciationCode,
            difficultyLevel: difficultyLevel,
            cefrLevel: cefrLevel,
            partOfSpeech: partOfSpeech,
            usageNotes: usageNotes,
            dateAdded: dateAdded
        )
    }
}

struct BrowseWordRow: Identifiable, Hashable, WordDisplayable {
    let detail: CatalogWordDetail
    let state: UserWordStateSnapshot

    var id: String { detail.id }
    var word: String { detail.word }
    var translation: String { detail.translation }
    var translationZh: String? { detail.translationZh }
    var examples: [String] { detail.examples }
    var exampleTranslations: [String] { detail.exampleTranslations }
    var exampleTranslationsZh: [String]? { detail.exampleTranslationsZh }
    var difficultyLevel: Int { detail.difficultyLevel }
    var cefrLevel: String? { detail.cefrLevel }
    var curiosityFacts: String? { detail.curiosityFacts }
    var curiosityFactsZh: String? { detail.curiosityFactsZh }
    var notificationMessage: String? { detail.notificationMessage }
    var notificationMessageZh: String? { detail.notificationMessageZh }
    var sourceLanguage: String { detail.sourceLanguage }
    var pronunciationCode: String { detail.pronunciationCode }
    var dateAdded: Date { detail.dateAdded }
    var article: String? { detail.article }
    var gender: String? { detail.gender }
    var partOfSpeech: String? { detail.partOfSpeech }
    var plural: String? { detail.plural }
    var relatedWords: [RelatedWordEntry] { detail.relatedWords }
    var usageNotes: String? { detail.usageNotes }
    var usageNotesZh: String? { detail.usageNotesZh }
    var practiceQuiz: PracticeQuiz? { detail.practiceQuiz }
    var conjugation: String? { detail.conjugation }
    var auxiliaryVerb: String? { detail.auxiliaryVerb }
    var pastParticiple: String? { detail.pastParticiple }
    var antonym: String? { detail.antonym }
    var comparative: String? { detail.comparative }
    var superlative: String? { detail.superlative }

    var isFavorite: Bool { state.isFavorite }
    var isLearned: Bool { state.isLearned }
    var reviewCount: Int { state.reviewCount }
    var isDueForReview: Bool { state.isDueForReview }
}

struct LearnWordPayload: Identifiable, Hashable, WordDisplayable {
    let detail: CatalogWordDetail
    let state: UserWordStateSnapshot

    var id: String { detail.id }
    var word: String { detail.word }
    var translation: String { detail.translation }
    var translationZh: String? { detail.translationZh }
    var examples: [String] { detail.examples }
    var exampleTranslations: [String] { detail.exampleTranslations }
    var exampleTranslationsZh: [String]? { detail.exampleTranslationsZh }
    var difficultyLevel: Int { detail.difficultyLevel }
    var cefrLevel: String? { detail.cefrLevel }
    var curiosityFacts: String? { detail.curiosityFacts }
    var curiosityFactsZh: String? { detail.curiosityFactsZh }
    var notificationMessage: String? { detail.notificationMessage }
    var notificationMessageZh: String? { detail.notificationMessageZh }
    var sourceLanguage: String { detail.sourceLanguage }
    var pronunciationCode: String { detail.pronunciationCode }
    var dateAdded: Date { detail.dateAdded }
    var article: String? { detail.article }
    var gender: String? { detail.gender }
    var partOfSpeech: String? { detail.partOfSpeech }
    var plural: String? { detail.plural }
    var relatedWords: [RelatedWordEntry] { detail.relatedWords }
    var usageNotes: String? { detail.usageNotes }
    var usageNotesZh: String? { detail.usageNotesZh }
    var practiceQuiz: PracticeQuiz? { detail.practiceQuiz }
    var conjugation: String? { detail.conjugation }
    var auxiliaryVerb: String? { detail.auxiliaryVerb }
    var pastParticiple: String? { detail.pastParticiple }
    var antonym: String? { detail.antonym }
    var comparative: String? { detail.comparative }
    var superlative: String? { detail.superlative }

    var reviewCount: Int { state.reviewCount }
    var isLearned: Bool { state.isLearned }
}

struct StatsCatalogSnapshot: Hashable {
    let totalWordsAvailable: Int
    let recentWordLabels: [String]
}

struct BrowseQuery: Hashable {
    var searchText: String
    var favoritesOnly: Bool
    var progressFilter: ProgressFilter
    var difficultyFilter: DifficultyFilter
    var sortOption: SortOption
    var page: Int
    var pageSize: Int
    var visibleOnly: Bool
    var sourceLanguage: String
}

struct LearnSelectionContext: Hashable {
    let currentWordID: String?
    let preferredDifficulty: Int?
    let allowMixedDifficulty: Bool
    let recentWordIDs: [String]
    let todaySeenIDs: [String]
}

extension WordDisplayable {
    var difficultyBucket: DifficultyBucket {
        DifficultyBucket.from(cefrLevel: cefrLevel, fallbackDifficultyLevel: difficultyLevel)
    }

    var primaryExample: String {
        examples.first ?? ""
    }

    var primaryExampleTranslation: String {
        localizedExampleTranslations.first ?? ""
    }

    var localizedTranslation: String {
        if AppLanguage.activeTargetLanguage == .chinese,
           let translationZh, !translationZh.isEmpty {
            return translationZh
        }
        return translation
    }

    var localizedExampleTranslations: [String] {
        if AppLanguage.activeTargetLanguage == .chinese,
           let exampleTranslationsZh, !exampleTranslationsZh.isEmpty {
            return exampleTranslationsZh
        }
        return exampleTranslations
    }

    var localizedExamplePairs: [(String, String)] {
        let translations = localizedExampleTranslations
        let count = min(examples.count, translations.count)
        return (0..<count).map { (examples[$0], translations[$0]) }
    }

    var localizedCuriosityFacts: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let curiosityFactsZh, !curiosityFactsZh.isEmpty {
            return curiosityFactsZh
        }
        return curiosityFacts
    }

    var localizedUsageNotes: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let usageNotesZh, !usageNotesZh.isEmpty {
            return usageNotesZh
        }
        return usageNotes
    }

    var localizedNotificationMessage: String? {
        if AppLanguage.activeTargetLanguage == .chinese,
           let notificationMessageZh, !notificationMessageZh.isEmpty {
            return notificationMessageZh
        }
        return notificationMessage
    }

    var displayArticle: String? {
        if let stored = article?.trimmingCharacters(in: .whitespacesAndNewlines), !stored.isEmpty {
            return stored.lowercased()
        }

        let knownArticles = ["der", "die", "das", "den", "dem", "des"]
        let components = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ")
        guard let first = components.first else { return nil }
        let firstComponent = String(first)
        return knownArticles.contains(firstComponent) ? firstComponent : nil
    }

    var displayGender: String? {
        guard let rawGender = gender?.trimmingCharacters(in: .whitespacesAndNewlines), !rawGender.isEmpty else {
            return nil
        }

        switch rawGender.lowercased() {
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

    var displayDifficulty: String {
        difficultyBucket.title
    }

    var displayWord: String {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let displayArticle, !displayArticle.isEmpty else {
            return trimmedWord
        }

        let loweredPrefix = displayArticle.lowercased() + " "
        if trimmedWord.lowercased().hasPrefix(loweredPrefix) {
            return String(trimmedWord.dropFirst(loweredPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmedWord
    }

    var conjugationPairs: [(pronoun: String, form: String)] {
        guard let conjugation, !conjugation.isEmpty else { return [] }
        return conjugation.components(separatedBy: ", ").compactMap { entry in
            let parts = entry.components(separatedBy: " ")
            guard parts.count >= 2 else { return nil }
            let pronoun = parts.dropLast().joined(separator: " ")
            return (pronoun, parts.last ?? "")
        }
    }

    var antonymParts: (word: String, note: String)? {
        guard let antonym, !antonym.isEmpty else { return nil }
        let parts = antonym.components(separatedBy: " — ")
        guard parts.count >= 2 else { return (antonym, "") }
        return (
            parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
            parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    var relatedWordsText: String? {
        guard !relatedWords.isEmpty else { return nil }
        return relatedWords.map { entry in
            let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return note.isEmpty ? "- \(entry.word)" : "- \(entry.word) — \(note)"
        }
        .joined(separator: "\n")
    }
}
