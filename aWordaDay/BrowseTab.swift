//
//  BrowseTab.swift
//  aWordaDay
//
//  Thin wrapper around BrowseWordsView for use as a tab.
//

import SwiftUI
import SwiftData

struct BrowseTab: View {
    @Query private var words: [Word]

    private var learnedWordIDs: Set<String> {
        Set(
            words
                .filter { $0.timesViewed > 0 && $0.sourceLanguage == AppLanguage.sourceCode }
                .map(\.id)
        )
    }

    var body: some View {
        BrowseWordsView(allowedWordIDs: learnedWordIDs, isEmbedded: true)
    }
}

#Preview {
    BrowseTab()
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
