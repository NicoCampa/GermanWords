//
//  WordDataLoader.swift
//  aWordaDay
//
//  Created by Claude on 08.08.25
//

import Foundation
import SwiftData

// MARK: - JSON Data Structures for Import
struct WordExportFile: Codable {
    let metadata: ExportMetadata
    let words: [WordImportData]
}

struct ExportMetadata: Codable {
    let exportDate: String
    let schemaVersion: Int?
    let language: LanguageInfo
    let totalWords: Int
    let difficultyDistribution: [String: Int]
}

struct LanguageInfo: Codable {
    let code: String
    let name: String
    let nativeName: String
    let pronunciationCode: String
}

struct PracticeQuizPayload: Codable {
    let question: String
    let correctAnswer: String
    let distractors: [String]

    func toModel() -> PracticeQuiz {
        PracticeQuiz(question: question, correctAnswer: correctAnswer, distractors: distractors)
    }
}

struct VerbConjugationPayload: Codable {
    let presentTense: [String: String]?
    let perfect: PerfectPayload?
    let infinitive: String?

    struct PerfectPayload: Codable {
        let auxiliary: String?
        let participle: String?
    }

    /// Formats presentTense dict into a canonical ordered string:
    /// "ich gehe, du gehst, er/sie/es geht, wir gehen, ihr geht, sie/Sie gehen"
    func formattedPresentTense() -> String? {
        guard let forms = presentTense, !forms.isEmpty else { return nil }
        let orderedKeys: [(key: String, display: String)] = [
            ("ich", "ich"),
            ("du", "du"),
            ("er_sie_es", "er/sie/es"),
            ("wir", "wir"),
            ("ihr", "ihr"),
            ("sie_Sie", "sie/Sie")
        ]
        let parts: [String] = orderedKeys.compactMap { (key, display) in
            guard let form = forms[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !form.isEmpty else { return nil }
            return "\(display) \(form)"
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct WordImportData: Codable {
    let word: String
    let translation: String
    let examples: [String]
    let exampleTranslations: [String]
    let difficultyLevel: Int
    let cefrLevel: String
    let curiosityFacts: String?
    let notificationMessage: String?
    let sourceLanguage: String
    let pronunciationCode: String
    let article: String?
    let gender: String?
    let partOfSpeech: String
    let plural: String?
    let relatedWords: [RelatedWordEntry]?
    let usageNotes: String
    let practiceQuiz: PracticeQuizPayload?
    let verbConjugation: VerbConjugationPayload?
    let antonym: AntonymPayload?
    let adjectiveForms: AdjectiveFormsPayload?

    // Chinese translation fields (schema v3)
    let translationZh: String?
    let exampleTranslationsZh: [String]?
    let curiosityFactsZh: String?
    let usageNotesZh: String?
    let notificationMessageZh: String?
}

struct LanguageImportResult {
    var imported: Int
    var updated: Int
    var duplicates: Int
    var skipped: Int
    var invalid: Int

    var hasChanges: Bool {
        imported > 0 || updated > 0
    }
}

// MARK: - Word Data Loader
class WordDataLoader: WordDataLoaderProtocol {
    static let shared = WordDataLoader()

    private init() {}

    /// Load words from bundled JSON files and populate the database
    func loadBundledWords(into modelContext: ModelContext) {
        #if DEBUG
        print("🗄️ Starting word data import...")
        #endif

        let result = loadLanguageWords(into: modelContext)
        #if DEBUG
        print("📚 \(AppLanguage.displayName) bundle → imported: \(result.imported), updated: \(result.updated), duplicates: \(result.duplicates), skipped: \(result.skipped), invalid: \(result.invalid)")
        print("✅ Total words imported: \(result.imported) | updated: \(result.updated)")
        #endif

        // Save the context after all imports
        do {
            try modelContext.save()
            #if DEBUG
            print("💾 Database saved successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to save database: \(error)")
            #endif
        }
    }

    /// Check bundle JSONs and import additional words if new ones were generated
    func syncBundledUpdates(into modelContext: ModelContext) {
        let decoder = JSONDecoder()
        var didModify = false

        guard let url = Bundle.main.url(forResource: AppLanguage.exportResourceName, withExtension: "json") else {
            #if DEBUG
            print("⚠️ Missing \(AppLanguage.exportResourceName).json in bundle")
            #endif
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let exportFile = try decoder.decode(WordExportFile.self, from: data)
            let languageCode = exportFile.metadata.language.code
            let existingCount = wordCount(for: languageCode, in: modelContext)
            let bundledCount = exportFile.words.count

            let result = loadLanguageWords(into: modelContext)
            if result.hasChanges || existingCount != bundledCount {
                didModify = true
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to sync bundle: \(error)")
            #endif
        }

        if didModify {
            do {
                try modelContext.save()
                #if DEBUG
                print("💾 Saved synced bundle updates")
                #endif
            } catch {
                #if DEBUG
                print("❌ Failed to save synced bundle updates: \(error)")
                #endif
            }
        }
    }

    private func normalizeImportedWord(_ rawWord: String, article: String?) -> String {
        let trimmedWord = rawWord.trimmed()
        guard !trimmedWord.isEmpty else { return trimmedWord }
        guard let article = article?.trimmed().nilIfEmpty else { return trimmedWord }

        let loweredWord = trimmedWord.lowercased()
        let loweredArticlePrefix = article.lowercased() + " "
        guard loweredWord.hasPrefix(loweredArticlePrefix) else { return trimmedWord }

        return String(trimmedWord.dropFirst(loweredArticlePrefix.count)).trimmed()
    }

    /// Load words for a specific language from JSON file
    private func loadLanguageWords(into modelContext: ModelContext) -> LanguageImportResult {
        let resourceName = AppLanguage.exportResourceName
        #if DEBUG
        print("🔍 Looking for file: \(resourceName).json")
        print("📁 Bundle path: \(Bundle.main.bundlePath)")
        #endif

        // List all JSON files in bundle
        let bundleFiles = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        #if DEBUG
        print("📄 Found JSON files in bundle: \(bundleFiles)")
        #endif

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            #if DEBUG
            print("⚠️ No word file found for \(AppLanguage.displayName)")
            #endif
            return LanguageImportResult(imported: 0, updated: 0, duplicates: 0, skipped: 0, invalid: 0)
        }

        do {
            let data = try Data(contentsOf: url)
            let exportFile = try JSONDecoder().decode(WordExportFile.self, from: data)

            var importedCount = 0
            var skippedCount = 0
            var duplicateCount = 0
            var invalidDataCount = 0
            var updatedCount = 0

            // Batch-fetch all existing words for this language into a lookup dictionary
            // to avoid O(N) fetches during import.
            let langCode = exportFile.metadata.language.code
            let existingDescriptor = FetchDescriptor<Word>(
                predicate: #Predicate<Word> { word in
                    word.sourceLanguage == langCode
                }
            )
            let existingWords = (try? modelContext.fetch(existingDescriptor)) ?? []
            var existingByWord: [String: Word] = [:]
            for w in existingWords {
                existingByWord[w.word.lowercased()] = w
            }

            for wordData in exportFile.words {
                let rawWordText = wordData.word.trimmed()
                let normalizedArticle = wordData.article?.trimmed().nilIfEmpty
                let wordText = normalizeImportedWord(rawWordText, article: normalizedArticle)
                let translation = wordData.translation.trimmed()
                let usageNotes = wordData.usageNotes.trimmed().nilIfEmpty

                // Validate required fields
                guard !wordText.isEmpty && !translation.isEmpty else {
                    let displayWord = wordText.isEmpty ? "[empty]" : wordText
                    #if DEBUG
                    print("⚠️ Skipping word with missing required fields: \(displayWord)")
                    #endif
                    invalidDataCount += 1
                    continue
                }

                let sanitizedExamples = wordData.examples.map { $0.trimmed() }.filter { !$0.isEmpty }
                let sanitizedTranslations = wordData.exampleTranslations.map { $0.trimmed() }.filter { !$0.isEmpty }
                guard !sanitizedExamples.isEmpty, !sanitizedTranslations.isEmpty else {
                    #if DEBUG
                    print("⚠️ Skipping '\(wordText)' - missing examples (has \(sanitizedExamples.count) examples, \(sanitizedTranslations.count) translations)")
                    #endif
                    skippedCount += 1
                    continue
                }

                let pairCount = min(sanitizedExamples.count, sanitizedTranslations.count)
                let normalizedExamples = Array(sanitizedExamples.prefix(pairCount))
                let normalizedTranslations = Array(sanitizedTranslations.prefix(pairCount))
                let difficulty = max(1, min(3, wordData.difficultyLevel))
                let pronunciationCode = wordData.pronunciationCode.trimmed()
                let sourceLanguage = wordData.sourceLanguage.trimmed()
                // Fast O(1) lookup instead of per-word SwiftData fetch
                let existingWord = existingByWord[wordText.lowercased()]
                    ?? existingByWord[rawWordText.lowercased()]

                let sanitizedRelatedWords: [RelatedWordEntry] = (wordData.relatedWords ?? []).compactMap { entry in
                    let relatedWord = entry.word.trimmed()
                    guard !relatedWord.isEmpty else { return nil }
                    let note = entry.note?.trimmed().nilIfEmpty
                    return RelatedWordEntry(word: relatedWord, note: note)
                }

                if let existingWord {
                    var didUpdate = false

                    if existingWord.translation != translation {
                        existingWord.translation = translation
                        didUpdate = true
                    }
                    if existingWord.word != wordText {
                        existingWord.word = wordText
                        didUpdate = true
                    }
                    if existingWord.examples != normalizedExamples {
                        existingWord.examples = normalizedExamples
                        didUpdate = true
                    }
                    if existingWord.exampleTranslations != normalizedTranslations {
                        existingWord.exampleTranslations = normalizedTranslations
                        didUpdate = true
                    }
                    if existingWord.difficultyLevel != difficulty {
                        existingWord.difficultyLevel = difficulty
                        let newXP = difficulty * 10
                        if existingWord.xpValue != newXP {
                            existingWord.xpValue = newXP
                        }
                        didUpdate = true
                    }
                    let sanitizedCEFR = wordData.cefrLevel.trimmed().nilIfEmpty
                    if existingWord.cefrLevel != sanitizedCEFR {
                        existingWord.cefrLevel = sanitizedCEFR
                        didUpdate = true
                    }
                    let trimmedCuriosity = wordData.curiosityFacts?.trimmed().nilIfEmpty
                    if existingWord.curiosityFacts != trimmedCuriosity {
                        existingWord.curiosityFacts = trimmedCuriosity
                        didUpdate = true
                    }
                    let trimmedNotification = wordData.notificationMessage?.trimmed().nilIfEmpty
                    if existingWord.notificationMessage != trimmedNotification {
                        existingWord.notificationMessage = trimmedNotification
                        didUpdate = true
                    }
                    if existingWord.pronunciationCode != pronunciationCode {
                        existingWord.pronunciationCode = pronunciationCode
                        didUpdate = true
                    }
                    if existingWord.article != wordData.article?.trimmed().nilIfEmpty {
                        existingWord.article = wordData.article?.trimmed().nilIfEmpty
                        didUpdate = true
                    }
                    if existingWord.gender != wordData.gender?.trimmed().nilIfEmpty {
                        existingWord.gender = wordData.gender?.trimmed().nilIfEmpty
                        didUpdate = true
                    }
                    if existingWord.partOfSpeech != wordData.partOfSpeech.trimmed().nilIfEmpty {
                        existingWord.partOfSpeech = wordData.partOfSpeech.trimmed().nilIfEmpty
                        didUpdate = true
                    }
                    if existingWord.plural != wordData.plural?.trimmed().nilIfEmpty {
                        existingWord.plural = wordData.plural?.trimmed().nilIfEmpty
                        didUpdate = true
                    }
                    if existingWord.relatedWords != sanitizedRelatedWords {
                        existingWord.relatedWords = sanitizedRelatedWords
                        didUpdate = true
                    }
                    if existingWord.usageNotes != usageNotes {
                        existingWord.usageNotes = usageNotes
                        didUpdate = true
                    }
                    let newQuiz = wordData.practiceQuiz?.toModel()
                    if existingWord.practiceQuiz != newQuiz {
                        existingWord.practiceQuiz = newQuiz
                        didUpdate = true
                    }
                    let newConjugation = wordData.verbConjugation?.formattedPresentTense()
                    if existingWord.conjugation != newConjugation {
                        existingWord.conjugation = newConjugation
                        didUpdate = true
                    }
                    let newAuxiliary = wordData.verbConjugation?.perfect?.auxiliary?.trimmed().nilIfEmpty
                    if existingWord.auxiliaryVerb != newAuxiliary {
                        existingWord.auxiliaryVerb = newAuxiliary
                        didUpdate = true
                    }
                    let newParticiple = wordData.verbConjugation?.perfect?.participle?.trimmed().nilIfEmpty
                    if existingWord.pastParticiple != newParticiple {
                        existingWord.pastParticiple = newParticiple
                        didUpdate = true
                    }
                    let newAntonym: String? = {
                        guard let a = wordData.antonym else { return nil }
                        let note = a.note?.trimmed().nilIfEmpty
                        return note != nil ? "\(a.word) — \(note!)" : a.word
                    }()
                    if existingWord.antonym != newAntonym {
                        existingWord.antonym = newAntonym
                        didUpdate = true
                    }
                    let newComparative = wordData.adjectiveForms?.comparative?.trimmed().nilIfEmpty
                    if existingWord.comparative != newComparative {
                        existingWord.comparative = newComparative
                        didUpdate = true
                    }
                    let newSuperlative = wordData.adjectiveForms?.superlative?.trimmed().nilIfEmpty
                    if existingWord.superlative != newSuperlative {
                        existingWord.superlative = newSuperlative
                        didUpdate = true
                    }

                    // Chinese translation fields (schema v3)
                    let newTranslationZh = wordData.translationZh?.trimmed().nilIfEmpty
                    if existingWord.translationZh != newTranslationZh {
                        existingWord.translationZh = newTranslationZh
                        didUpdate = true
                    }
                    if existingWord.exampleTranslationsZh != wordData.exampleTranslationsZh {
                        existingWord.exampleTranslationsZh = wordData.exampleTranslationsZh
                        didUpdate = true
                    }
                    let newCuriosityFactsZh = wordData.curiosityFactsZh?.trimmed().nilIfEmpty
                    if existingWord.curiosityFactsZh != newCuriosityFactsZh {
                        existingWord.curiosityFactsZh = newCuriosityFactsZh
                        didUpdate = true
                    }
                    let newUsageNotesZh = wordData.usageNotesZh?.trimmed().nilIfEmpty
                    if existingWord.usageNotesZh != newUsageNotesZh {
                        existingWord.usageNotesZh = newUsageNotesZh
                        didUpdate = true
                    }
                    let newNotificationMessageZh = wordData.notificationMessageZh?.trimmed().nilIfEmpty
                    if existingWord.notificationMessageZh != newNotificationMessageZh {
                        existingWord.notificationMessageZh = newNotificationMessageZh
                        didUpdate = true
                    }

                    if didUpdate {
                        updatedCount += 1
                    } else {
                        duplicateCount += 1
                    }
                } else {
                    let word = Word(
                        word: wordText,
                        translation: translation,
                        examples: normalizedExamples,
                        exampleTranslations: normalizedTranslations,
                        difficultyLevel: difficulty,
                        cefrLevel: wordData.cefrLevel.trimmed().nilIfEmpty,
                        curiosityFacts: wordData.curiosityFacts?.trimmed().nilIfEmpty,
                        relatedWords: sanitizedRelatedWords,
                        notificationMessage: wordData.notificationMessage?.trimmed().nilIfEmpty,
                        sourceLanguage: sourceLanguage,
                        pronunciationCode: pronunciationCode,
                        article: wordData.article?.trimmed().nilIfEmpty,
                        gender: wordData.gender?.trimmed().nilIfEmpty,
                        partOfSpeech: wordData.partOfSpeech.trimmed().nilIfEmpty,
                        plural: wordData.plural?.trimmed().nilIfEmpty,
                        usageNotes: usageNotes,
                        practiceQuiz: wordData.practiceQuiz?.toModel(),
                        conjugation: wordData.verbConjugation?.formattedPresentTense(),
                        auxiliaryVerb: wordData.verbConjugation?.perfect?.auxiliary?.trimmed().nilIfEmpty,
                        pastParticiple: wordData.verbConjugation?.perfect?.participle?.trimmed().nilIfEmpty,
                        antonym: {
                            guard let a = wordData.antonym else { return nil }
                            let note = a.note?.trimmed().nilIfEmpty
                            return note != nil ? "\(a.word) — \(note!)" : a.word
                        }(),
                        comparative: wordData.adjectiveForms?.comparative?.trimmed().nilIfEmpty,
                        superlative: wordData.adjectiveForms?.superlative?.trimmed().nilIfEmpty,
                        translationZh: wordData.translationZh?.trimmed().nilIfEmpty,
                        exampleTranslationsZh: wordData.exampleTranslationsZh,
                        curiosityFactsZh: wordData.curiosityFactsZh?.trimmed().nilIfEmpty,
                        usageNotesZh: wordData.usageNotesZh?.trimmed().nilIfEmpty,
                        notificationMessageZh: wordData.notificationMessageZh?.trimmed().nilIfEmpty
                    )

                    modelContext.insert(word)
                    existingByWord[wordText.lowercased()] = word
                    importedCount += 1
                }
            }

            // Detailed import summary
            #if DEBUG
            print("📊 Import summary for \(AppLanguage.displayName):")
            print("   ✅ New words: \(importedCount)")
            print("   ✏️ Updated words: \(updatedCount)")
            print("   🔄 Unchanged duplicates: \(duplicateCount)")
            print("   ⚠️ Missing examples: \(skippedCount)")
            print("   ❌ Invalid data: \(invalidDataCount)")
            print("   📦 Total in file: \(exportFile.words.count)")

            if skippedCount > 0 || invalidDataCount > 0 {
                print("⚠️ WARNING: \(skippedCount + invalidDataCount) words were not imported due to data issues")
            }
            #endif

            return LanguageImportResult(
                imported: importedCount,
                updated: updatedCount,
                duplicates: duplicateCount,
                skipped: skippedCount,
                invalid: invalidDataCount
            )

        } catch {
            let message = "❌ Failed to load \(AppLanguage.displayName) words: \(error)"
            #if DEBUG
            print(message)
            #endif

            if let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                let logURL = documentsURL.appendingPathComponent("word_import.log")
                if let data = (message + "\n").data(using: .utf8) {
                    if FileManager.default.fileExists(atPath: logURL.path) {
                        if let handle = try? FileHandle(forWritingTo: logURL) {
                            handle.seekToEndOfFile()
                            handle.write(data)
                            try? handle.close()
                        }
                    } else {
                        try? data.write(to: logURL)
                    }
                }
            }
            return LanguageImportResult(imported: 0, updated: 0, duplicates: 0, skipped: 0, invalid: 0)
        }
    }

    /// Check if words are already loaded for a language
    func hasWordsForLanguage(_ languageCode: String, in modelContext: ModelContext) -> Bool {
        do {
            let descriptor = FetchDescriptor<Word>(
                predicate: #Predicate<Word> { word in
                    word.sourceLanguage == languageCode
                }
            )

            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            #if DEBUG
            print("❌ Error checking words for language \(languageCode): \(error)")
            #endif
            return false
        }
    }

    /// Get word count for a specific language
    func wordCount(for languageCode: String, in modelContext: ModelContext) -> Int {
        do {
            let descriptor = FetchDescriptor<Word>(
                predicate: #Predicate<Word> { word in
                    word.sourceLanguage == languageCode
                }
            )

            return try modelContext.fetchCount(descriptor)
        } catch {
            #if DEBUG
            print("❌ Error counting words for language \(languageCode): \(error)")
            #endif
            return 0
        }
    }

