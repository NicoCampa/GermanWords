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
        .sheet(isPresented: browsePresentationBinding, onDismiss: dismissPresentedSection) {
            BrowseWordsView(showsOnlyViewedWords: true)
        }
        .sheet(isPresented: settingsPresentationBinding, onDismiss: dismissPresentedSection) {
            SettingsView(
                currentProgress: currentProgress,
                modelContext: modelContext
            )
        }
        .onAppear(perform: routePendingNotificationToLearnIfNeeded)
        .onChange(of: notificationManager.pendingNotificationWordID) { _, _ in
            routePendingNotificationToLearnIfNeeded()
        }
    }

    private var browsePresentationBinding: Binding<Bool> {
        Binding(
            get: { selectedTab == .browse },
            set: { isPresented in
                selectedTab = isPresented ? .browse : .learn
            }
        )
    }

    private var settingsPresentationBinding: Binding<Bool> {
        Binding(
            get: { selectedTab == .settings },
            set: { isPresented in
                selectedTab = isPresented ? .settings : .learn
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
