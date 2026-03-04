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

    @State var viewModel = HomeViewModel()
    @State private var notificationManager = NotificationManager.shared
    @StateObject var speechSynthesizer = SpeechSynthesizerManager()

    @Binding var selectedTab: AppTab

    @State var showingPronunciation = false
    @State var showingAchievementToast = false
    @State var achievementMessage = ""
    @State var showingXPAnimation = false
    @State var xpGained = 0
    // Consolidated sheet state
    @State var activeSheet: HomeSheet?
    @State private var hasInitializedHomeState = false

    // Phase 2: Collapsible sections (collapsed by default)
    @State var showAllExamples = false
    @State var usageNotesExpanded = false
    @State var relatedWordsExpanded = false
    @State var conjugationExpanded = false

    @State private var wordFeed: [LearnWordPayload] = []
    @State private var currentWordIndex = 0
    @State private var currentWordID: String?
    @State private var canLoadMoreWords = false
    @State private var isLoadingNextWord = false
    @State private var selectedPageByWordID: [String: WordCardPageKind] = [:]
    @State private var statsStripHeight: CGFloat = 0
    @State private var hasTriggeredBottomOverscrollLoad = false

    var todaysWord: LearnWordPayload? { viewModel.todaysWord }
    var activeWord: LearnWordPayload? {
        if let currentWordID,
           let resolvedWord = wordFeed.first(where: { $0.id == currentWordID }) {
            return resolvedWord
        }

        guard wordFeed.indices.contains(currentWordIndex) else {
            return wordFeed.last ?? todaysWord
        }

        return wordFeed[currentWordIndex]
    }
    var currentProgress: AppState { viewModel.currentProgress }
    var hasAvailableWords: Bool { viewModel.availableWordCount > 0 }
    var canAdvanceWordFeed: Bool {
        currentWordIndex < wordFeed.count - 1 || (canLoadMoreWords && hasAvailableWords)
    }

    var scrollableHome: some View {
        GeometryReader { geometry in
            let bottomReserved = max(geometry.safeAreaInsets.bottom, 20) + 96
            let availableHeight = max(geometry.size.height - statsStripHeight - 26 - bottomReserved, 280)

            VStack(spacing: 14) {
                compactStatsStrip
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: HomeStatsStripHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )

                if wordFeed.isEmpty {
                    Spacer(minLength: 0)
                    noWordsSection
                    Spacer(minLength: 0)
                } else {
                    verticalWordFeed(cardHeight: availableHeight)
                        .frame(height: availableHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onPreferenceChange(HomeStatsStripHeightPreferenceKey.self) { statsStripHeight = $0 }
    }

    private func verticalWordFeed(cardHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(wordFeed) { word in
                    HomeWordCardView(
                        word: word,
                        selectedPage: pageSelectionBinding(for: word),
                        speechSynthesizer: speechSynthesizer,
                        isPronunciationActive: showingPronunciation && activeWord?.id == word.id,
                        onPronounce: {
                            focusWord(id: word.id, animated: false)
                            pronounceWord()
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .frame(height: cardHeight)
                    .clipped()
                    .id(word.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentWordID)
        .onAppear(perform: syncCurrentWordIDWithFeed)
        .onChange(of: currentWordID) { _, newWordID in
            syncCurrentWordIndex(for: newWordID)
        }
        .onScrollGeometryChange(for: PagerOverscrollState.self) { geometry in
            let bottomOverscroll = max(
                0,
                geometry.contentOffset.y + geometry.visibleRect.height - geometry.contentSize.height
            )
            return PagerOverscrollState(bottomOverscroll: bottomOverscroll)
        } action: { _, state in
            handlePagerOverscroll(state.bottomOverscroll)
        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(L10n.Tabs.learn)
                        .font(DesignTokens.typography.callout(weight: .bold))
                        .foregroundStyle(DesignTokens.color.headingPrimary)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    topBarActionButton(
                        icon: "magnifyingglass",
                        label: L10n.Tabs.browse
                    ) {
                        selectedTab = .browse
                    }

                    topBarActionButton(
                        icon: "gearshape.fill",
                        label: L10n.Tabs.settings
                    ) {
                        selectedTab = .settings
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
                performInitialHomeSetupIfNeeded()
                openPendingNotificationWordIfNeeded()
            }
            .onChange(of: notificationManager.pendingNotificationWordID) { _, _ in
                openPendingNotificationWordIfNeeded()
            }
            .onChange(of: selectedTab) { _, newTab in
                guard newTab == .learn else { return }
                if hasInitializedHomeState {
                    syncHomeState()
                } else {
                    performInitialHomeSetupIfNeeded()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    syncHomeState()
                }
            }
    }

    func applyHomeSheets<V: View>(to view: V) -> some View {
        view
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
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
        viewModel.sync(modelContext: modelContext)
        refreshWordFeedFromViewModel()
    }

    func performInitialHomeSetupIfNeeded() {
        guard !hasInitializedHomeState else { return }

        hasInitializedHomeState = true
        syncHomeState()
    }

    private func refreshWordFeedFromViewModel() {
        guard let latestWord = viewModel.todaysWord else {
            wordFeed = []
            currentWordIndex = 0
            currentWordID = nil
            canLoadMoreWords = false
            selectedPageByWordID.removeAll()
            return
        }

        canLoadMoreWords = viewModel.availableWordCount > 1
        let previousVisibleWordID = currentWordID

        if let existingIndex = wordFeed.firstIndex(where: { $0.id == latestWord.id }) {
            ensurePageState(for: wordFeed[existingIndex])

            if let previousVisibleWordID,
               let previousVisibleIndex = wordFeed.firstIndex(where: { $0.id == previousVisibleWordID }) {
                currentWordIndex = previousVisibleIndex
                currentWordID = previousVisibleWordID
            } else {
                currentWordIndex = existingIndex
                currentWordID = latestWord.id
            }

            return
        }

        if wordFeed.isEmpty {
            wordFeed = [latestWord]
            ensurePageState(for: latestWord)
            currentWordIndex = 0
            currentWordID = latestWord.id
            return
        }

        wordFeed.append(latestWord)
        ensurePageState(for: latestWord)
        currentWordIndex = wordFeed.count - 1
        currentWordID = latestWord.id
        hasTriggeredBottomOverscrollLoad = false
    }

    private func requestAndShowNextWord() {
        guard canLoadMoreWords && hasAvailableWords else {
            return
        }
        guard !isLoadingNextWord else { return }

        isLoadingNextWord = true
        let currentWordID = activeWord?.id
        handleNewWordRequest()
        isLoadingNextWord = false

        guard let latestWord = viewModel.todaysWord else {
            canLoadMoreWords = false
            return
        }

        canLoadMoreWords = viewModel.availableWordCount > 1

        if let existingIndex = wordFeed.firstIndex(where: { $0.id == latestWord.id }) {
            focusWord(at: existingIndex, animated: true)
            return
        }

        guard latestWord.id != currentWordID else {
            return
        }

        if wordFeed.last?.id != latestWord.id {
            wordFeed.append(latestWord)
            ensurePageState(for: latestWord)
        }

        focusWord(at: wordFeed.count - 1, animated: true)
    }

    private func openPendingNotificationWordIfNeeded() {
        guard let wordID = notificationManager.consumePendingNotificationWordID() else { return }

        if !hasInitializedHomeState {
            performInitialHomeSetupIfNeeded()
        }

        selectedTab = .learn
        viewModel.presentWord(id: wordID)
        refreshWordFeedFromViewModel()
        if let targetWord = wordFeed.first(where: { $0.id == wordID }) {
            resetPageState(for: targetWord)
        }
        focusWord(id: wordID, animated: false)
    }

    private func handlePagerOverscroll(_ bottomOverscroll: CGFloat) {
        guard currentWordIndex == wordFeed.count - 1 else {
            hasTriggeredBottomOverscrollLoad = false
            return
        }

        guard canLoadMoreWords && hasAvailableWords else { return }

        if bottomOverscroll < 12 {
            hasTriggeredBottomOverscrollLoad = false
            return
        }

        guard bottomOverscroll > 72 else { return }
        guard !hasTriggeredBottomOverscrollLoad else { return }

        hasTriggeredBottomOverscrollLoad = true
        requestAndShowNextWord()
    }

    private func syncCurrentWordIDWithFeed() {
        guard !wordFeed.isEmpty else {
            currentWordID = nil
            return
        }

        if let currentWordID, wordFeed.contains(where: { $0.id == currentWordID }) {
            return
        }

        currentWordID = wordFeed[safe: currentWordIndex]?.id ?? wordFeed.first?.id
    }

    private func syncCurrentWordIndex(for wordID: String?) {
        guard let wordID,
              let index = wordFeed.firstIndex(where: { $0.id == wordID }) else { return }

        currentWordIndex = index
        ensurePageState(for: wordFeed[index])
        hasTriggeredBottomOverscrollLoad = false
    }

    private func focusWord(at index: Int, animated: Bool) {
        guard wordFeed.indices.contains(index) else { return }
        let wordID = wordFeed[index].id

        currentWordIndex = index
        hasTriggeredBottomOverscrollLoad = false

        if animated {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                currentWordID = wordID
            }
        } else {
            currentWordID = wordID
        }
    }

    private func focusWord(id wordID: String, animated: Bool) {
        guard let index = wordFeed.firstIndex(where: { $0.id == wordID }) else { return }
        focusWord(at: index, animated: animated)
    }

    private func pageSelectionBinding(for word: LearnWordPayload) -> Binding<WordCardPageKind> {
        Binding {
            let availableKinds = Set(wordCardPages(for: word).map(\.kind))
            let storedPage = selectedPageByWordID[word.id]
            return storedPage.flatMap { availableKinds.contains($0) ? $0 : nil } ?? defaultWordCardPageKind(for: word)
        } set: { newValue in
            selectedPageByWordID[word.id] = newValue
        }
    }

    private func ensurePageState(for word: LearnWordPayload) {
        let availableKinds = Set(wordCardPages(for: word).map(\.kind))
        if let selectedPage = selectedPageByWordID[word.id], availableKinds.contains(selectedPage) {
            return
        }

        selectedPageByWordID[word.id] = defaultWordCardPageKind(for: word)
    }

    private func resetPageState(for word: LearnWordPayload) {
        selectedPageByWordID[word.id] = defaultWordCardPageKind(for: word)
    }

    @ViewBuilder
    private func topBarActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignTokens.color.headingPrimary)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.76))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.88), lineWidth: 1)
                        )
                )
                .shadow(color: Color(red: 0.19, green: 0.37, blue: 0.72).opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(label)
    }

}

private struct PagerOverscrollState: Equatable {
    let bottomOverscroll: CGFloat
}

private struct HomeStatsStripHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

enum HomeSheet: Identifiable, Equatable {
    case stats

    var id: String {
        switch self {
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
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
