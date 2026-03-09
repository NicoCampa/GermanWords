//
//  SwiftDataUserStateStore.swift
//  aWordaDay
//

import Foundation
import SwiftData

@MainActor
protocol UserStateStoreProtocol {
    func loadAppState(in modelContext: ModelContext) -> AppState
    func loadWordState(in modelContext: ModelContext, wordID: String) -> UserWordState
    func loadWordStates(in modelContext: ModelContext) -> [UserWordState]
    func loadWordStates(in modelContext: ModelContext, wordIDs: [String]) -> [String: UserWordStateSnapshot]
    func saveWordView(in modelContext: ModelContext, wordID: String, date: Date) -> UserWordViewResult
    func saveWordReview(in modelContext: ModelContext, wordID: String, quality: Int, date: Date) -> UserWordReviewResult
    func toggleFavorite(in modelContext: ModelContext, wordID: String) -> UserWordStateSnapshot
    func recordWordShown(in modelContext: ModelContext, wordID: String, date: Date)
    func resetAllUserState(in modelContext: ModelContext)
}

@MainActor
struct SwiftDataUserStateStore: UserStateStoreProtocol {
    func loadAppState(in modelContext: ModelContext) -> AppState {
        AppState.current(in: modelContext)
    }

    func loadWordState(in modelContext: ModelContext, wordID: String) -> UserWordState {
        if let existing = fetchWordState(in: modelContext, wordID: wordID) {
            return existing
        }

        let state = UserWordState(wordID: wordID)
        modelContext.insert(state)
        return state
    }

    func loadWordStates(in modelContext: ModelContext) -> [UserWordState] {
        do {
            return try modelContext.fetch(FetchDescriptor<UserWordState>())
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch UserWordState rows: \(error)")
            #endif
            return []
        }
    }

    func loadWordStates(in modelContext: ModelContext, wordIDs: [String]) -> [String: UserWordStateSnapshot] {
        guard !wordIDs.isEmpty else { return [:] }
        let idSet = Set(wordIDs)
        return loadWordStates(in: modelContext)
            .filter { idSet.contains($0.wordID) }
            .reduce(into: [:]) { partialResult, state in
                partialResult[state.wordID] = state.snapshot
            }
    }

    func saveWordView(in modelContext: ModelContext, wordID: String, date: Date) -> UserWordViewResult {
        let state = loadWordState(in: modelContext, wordID: wordID)
        return state.applyView(viewDate: date)
    }

    func saveWordReview(in modelContext: ModelContext, wordID: String, quality: Int, date: Date) -> UserWordReviewResult {
        let state = loadWordState(in: modelContext, wordID: wordID)
        let result = state.applyReview(quality: quality, reviewDate: date)
        return result
    }

    func toggleFavorite(in modelContext: ModelContext, wordID: String) -> UserWordStateSnapshot {
        let state = loadWordState(in: modelContext, wordID: wordID)
        state.isFavorite.toggle()
        return state.snapshot
    }

    func recordWordShown(in modelContext: ModelContext, wordID: String, date: Date) {
        let appState = loadAppState(in: modelContext)
        appState.recordWordShownToday(wordID, now: date)
    }

    func resetAllUserState(in modelContext: ModelContext) {
        do {
            for state in try modelContext.fetch(FetchDescriptor<UserWordState>()) {
                modelContext.delete(state)
            }
            for appState in try modelContext.fetch(FetchDescriptor<AppState>()) {
                modelContext.delete(appState)
            }
            try modelContext.save()
        } catch {
            #if DEBUG
            print("⚠️ Failed to reset user state: \(error)")
            #endif
        }
    }

    private func fetchWordState(in modelContext: ModelContext, wordID: String) -> UserWordState? {
        do {
            let predicate = #Predicate<UserWordState> { state in
                state.wordID == wordID
            }
            var descriptor = FetchDescriptor<UserWordState>(predicate: predicate)
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch word state for \(wordID): \(error)")
            #endif
            return nil
        }
    }
}
