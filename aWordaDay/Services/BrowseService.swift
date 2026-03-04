//
//  BrowseService.swift
//  aWordaDay
//

import Foundation
import SwiftData

struct BrowsePage {
    let rows: [BrowseWordRow]
    let totalCount: Int
    let hasMorePages: Bool
}

@MainActor
final class BrowseService {
    private let catalogStore: CatalogStoreProtocol
    private let userStateStore: UserStateStoreProtocol

    init(
        catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared,
        userStateStore: UserStateStoreProtocol? = nil
    ) {
        self.catalogStore = catalogStore
        self.userStateStore = userStateStore ?? SwiftDataUserStateStore()
    }

    func fetchPage(
        query: BrowseQuery,
        modelContext: ModelContext,
        showsOnlyViewedWords: Bool
    ) -> BrowsePage {
        let allStates = userStateStore.loadWordStates(in: modelContext)
        let statesByID = Dictionary(uniqueKeysWithValues: allStates.map { ($0.wordID, $0.snapshot) })
        let needsStateDrivenFiltering = showsOnlyViewedWords || query.favoritesOnly || query.progressFilter != .all

        if needsStateDrivenFiltering {
            return fetchStateDrivenPage(
                query: query,
                states: allStates,
                statesByID: statesByID,
                showsOnlyViewedWords: showsOnlyViewedWords
            )
        }

        let details = catalogStore.fetchBrowseRows(query: query)
        let rows = details.map { detail in
            BrowseWordRow(detail: detail, state: statesByID[detail.id] ?? .empty(wordID: detail.id))
        }
        let totalCount = catalogStore.fetchBrowseRowCount(query: query)
        let hasMorePages = query.page * query.pageSize < totalCount
        return BrowsePage(rows: rows, totalCount: totalCount, hasMorePages: hasMorePages)
    }

    private func fetchStateDrivenPage(
        query: BrowseQuery,
        states: [UserWordState],
        statesByID: [String: UserWordStateSnapshot],
        showsOnlyViewedWords: Bool
    ) -> BrowsePage {
        let matchingIDs = states
            .filter { state in
                if showsOnlyViewedWords && state.reviewCount == 0 { return false }
                if query.favoritesOnly && !state.isFavorite { return false }

                switch query.progressFilter {
                case .all:
                    break
                case .learning:
                    if state.isLearned { return false }
                case .learned:
                    if !state.isLearned { return false }
                case .dueReview:
                    if !state.isDueForReview { return false }
                }

                return true
            }
            .map(\.wordID)

        if matchingIDs.isEmpty && showsOnlyViewedWords {
            return BrowsePage(rows: [], totalCount: 0, hasMorePages: false)
        }

        let rows = catalogStore.fetchWords(ids: matchingIDs)
            .map { detail in
                BrowseWordRow(detail: detail, state: statesByID[detail.id] ?? .empty(wordID: detail.id))
            }
            .filter { row in
                guard row.sourceLanguage == query.sourceLanguage else { return false }

                switch query.difficultyFilter {
                case .all:
                    break
                case .easy:
                    if row.difficultyBucket != .easy { return false }
                case .medium:
                    if row.difficultyBucket != .medium { return false }
                case .hard:
                    if row.difficultyBucket != .hard { return false }
                }

                let search = normalizedSearch(query.searchText)
                if !search.isEmpty {
                    let haystacks = [row.word, row.translation, row.usageNotes ?? ""]
                    let matches = haystacks.contains { value in
                        normalize(value).contains(search)
                    }
                    if !matches { return false }
                }

                return true
            }
            .sorted(by: browseSort(query.sortOption))

        let totalCount = rows.count
        let startIndex = max(query.page - 1, 0) * query.pageSize
        let endIndex = min(startIndex + query.pageSize, rows.count)
        let pageRows = startIndex < endIndex ? Array(rows[startIndex..<endIndex]) : []
        let hasMorePages = endIndex < rows.count
        return BrowsePage(rows: pageRows, totalCount: totalCount, hasMorePages: hasMorePages)
    }

    private func browseSort(_ option: SortOption) -> (BrowseWordRow, BrowseWordRow) -> Bool {
        switch option {
        case .dateAdded:
            return { $0.dateAdded > $1.dateAdded }
        case .alphabetical:
            return { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
        case .difficulty:
            return {
                if $0.difficultyBucket != $1.difficultyBucket {
                    return $0.difficultyBucket.rawValue < $1.difficultyBucket.rawValue
                }
                return $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending
            }
        }
    }

    private func normalizedSearch(_ value: String) -> String {
        normalize(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
    }
}