    /// Get statistics about loaded words
    func getWordStatistics(in modelContext: ModelContext) -> [String: Any] {
        var stats: [String: Any] = [:]
        let code = AppLanguage.sourceCode
        let name = AppLanguage.displayName
        let total = wordCount(for: code, in: modelContext)
        var difficultyStats: [Int: Int] = [1: 0, 2: 0, 3: 0]

        do {
            let descriptor = FetchDescriptor<Word>(
                predicate: #Predicate<Word> { word in
                    word.sourceLanguage == code
                }
            )

            let words = try modelContext.fetch(descriptor)

            for word in words {
                difficultyStats[word.difficultyLevel, default: 0] += 1
            }
        } catch {
            #if DEBUG
            print("❌ Error fetching difficulty stats: \(error)")
            #endif
        }

        stats[name] = [
            "total": total,
            "easy": difficultyStats[1] ?? 0,
            "medium": difficultyStats[2] ?? 0,
            "hard": difficultyStats[3] ?? 0
        ]

        return stats
    }
}

// MARK: - User Progress Integration
extension UserProgress {
    func loadInitialDataIfNeeded(modelContext: ModelContext) {
        if isFirstLaunch {
            #if DEBUG
            print("🚀 First launch detected - loading word database...")
            #endif
            WordDataLoader.shared.loadBundledWords(into: modelContext)

            isFirstLaunch = false

            #if DEBUG
            print("🎉 Initial setup complete!")
            #endif
        }

        WordDataLoader.shared.syncBundledUpdates(into: modelContext)
    }
}

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
