//
//  ContentView.swift
//  aWordaDay
//
//  Created by Nicolò Campagnoli on 18.07.25.
//

import SwiftUI
import SwiftData
import UIKit

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
    @State private var isRebasingWordFeedSelection = false
    @State private var selectedPageByWordID: [String: WordCardPageKind] = [:]
    @State private var completedWordIDs: Set<String> = []

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
        VStack(spacing: 14) {
            compactStatsStrip

            if wordFeed.isEmpty {
                Spacer(minLength: 0)
                noWordsSection
                Spacer(minLength: 0)
            } else {
                GeometryReader { proxy in
                    verticalWordFeed(size: proxy.size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func verticalWordFeed(size: CGSize) -> some View {
        VerticalWordPager(pageCount: wordFeed.count, selection: $currentWordIndex) { index in
            wordFeedPage(for: wordFeed[index], size: size)
        }
        .onAppear(perform: syncCurrentWordIDWithFeed)
        .onAppear(perform: ensureLookaheadWordIfNeeded)
        .onChange(of: currentWordIndex) { oldIndex, newIndex in
            handleWordPageChange(from: oldIndex, to: newIndex)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func wordFeedPage(for word: LearnWordPayload, size: CGSize) -> some View {
        ZStack(alignment: .top) {
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
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipped()
        .id(word.id)
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
            completedWordIDs.removeAll()
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

            completedWordIDs.formIntersection(Set(wordFeed.map(\.id)))
            return
        }

        if wordFeed.isEmpty {
            wordFeed = [latestWord]
            ensurePageState(for: latestWord)
            currentWordIndex = 0
            currentWordID = latestWord.id
            completedWordIDs.removeAll()
            return
        }

        wordFeed.append(latestWord)
        ensurePageState(for: latestWord)
        currentWordIndex = wordFeed.count - 1
        currentWordID = latestWord.id
        completedWordIDs.formIntersection(Set(wordFeed.map(\.id)))
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
        ensureLookaheadWordIfNeeded()
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

    private func focusWord(at index: Int, animated: Bool) {
        guard wordFeed.indices.contains(index) else { return }
        let wordID = wordFeed[index].id

        let updateSelection = {
            currentWordIndex = index
        }
        currentWordID = wordID

        if animated {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                updateSelection()
            }
        } else {
            updateSelection()
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

    private func handleWordPageChange(from oldIndex: Int, to newIndex: Int) {
        guard wordFeed.indices.contains(newIndex) else { return }

        let newWord = wordFeed[newIndex]

        if isRebasingWordFeedSelection {
            isRebasingWordFeedSelection = false
            currentWordID = newWord.id
            ensurePageState(for: newWord)
            ensureLookaheadWordIfNeeded()
            return
        }

        currentWordID = newWord.id
        ensurePageState(for: newWord)

        if newIndex > oldIndex, wordFeed.indices.contains(oldIndex) {
            let previousWord = wordFeed[oldIndex]
            if completedWordIDs.insert(previousWord.id).inserted {
                viewModel.advanceToWord(
                    id: newWord.id,
                    from: previousWord.id,
                    onXPGained: { xp in triggerXPGainAnimation(amount: xp) },
                    onAchievement: { msg in showAchievementToast(msg) }
                )
            }

            rebaseWordFeed(keepingVisibleIndex: newIndex)
        }

        ensureLookaheadWordIfNeeded()
    }

    private func ensureLookaheadWordIfNeeded() {
        guard currentWordIndex >= wordFeed.count - 2 else { return }
        preloadNextWordIfNeeded()
    }

    private func preloadNextWordIfNeeded() {
        guard canLoadMoreWords && hasAvailableWords else { return }
        guard !isLoadingNextWord else { return }

        let excludedIDs = Set(wordFeed.map(\.id))
        let anchorWordID = wordFeed.last?.id

        isLoadingNextWord = true
        defer { isLoadingNextWord = false }

        guard let nextWord = viewModel.previewNextWord(after: anchorWordID, excluding: excludedIDs) else {
            canLoadMoreWords = false
            return
        }

        wordFeed.append(nextWord)
        ensurePageState(for: nextWord)
        canLoadMoreWords = viewModel.availableWordCount > 1
    }

    private func rebaseWordFeed(keepingVisibleIndex visibleIndex: Int) {
        guard visibleIndex > 0, wordFeed.indices.contains(visibleIndex) else { return }

        let visibleWordID = wordFeed[visibleIndex].id
        wordFeed.removeFirst(visibleIndex)
        completedWordIDs.formIntersection(Set(wordFeed.map(\.id)))

        if currentWordID == visibleWordID {
            isRebasingWordFeedSelection = true
            currentWordIndex = 0
        } else {
            currentWordID = wordFeed.first?.id
            currentWordIndex = 0
        }
    }

    @ViewBuilder
    private func topBarActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(DesignTokens.color.primary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct VerticalWordPager<Page: View>: UIViewControllerRepresentable {
    let pageCount: Int
    @Binding var selection: Int
    let content: (Int) -> Page

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        context.coordinator.syncControllers(with: self)

        if let initialController = context.coordinator.controller(at: clampedSelection) {
            controller.setViewControllers([initialController], direction: .forward, animated: false)
            context.coordinator.currentIndex = clampedSelection
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.syncControllers(with: self)

        let targetIndex = clampedSelection
        guard let targetController = context.coordinator.controller(at: targetIndex) else { return }

        let currentController = uiViewController.viewControllers?.first
        let currentIndex = context.coordinator.index(of: currentController) ?? context.coordinator.currentIndex

        guard currentIndex != targetIndex || currentController !== targetController else { return }

        let direction: UIPageViewController.NavigationDirection = targetIndex >= currentIndex ? .forward : .reverse
        uiViewController.setViewControllers([targetController], direction: direction, animated: false)
        context.coordinator.currentIndex = targetIndex
    }

    private var clampedSelection: Int {
        guard pageCount > 0 else { return 0 }
        return min(max(selection, 0), pageCount - 1)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalWordPager
        var controllers: [UIHostingController<AnyView>] = []
        var currentIndex = 0

        init(parent: VerticalWordPager) {
            self.parent = parent
        }

        func syncControllers(with parent: VerticalWordPager) {
            if controllers.count > parent.pageCount {
                controllers.removeLast(controllers.count - parent.pageCount)
            } else if controllers.count < parent.pageCount {
                let startIndex = controllers.count
                let newControllers = (startIndex..<parent.pageCount).map { index in
                    UIHostingController(rootView: AnyView(parent.content(index)))
                }
                controllers.append(contentsOf: newControllers)
            }

            for index in controllers.indices {
                controllers[index].rootView = AnyView(parent.content(index))
                controllers[index].view.backgroundColor = .clear
            }
        }

        func controller(at index: Int) -> UIViewController? {
            guard controllers.indices.contains(index) else { return nil }
            return controllers[index]
        }

        func index(of viewController: UIViewController?) -> Int? {
            guard let viewController else { return nil }
            return controllers.firstIndex { $0 === viewController }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = index(of: viewController), index > 0 else { return nil }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = index(of: viewController), index < controllers.count - 1 else { return nil }
            return controllers[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let visibleController = pageViewController.viewControllers?.first,
                  let index = index(of: visibleController) else {
                return
            }

            currentIndex = index

            guard parent.selection != index else { return }
            DispatchQueue.main.async {
                self.parent.selection = index
            }
        }
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
