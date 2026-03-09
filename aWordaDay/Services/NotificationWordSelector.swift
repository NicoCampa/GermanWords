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

    func selectWord(
        modelContext: ModelContext,
        language: String,
        excluding excludedWordIDs: Set<String> = []
    ) -> CatalogWordDetail? {
        let states = userStateStore.loadWordStates(in: modelContext)

        let stateIDs = Set(states.map(\.wordID))
        let unseenCandidates = catalogStore.fetchCandidateWords(
            language: language,
            limit: 0
        )
        .filter { !stateIDs.contains($0.id) && !excludedWordIDs.contains($0.id) }

        if let unseen = unseenCandidates.randomElement() {
            return catalogStore.fetchWord(id: unseen.id)
        }

        if let leastReviewed = states
            .filter({ !excludedWordIDs.contains($0.wordID) })
            .min(by: { $0.reviewCount < $1.reviewCount }) {
            return catalogStore.fetchWord(id: leastReviewed.wordID)
        }

        return catalogStore.fetchNotificationCandidateWords(limit: 25)
            .first(where: { !excludedWordIDs.contains($0.id) })
    }
}
