//
//  StatsService.swift
//  aWordaDay
//

import Foundation
import SwiftData

struct StatsSummary {
    let appState: AppState
    let totalWordsAvailable: Int
    let discoveredCount: Int
    let recentWordLabels: [String]
}

@MainActor
final class StatsService {
    private let catalogStore: CatalogStoreProtocol
    private let userStateStore: UserStateStoreProtocol

    init(
        catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared,
        userStateStore: UserStateStoreProtocol? = nil
    ) {
        self.catalogStore = catalogStore
        self.userStateStore = userStateStore ?? SwiftDataUserStateStore()
    }

    func makeSummary(modelContext: ModelContext) -> StatsSummary {
        let appState = userStateStore.loadAppState(in: modelContext)
        let states = userStateStore.loadWordStates(in: modelContext)
        let discoveredStates = states.filter { $0.reviewCount > 0 }
        let recentIDs = discoveredStates
            .sorted { ($0.lastReviewedAt ?? .distantPast) > ($1.lastReviewedAt ?? .distantPast) }
            .prefix(6)
            .map(\.wordID)
        let labels = catalogStore.fetchWords(ids: recentIDs).map(\.word)

        return StatsSummary(
            appState: appState,
            totalWordsAvailable: catalogStore.totalWordCount(for: AppLanguage.sourceCode),
            discoveredCount: discoveredStates.count,
            recentWordLabels: labels
        )
    }
}
