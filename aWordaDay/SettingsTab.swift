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
    @Query private var appStates: [AppState]

    private var currentProgress: AppState {
        AppState.current(in: modelContext, cached: appStates)
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
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
