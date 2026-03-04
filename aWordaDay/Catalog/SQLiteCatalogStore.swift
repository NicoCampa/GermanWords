//
//  SQLiteCatalogStore.swift
//  aWordaDay
//

import Foundation
import SQLite3

struct CatalogDifficultyPolicy: Hashable {
    let preferredDifficulty: Int?
    let allowMixedDifficulty: Bool
}

protocol CatalogStoreProtocol: AnyObject {
    func fetchWord(id: String) -> CatalogWordDetail?
    func fetchBrowseRows(query: BrowseQuery) -> [CatalogWordDetail]
    func fetchBrowseRowCount(query: BrowseQuery) -> Int
    func fetchWords(ids: [String]) -> [CatalogWordDetail]
    func fetchCandidateWords(language: String, difficultyPolicy: CatalogDifficultyPolicy, limit: Int) -> [CatalogWord]
    func fetchNotificationCandidateWords(limit: Int) -> [CatalogWordDetail]
    func totalWordCount(for language: String) -> Int
}

final class SQLiteCatalogStore: CatalogStoreProtocol {
    static let shared = SQLiteCatalogStore()

    private let queue = DispatchQueue(label: "com.nicolocampagnoli.aWordaDay.catalog")
    private var database: OpaquePointer?

    private init() {
        openDatabaseIfPossible()
    }

    deinit {
        if let database {
            sqlite3_close(database)
        }
    }

    func fetchWord(id: String) -> CatalogWordDetail? {
        let sql = """
        SELECT id, word, translation, translation_zh, source_language, pronunciation_code,
               difficulty_level, cefr_level, article, gender, part_of_speech, plural,
               usage_notes, usage_notes_zh, curiosity_facts, curiosity_facts_zh,
               notification_message, notification_message_zh, conjugation, auxiliary_verb,
               past_participle, antonym, comparative, superlative, examples_json,
               example_translations_json, example_translations_zh_json, related_words_json,
               practice_quiz_json, date_added
        FROM words
        WHERE id = ?
        LIMIT 1
        """

        return queue.sync {
            guard let database else { return nil }
            guard let statement = prepareStatement(database: database, sql: sql) else { return nil }
            defer { sqlite3_finalize(statement) }
            bind(text: id, to: statement, index: 1)

            guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
            return decodeDetail(from: statement)
        }
    }

