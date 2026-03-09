//
//  AppTabView.swift
//  aWordaDay
//
//  Root tab container replacing ContentView as the app's main view.
//

import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case learn
    case browse
    case settings
}

private enum PresentedAppSheet: String, Identifiable {
    case browse
    case settings

    var id: String { rawValue }
}

struct AppTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appStates: [AppState]
    @State private var selectedTab: AppTab = .learn
    @State private var notificationManager = NotificationManager.shared

    private var currentProgress: AppState {
        AppState.current(in: modelContext, cached: appStates)
    }

    var body: some View {
        ContentView(selectedTab: $selectedTab)
        .tint(DesignTokens.color.primary)
        .sheet(item: presentedSheetBinding, onDismiss: dismissPresentedSection) { sheet in
            switch sheet {
            case .browse:
                BrowseWordsView(showsOnlyViewedWords: true)
            case .settings:
                SettingsView(
                    currentProgress: currentProgress,
                    modelContext: modelContext
                )
            }
        }
        .onAppear(perform: routePendingNotificationToLearnIfNeeded)
        .onChange(of: notificationManager.pendingNotificationWordID) { _, _ in
            routePendingNotificationToLearnIfNeeded()
        }
    }

    private var presentedSheetBinding: Binding<PresentedAppSheet?> {
        Binding(
            get: {
                switch selectedTab {
                case .learn:
                    nil
                case .browse:
                    .browse
                case .settings:
                    .settings
                }
            },
            set: { sheet in
                switch sheet {
                case .browse:
                    selectedTab = .browse
                case .settings:
                    selectedTab = .settings
                case nil:
                    selectedTab = .learn
                }
            }
        )
    }

    private func routePendingNotificationToLearnIfNeeded() {
        guard notificationManager.pendingNotificationWordID != nil else { return }
        selectedTab = .learn
    }

    private func dismissPresentedSection() {
        selectedTab = .learn
    }
}

#Preview {
    AppTabView()
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
