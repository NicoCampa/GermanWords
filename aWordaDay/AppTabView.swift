//
//  AppTabView.swift
//  aWordaDay
//
//  Root tab container replacing ContentView as the app's main view.
//

import SwiftUI

enum AppTab: Hashable {
    case learn
    case browse
    case settings
}

struct AppTabView: View {
    @State private var selectedTab: AppTab = .learn

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.Tabs.learn, systemImage: "book.fill")
                }
                .tag(AppTab.learn)

            BrowseTab()
                .tabItem {
                    Label(L10n.Tabs.browse, systemImage: "text.magnifyingglass")
                }
                .tag(AppTab.browse)

SettingsTab()
                .tabItem {
                    Label(L10n.Tabs.settings, systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tabViewStyle(.tabBarOnly)
        .tint(DesignTokens.color.primary)
    }
}

#Preview {
    AppTabView()
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
