//
//  BrowseTab.swift
//  aWordaDay
//
//  Thin wrapper around BrowseWordsView for use as a tab.
//

import SwiftUI

struct BrowseTab: View {
    var body: some View {
        BrowseWordsView(showsOnlyViewedWords: true, isEmbedded: true)
    }
}

#Preview {
    BrowseTab()
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
