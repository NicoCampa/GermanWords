//
//  LearnService.swift
//  aWordaDay
//

import Foundation

final class LearnService {
    private let catalogStore: CatalogStoreProtocol
    private let learningManager: LearningManagerProtocol

    init(
        catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared,
        learningManager: LearningManagerProtocol = LearningManager.shared
    ) {
        self.catalogStore = catalogStore
        self.learningManager = learningManager
    }

    func loadCandidatePool(language: String) -> [CatalogWord] {
        catalogStore.fetchCandidateWords(language: language, limit: 0)
    }

    func selectNextWord(
        candidates: [CatalogWord],
        statesByID: [String: UserWordStateSnapshot],
        context: LearnSelectionContext
    ) -> CatalogWord? {
        learningManager.selectNextWord(
            from: candidates,
            statesByID: statesByID,
            language: AppLanguage.sourceCode,
            lastWordID: context.currentWordID
        )
    }

    func makePayload(wordID: String, statesByID: [String: UserWordStateSnapshot]) -> LearnWordPayload? {
        guard let detail = catalogStore.fetchWord(id: wordID) else { return nil }
        let state = statesByID[wordID] ?? .empty(wordID: wordID)
        return LearnWordPayload(detail: detail, state: state)
    }
}
