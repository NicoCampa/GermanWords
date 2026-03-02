//
//  SettingsTab.swift
//  aWordaDay
//
//  Thin wrapper around SettingsView for use as a tab.
//

import SwiftUI
import SwiftData

struct SettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]

    private var currentProgress: UserProgress {
        UserProgress.current(in: modelContext, cached: userProgress)
    }

    var body: some View {
        SettingsView(
            currentProgress: currentProgress,
            modelContext: modelContext,
            isEmbedded: true
        )
    }
}

#Preview {
    SettingsTab()
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
