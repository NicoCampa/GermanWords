//
//  ContentView.swift
//  aWordaDay
//
//  Created by Nicolò Campagnoli on 18.07.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query var words: [Word]
    @Query var userProgress: [UserProgress]

    @State var viewModel = HomeViewModel()
    @StateObject var speechSynthesizer = SpeechSynthesizerManager()

    @Binding var selectedTab: AppTab

    @State var showingPronunciation = false
    @State var showingAchievementToast = false
    @State var achievementMessage = ""
    @State var showingXPAnimation = false
    @State var xpGained = 0
    // Consolidated sheet state
    @State var activeSheet: HomeSheet?

    // Phase 2: Collapsible sections (collapsed by default)
    @State var showAllExamples = false
    @State var usageNotesExpanded = false
    @State var relatedWordsExpanded = false
    @State var conjugationExpanded = false

    // ScrollViewProxy for FAB scroll-to-top
    @State var scrollProxy: ScrollViewProxy?

    var todaysWord: Word? { viewModel.todaysWord }
    var currentProgress: UserProgress { viewModel.currentProgress }
    var availableWords: [Word] { viewModel.availableWords }
    var wordsSeenToday: [Word] { viewModel.wordsSeenToday }
    var learnedWords: [Word] { viewModel.learnedWords }

    var scrollableHome: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    homeSections
                        .frame(width: geometry.size.width)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onAppear { scrollProxy = proxy }
            }
        }
    }

    var homeSections: some View {
        VStack(spacing: 14) {
            Color.clear.frame(height: 0).id("top")

            // Compact stats strip
            compactStatsStrip

            if let word = todaysWord {
                todaysWordSection(word)
                    .id(word.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                noWordsSection
            }
        }
        .padding(.bottom, 20)
        .clipped()
    }

    var achievementOverlay: some View {
        VStack {
            if showingAchievementToast {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    Text(achievementMessage)
                        .font(DesignTokens.typography.callout(weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            DesignTokens.color.success,
                            DesignTokens.color.success.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: DesignTokens.color.success.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 20)
                .padding(.top, 80)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            Spacer()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingAchievementToast)
    }

    var rootNavigationView: some View {
        NavigationStack {
            ZStack {
                HomeBackgroundView()
                scrollableHome
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    floatingNextButton
                    if showingXPAnimation {
                        XPPopupView(xpAmount: xpGained)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                            .padding(.bottom, 70)
                            .padding(.trailing, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                #if DEBUG
                print("[ContentView] appeared with language=\(AppLanguage.sourceCode) level=\(currentProgress.currentLevel)")
                #endif
                FirebaseAnalyticsManager.shared.logScreenView(FirebaseAnalyticsManager.Screen.home)
            }
        }
    }

    var body: some View {
        let baseView = rootNavigationView.overlay(achievementOverlay)
        return applyHomeSheets(to: baseView)
            .onAppear {
                syncHomeState()
                currentProgress.loadInitialDataIfNeeded(modelContext: modelContext)
                try? modelContext.save()
            }
            .onChange(of: words) {
                syncHomeState()
            }
            .onChange(of: userProgress) {
                syncHomeState()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.refreshDailyWordIfNeeded()
                }
            }
    }

    func applyHomeSheets<V: View>(to view: V) -> some View {
        view
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .chat:
                    ChatView(word: todaysWord, isSheet: true)
                case .stats:
                    NavigationStack {
                        StatsTab()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(L10n.Common.done) { activeSheet = nil }
                                        .font(DesignTokens.typography.body())
                                        .foregroundStyle(DesignTokens.color.primary)
                                }
                            }
                    }
                }
            }
    }

    func syncHomeState() {
        viewModel.sync(modelContext: modelContext, words: words, userProgress: userProgress)
    }

}

enum HomeSheet: Identifiable, Equatable {
    case chat
    case stats

    var id: String {
        switch self {
        case .chat: return "chat"
        case .stats: return "stats"
        }
    }
}

enum ProgressStat: String, Identifiable {
    case streak
    case learned
    case level

    var id: String { rawValue }

    var title: String {
        switch self {
        case .streak: return L10n.Progress.streakTitle
        case .learned: return L10n.Progress.wordsLearnedTitle
        case .level: return L10n.Progress.levelTitle
        }
    }
}

#Preview {
    ContentView(selectedTab: .constant(.learn))
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
