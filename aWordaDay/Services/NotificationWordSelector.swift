//
//  NotificationWordSelector.swift
//  aWordaDay
//

import Foundation
import SwiftData

@MainActor
final class NotificationWordSelector {
    private let catalogStore: CatalogStoreProtocol
    private let userStateStore: UserStateStoreProtocol

    init(
        catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared,
        userStateStore: UserStateStoreProtocol? = nil
    ) {
        self.catalogStore = catalogStore
        self.userStateStore = userStateStore ?? SwiftDataUserStateStore()
    }

    func selectWord(modelContext: ModelContext, language: String) -> CatalogWordDetail? {
        let states = userStateStore.loadWordStates(in: modelContext)

        if let dueState = states
            .filter({ $0.isDueForReview })
            .sorted(by: { ($0.srsDueDate ?? .distantFuture) < ($1.srsDueDate ?? .distantFuture) })
            .first {
            return catalogStore.fetchWord(id: dueState.wordID)
        }

        let stateIDs = Set(states.map(\.wordID))
        let unseenCandidates = catalogStore.fetchCandidateWords(
            language: language,
            difficultyPolicy: CatalogDifficultyPolicy(preferredDifficulty: nil, allowMixedDifficulty: true),
            limit: 0
        )
        .filter { !stateIDs.contains($0.id) }

        if let unseen = unseenCandidates.randomElement() {
            return catalogStore.fetchWord(id: unseen.id)
        }

        if let leastReviewed = states.min(by: { $0.reviewCount < $1.reviewCount }) {
            return catalogStore.fetchWord(id: leastReviewed.wordID)
        }

        return catalogStore.fetchNotificationCandidateWords(limit: 1).first
    }
}