    func fetchBrowseRows(query: BrowseQuery) -> [CatalogWordDetail] {
        queue.sync {
            guard let database else { return [] }

            let searchTerm = normalizedSearchTerm(query.searchText)
            var bindings: [String] = [query.sourceLanguage]
            var conditions = ["source_language = ?"]

            if query.difficultyFilter != .all {
                switch query.difficultyFilter {
                case .easy:
                    conditions.append(DifficultyBucket.easy.sqlFilterClause)
                case .medium:
                    conditions.append(DifficultyBucket.medium.sqlFilterClause)
                case .hard:
                    conditions.append(DifficultyBucket.hard.sqlFilterClause)
                case .all:
                    break
                }
            }

            if !searchTerm.isEmpty {
                conditions.append("(word_lower LIKE ? OR translation_lower LIKE ? OR usage_notes_lower LIKE ?)")
                let likeTerm = "%\(searchTerm)%"
                bindings.append(contentsOf: [likeTerm, likeTerm, likeTerm])
            }

            let offset = max(query.page - 1, 0) * max(query.pageSize, 1)
            let sql = """
            SELECT id, word, translation, translation_zh, source_language, pronunciation_code,
                   difficulty_level, cefr_level, article, gender, part_of_speech, plural,
                   usage_notes, usage_notes_zh, curiosity_facts, curiosity_facts_zh,
                   notification_message, notification_message_zh, conjugation, auxiliary_verb,
                   past_participle, antonym, comparative, superlative, examples_json,
                   example_translations_json, example_translations_zh_json, related_words_json,
                   practice_quiz_json, date_added
            FROM words
            WHERE \(conditions.joined(separator: " AND "))
            ORDER BY \(sortClause(for: query.sortOption))
            LIMIT \(max(query.pageSize, 1)) OFFSET \(offset)
            """

            guard let statement = prepareStatement(database: database, sql: sql) else { return [] }
            defer { sqlite3_finalize(statement) }
            bind(strings: bindings, to: statement)

            var rows: [CatalogWordDetail] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                rows.append(decodeDetail(from: statement))
            }
            return rows
        }
    }

    func fetchBrowseRowCount(query: BrowseQuery) -> Int {
        queue.sync {
            guard let database else { return 0 }

            let searchTerm = normalizedSearchTerm(query.searchText)
            var bindings: [String] = [query.sourceLanguage]
            var conditions = ["source_language = ?"]

            if query.difficultyFilter != .all {
                switch query.difficultyFilter {
                case .easy:
                    conditions.append(DifficultyBucket.easy.sqlFilterClause)
                case .medium:
                    conditions.append(DifficultyBucket.medium.sqlFilterClause)
                case .hard:
                    conditions.append(DifficultyBucket.hard.sqlFilterClause)
                case .all:
                    break
                }
            }

            if !searchTerm.isEmpty {
                conditions.append("(word_lower LIKE ? OR translation_lower LIKE ? OR usage_notes_lower LIKE ?)")
                let likeTerm = "%\(searchTerm)%"
                bindings.append(contentsOf: [likeTerm, likeTerm, likeTerm])
            }

            let sql = """
            SELECT COUNT(*)
            FROM words
            WHERE \(conditions.joined(separator: " AND "))
            """

            guard let statement = prepareStatement(database: database, sql: sql) else { return 0 }
            defer { sqlite3_finalize(statement) }
            bind(strings: bindings, to: statement)

            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int64(statement, 0))
        }
    }

    func fetchWords(ids: [String]) -> [CatalogWordDetail] {
        guard !ids.isEmpty else { return [] }

        return queue.sync {
            guard let database else { return [] }

            let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ",")
            let sql = """
            SELECT id, word, translation, translation_zh, source_language, pronunciation_code,
                   difficulty_level, cefr_level, article, gender, part_of_speech, plural,
                   usage_notes, usage_notes_zh, curiosity_facts, curiosity_facts_zh,
                   notification_message, notification_message_zh, conjugation, auxiliary_verb,
                   past_participle, antonym, comparative, superlative, examples_json,
                   example_translations_json, example_translations_zh_json, related_words_json,
                   practice_quiz_json, date_added
            FROM words
            WHERE id IN (\(placeholders))
            """

            guard let statement = prepareStatement(database: database, sql: sql) else { return [] }
            defer { sqlite3_finalize(statement) }
            bind(strings: ids, to: statement)

            var decodedByID: [String: CatalogWordDetail] = [:]
            while sqlite3_step(statement) == SQLITE_ROW {
                let detail = decodeDetail(from: statement)
                decodedByID[detail.id] = detail
            }

            return ids.compactMap { decodedByID[$0] }
        }
    }

    func fetchCandidateWords(language: String, difficultyPolicy: CatalogDifficultyPolicy, limit: Int) -> [CatalogWord] {
        queue.sync {
            guard let database else { return [] }

            var conditions = ["source_language = ?"]
            var bindings = [language]

            if let preferredDifficulty = difficultyPolicy.preferredDifficulty,
               !difficultyPolicy.allowMixedDifficulty,
               let selectedBucket = DifficultyBucket(selection: preferredDifficulty) {
                conditions.append(selectedBucket.sqlFilterClause)
            }

            let limitClause = limit > 0 ? "LIMIT \(limit)" : ""
            let sql = """
            SELECT id, word, translation, source_language, pronunciation_code,
                   difficulty_level, cefr_level, part_of_speech, usage_notes, date_added
            FROM words
            WHERE \(conditions.joined(separator: " AND "))
            ORDER BY RANDOM()
            \(limitClause)
            """

            guard let statement = prepareStatement(database: database, sql: sql) else { return [] }
            defer { sqlite3_finalize(statement) }
            bind(strings: bindings, to: statement)

            var words: [CatalogWord] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                words.append(
                    CatalogWord(
                        id: stringColumn(statement, index: 0) ?? "",
                        word: stringColumn(statement, index: 1) ?? "",
                        translation: stringColumn(statement, index: 2) ?? "",
                        sourceLanguage: stringColumn(statement, index: 3) ?? "",
                        pronunciationCode: stringColumn(statement, index: 4) ?? AppLanguage.pronunciationCode,
                        difficultyLevel: Int(sqlite3_column_int64(statement, 5)),
                        cefrLevel: stringColumn(statement, index: 6),
                        partOfSpeech: stringColumn(statement, index: 7),
                        usageNotes: stringColumn(statement, index: 8),
                        dateAdded: dateColumn(statement, index: 9)
                    )
                )
            }
            return words
        }
    }

    func fetchNotificationCandidateWords(limit: Int) -> [CatalogWordDetail] {
        let query = BrowseQuery(
            searchText: "",
            favoritesOnly: false,
            progressFilter: .all,
            difficultyFilter: .all,
            sortOption: .dateAdded,
            page: 1,
            pageSize: limit,
            visibleOnly: false,
            sourceLanguage: AppLanguage.sourceCode
        )
        return fetchBrowseRows(query: query)
    }

    func totalWordCount(for language: String) -> Int {
        queue.sync {
            guard let database else { return 0 }
            let sql = "SELECT COUNT(*) FROM words WHERE source_language = ?"
            guard let statement = prepareStatement(database: database, sql: sql) else { return 0 }
            defer { sqlite3_finalize(statement) }
            bind(text: language, to: statement, index: 1)

            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int64(statement, 0))
        }
    }

    private func openDatabaseIfPossible() {
        guard let url = bundledCatalogURL() else {
            #if DEBUG
            print("⚠️ Missing bundled catalog.sqlite")
            #endif
            return
        }

        var databasePointer: OpaquePointer?
        if sqlite3_open_v2(url.path, &databasePointer, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            #if DEBUG
            print("⚠️ Failed to open catalog.sqlite at \(url.path)")
            #endif
            if let databasePointer {
                sqlite3_close(databasePointer)
            }
            return
        }

        database = databasePointer
    }

    private func bundledCatalogURL() -> URL? {
        if let bundleURL = Bundle.main.url(forResource: "catalog", withExtension: "sqlite") {
            return bundleURL
        }

        let fallback = URL(fileURLWithPath: "/Users/nicolocampagnoli/Documents/iOS app projects/aWordaDay/aWordaDay/catalog.sqlite")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    private func sortClause(for option: SortOption) -> String {
        switch option {
        case .dateAdded:
            return "date_added DESC"
        case .alphabetical:
            return "word_lower ASC"
        case .difficulty:
            return "\(DifficultyBucket.sqlSortRankExpression) ASC, word_lower ASC"
        }
    }

    private func normalizedSearchTerm(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
    }

    private func prepareStatement(database: OpaquePointer, sql: String) -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            #if DEBUG
            print("⚠️ SQL prepare failed: \(sql)")
            #endif
            return nil
        }
        return statement
    }

    private func bind(strings: [String], to statement: OpaquePointer?) {
        for (index, string) in strings.enumerated() {
            bind(text: string, to: statement, index: Int32(index + 1))
        }
    }

    private func bind(text: String, to statement: OpaquePointer?, index: Int32) {
        sqlite3_bind_text(statement, index, text, -1, SQLITE_TRANSIENT)
    }

    private func decodeDetail(from statement: OpaquePointer?) -> CatalogWordDetail {
        CatalogWordDetail(
            id: stringColumn(statement, index: 0) ?? "",
            word: stringColumn(statement, index: 1) ?? "",
            translation: stringColumn(statement, index: 2) ?? "",
            translationZh: stringColumn(statement, index: 3),
            examples: decodeStringArray(stringColumn(statement, index: 24)),
            exampleTranslations: decodeStringArray(stringColumn(statement, index: 25)),
            exampleTranslationsZh: decodeOptionalStringArray(stringColumn(statement, index: 26)),
            difficultyLevel: Int(sqlite3_column_int64(statement, 6)),
            cefrLevel: stringColumn(statement, index: 7),
            curiosityFacts: stringColumn(statement, index: 14),
            curiosityFactsZh: stringColumn(statement, index: 15),
            notificationMessage: stringColumn(statement, index: 16),
            notificationMessageZh: stringColumn(statement, index: 17),
            sourceLanguage: stringColumn(statement, index: 4) ?? AppLanguage.sourceCode,
            pronunciationCode: stringColumn(statement, index: 5) ?? AppLanguage.pronunciationCode,
            dateAdded: dateColumn(statement, index: 29),
            article: stringColumn(statement, index: 8),
            gender: stringColumn(statement, index: 9),
            partOfSpeech: stringColumn(statement, index: 10),
            plural: stringColumn(statement, index: 11),
            relatedWords: decodeRelatedWords(stringColumn(statement, index: 27)),
            usageNotes: stringColumn(statement, index: 12),
            usageNotesZh: stringColumn(statement, index: 13),
            practiceQuiz: decodePracticeQuiz(stringColumn(statement, index: 28)),
            conjugation: stringColumn(statement, index: 18),
            auxiliaryVerb: stringColumn(statement, index: 19),
            pastParticiple: stringColumn(statement, index: 20),
            antonym: stringColumn(statement, index: 21),
            comparative: stringColumn(statement, index: 22),
            superlative: stringColumn(statement, index: 23)
        )
    }

    private func stringColumn(_ statement: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }

    private func dateColumn(_ statement: OpaquePointer?, index: Int32) -> Date {
        Date(timeIntervalSince1970: sqlite3_column_double(statement, index))
    }

    private func decodeStringArray(_ json: String?) -> [String] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func decodeOptionalStringArray(_ json: String?) -> [String]? {
        guard let json, !json.isEmpty else { return nil }
        return decodeStringArray(json)
    }

    private func decodeRelatedWords(_ json: String?) -> [RelatedWordEntry] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([RelatedWordEntry].self, from: data)) ?? []
    }

    private func decodePracticeQuiz(_ json: String?) -> PracticeQuiz? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PracticeQuiz.self, from: data)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
