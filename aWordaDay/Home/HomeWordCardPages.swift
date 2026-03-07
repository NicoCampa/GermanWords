import SwiftUI

enum WordCardPageKind: String, CaseIterable, Hashable, Identifiable {
    case examples
    case didYouKnow
    case usageNotes
    case relatedWords
    case conjugation
    case detailsFallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .examples:
            return L10n.Common.examples
        case .didYouKnow:
            return L10n.WordDetail.didYouKnow
        case .usageNotes:
            return L10n.WordDetail.usageNotes
        case .relatedWords:
            return L10n.WordDetail.relatedWords
        case .conjugation:
            return L10n.WordDetail.conjugation
        case .detailsFallback:
            return L10n.WordDetail.details
        }
    }

    var shortTitle: String {
        switch self {
        case .examples:
            return "Examples"
        case .didYouKnow:
            return "Notes"
        case .usageNotes:
            return "Usage"
        case .relatedWords:
            return "Related"
        case .conjugation:
            return "Forms"
        case .detailsFallback:
            return "Details"
        }
    }

    var accent: Color {
        switch self {
        case .examples:
            return DesignTokens.color.skyBlue
        case .didYouKnow:
            return DesignTokens.color.gold
        case .usageNotes:
            return DesignTokens.color.accentBlue
        case .relatedWords:
            return DesignTokens.color.relatedAccent
        case .conjugation:
            return DesignTokens.color.pronunciationAccent
        case .detailsFallback:
            return DesignTokens.color.textMuted
        }
    }
}

struct WordCardPage: Identifiable {
    let kind: WordCardPageKind
    let title: String
    let shortTitle: String
    let accent: Color

    var id: String { kind.rawValue }

    init(kind: WordCardPageKind) {
        self.kind = kind
        self.title = kind.title
        self.shortTitle = kind.shortTitle
        self.accent = kind.accent
    }
}

func wordCardPages<WordType: WordDisplayable>(for word: WordType) -> [WordCardPage] {
    var pages: [WordCardPage] = []
    let hasConjugation = !word.conjugationPairs.isEmpty

    if !word.localizedExamplePairs.isEmpty {
        pages.append(WordCardPage(kind: .examples))
    }

    // Verbs: keep Forms directly after Examples.
    if wordCardIsVerb(word), hasConjugation {
        pages.append(WordCardPage(kind: .conjugation))
    }

    if !wordCardUsageEntries(for: word).isEmpty {
        pages.append(WordCardPage(kind: .usageNotes))
    }

    if let curiosityFacts = word.localizedCuriosityFacts?.trimmingCharacters(in: .whitespacesAndNewlines),
       !curiosityFacts.isEmpty {
        pages.append(WordCardPage(kind: .didYouKnow))
    }

    if !word.relatedWords.isEmpty {
        pages.append(WordCardPage(kind: .relatedWords))
    }

    // Non-verbs keep Forms at the end, preserving previous order.
    if !wordCardIsVerb(word), hasConjugation {
        pages.append(WordCardPage(kind: .conjugation))
    }

    return pages.isEmpty ? [WordCardPage(kind: .detailsFallback)] : pages
}

func defaultWordCardPageKind<WordType: WordDisplayable>(for word: WordType) -> WordCardPageKind {
    wordCardPages(for: word).first?.kind ?? .detailsFallback
}

func wordCardUsageEntries<WordType: WordDisplayable>(for word: WordType) -> [String] {
    let trimmed = word.localizedUsageNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let source = trimmed.isEmpty ? word.localizedTranslation : trimmed

    return source
        .components(separatedBy: CharacterSet.newlines)
        .flatMap { $0.components(separatedBy: "•") }
        .map { raw in
            var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            while let first = cleaned.first, ["-", "•"].contains(first) {
                cleaned.removeFirst()
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return cleaned
        }
        .filter { !$0.isEmpty }
}

func wordCardGenderColor<WordType: WordDisplayable>(for word: WordType) -> Color? {
    guard wordCardIsNoun(word) else { return nil }

    let resolvedGender = word.gender?.lowercased() ?? word.displayArticle
    switch resolvedGender {
    case "masculine", "maskulin", "m", "der":
        return DesignTokens.color.genderMasculine
    case "feminine", "feminin", "f", "die":
        return DesignTokens.color.genderFeminine
    case "neuter", "neutral", "n", "das":
        return DesignTokens.color.genderNeuter
    default:
        return nil
    }
}

func wordCardIsNoun<WordType: WordDisplayable>(_ word: WordType) -> Bool {
    word.partOfSpeech?.lowercased().contains("noun") == true || word.displayArticle != nil
}

func wordCardIsVerb<WordType: WordDisplayable>(_ word: WordType) -> Bool {
    word.partOfSpeech?.lowercased().contains("verb") == true
}
