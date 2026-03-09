//
//  BrowseWordsView.swift
//  aWordaDay
//

import SwiftData
import SwiftUI

struct BrowseWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showOnlyFavorites = false
    @State private var difficultyFilter: DifficultyFilter = .all
    @State private var sortOption: SortOption = .dateAdded
    @State private var expandedWordId: String?
    @State private var visibleWords: [BrowseWordRow] = []
    @State private var totalCount = 0
    @State private var page = 1
    @State private var hasMorePages = false
    @State private var isLoading = false
    @State private var pendingReloadTask: Task<Void, Never>?

    private let browseService = BrowseService()
    private let userStateStore = SwiftDataUserStateStore()
    private let showsOnlyViewedWords: Bool
    private let isEmbedded: Bool

    init(showsOnlyViewedWords: Bool = false, isEmbedded: Bool = false) {
        self.showsOnlyViewedWords = showsOnlyViewedWords
        self.isEmbedded = isEmbedded
    }

    @StateObject private var speechSynthesizer = SpeechSynthesizerManager()

    private var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if showOnlyFavorites { count += 1 }
        if difficultyFilter != .all { count += 1 }
        return count
    }

    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        DesignTokens.color.backgroundLight,
                        DesignTokens.color.backgroundMedium
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    filterChips

                    if isLoading && visibleWords.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if visibleWords.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignTokens.spacing.md) {
                                ForEach(visibleWords) { row in
                                    wordCard(row)
                                        .onAppear {
                                            loadNextPageIfNeeded(for: row)
                                        }
                                }

                                if hasMorePages && isLoading {
                                    ProgressView()
                                        .padding(.vertical, DesignTokens.spacing.lg)
                                }
                            }
                            .padding(.horizontal, DesignTokens.spacing.lg)
                            .padding(.vertical, DesignTokens.spacing.md)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Browse.browseWords)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEmbedded {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(L10n.Common.close) {
                            dismiss()
                        }
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.title)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.primary)
                    }
                }
            }
        }
        .onAppear {
            reload(reset: true, debounced: false)
            FirebaseAnalyticsManager.shared.logScreenView("Browse Words")
        }
        .onChange(of: searchText) { reload(reset: true, debounced: true) }
        .onChange(of: showOnlyFavorites) { reload(reset: true, debounced: false) }
        .onChange(of: difficultyFilter) { reload(reset: true, debounced: false) }
        .onChange(of: sortOption) { reload(reset: true, debounced: false) }
    }

    private var searchBar: some View {
        HStack(spacing: DesignTokens.spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.color.textSubtle)

            TextField(L10n.Browse.searchPlaceholder, text: $searchText)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DesignTokens.color.textMuted)
                }
            }
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.vertical, DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(DesignTokens.color.cardBackground)
                .designSystemShadow(DesignTokens.shadow.light)
        )
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.top, DesignTokens.spacing.md)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: L10n.Browse.favorites,
                    icon: "heart.fill",
                    isSelected: showOnlyFavorites,
                    action: { showOnlyFavorites.toggle() }
                )

                Menu {
                    Button {
                        difficultyFilter = .all
                    } label: {
                        HStack {
                            Text(L10n.Browse.all)
                            if difficultyFilter == .all {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    ForEach(DifficultyFilter.quickFilters, id: \.self) { option in
                        Button {
                            difficultyFilter = option
                        } label: {
                            HStack {
                                Text(option.title)
                                if difficultyFilter == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChipLabel(
                        title: difficultyMenuTitle,
                        icon: "line.3.horizontal.decrease.circle",
                        isSelected: difficultyFilter != .all
                    )
                }

                if hasActiveFilters {
                    Button(action: clearAllFilters) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DesignTokens.color.primary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing.lg)
        }
        .padding(.vertical, DesignTokens.spacing.sm)
    }

    private func wordCard(_ row: BrowseWordRow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.spacing.md) {
                    Circle()
                        .fill(row.isLearned ? DesignTokens.color.success : DesignTokens.color.textMuted)
                        .frame(width: 10, height: 10)
                        .padding(.top, 7)
                        .accessibilityLabel(row.isLearned ? L10n.Browse.learned : L10n.Browse.notLearned)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.displayWord)
                            .font(DesignTokens.typography.headline(weight: .bold))
                            .foregroundStyle(DesignTokens.color.textPrimary)

                        Text(row.localizedTranslation)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textLight)
                    }

                    Spacer()

                    Button {
                        HapticFeedback.light()
                        toggleFavorite(for: row)
                    } label: {
                        Image(systemName: row.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(row.isFavorite ? DesignTokens.color.difficultyHard : DesignTokens.color.textMuted)
                    }
                    .accessibilityLabel(row.isFavorite ? L10n.WordDetail.removeFromFavorites : L10n.WordDetail.addToFavorites)
                }

                HStack(spacing: DesignTokens.spacing.sm) {
                    BadgeView(text: row.displayDifficulty, color: DesignTokens.color.info)

                    Spacer()

                    Button {
                        pronounceWord(row)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.pronunciationAccent)
                    }
                    .accessibilityLabel("Listen to \(row.word)")

                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            expandedWordId = expandedWordId == row.id ? nil : row.id
                        }
                    } label: {
                        Image(systemName: expandedWordId == row.id ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textMuted)
                    }
                }
            }
            .padding(DesignTokens.spacing.lg)

            if expandedWordId == row.id {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                    Divider()
                        .padding(.horizontal, DesignTokens.spacing.lg)

                    if let usageNotes = row.localizedUsageNotes, !usageNotes.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                            Text(L10n.WordDetail.usageNotes)
                                .font(DesignTokens.typography.footnote(weight: .bold))
                                .foregroundStyle(DesignTokens.color.textSubtle)
                                .textCase(.uppercase)

                            Text(usageNotes)
                                .font(DesignTokens.typography.callout(weight: .medium))
                                .foregroundStyle(DesignTokens.color.textTertiary)
                        }
                        .padding(.horizontal, DesignTokens.spacing.lg)
                    }

                    if !row.examples.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                            Text(L10n.Common.examples)
                                .font(DesignTokens.typography.footnote(weight: .bold))
                                .foregroundStyle(DesignTokens.color.textSubtle)
                                .textCase(.uppercase)

                            ForEach(row.localizedExamplePairs, id: \.0) { example, translation in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(example)
                                        .font(DesignTokens.typography.caption(weight: .medium))
                                        .foregroundStyle(DesignTokens.color.textTertiary)
                                        .italic()

                                    Text("→ \(translation)")
                                        .font(DesignTokens.typography.caption(weight: .regular))
                                        .foregroundStyle(DesignTokens.color.textLight)
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.spacing.lg)
                        .padding(.bottom, DesignTokens.spacing.lg)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: DesignTokens.color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.spacing.xl) {
            Spacer()

            SharedCloudMascot(scale: 0.6)
                .frame(width: 90, height: 90)

            VStack(spacing: DesignTokens.spacing.md) {
                Text(L10n.Browse.noWordsFound)
                    .font(DesignTokens.typography.title(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textPrimary)

                Text(L10n.Browse.adjustFilters)
                    .font(DesignTokens.typography.callout(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textSubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.spacing.xxl)

                if hasActiveFilters {
                    VStack(spacing: DesignTokens.spacing.md) {
                        Text(L10n.Browse.suggestions)
                            .font(DesignTokens.typography.caption(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textSubtle)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                            suggestionChip(label: L10n.Browse.clearFilters, icon: "line.3.horizontal.decrease.circle") {
                                clearAllFilters()
                            }

                            if !searchText.isEmpty {
                                suggestionChip(label: L10n.Browse.resetSearch, icon: "text.magnifyingglass") {
                                    searchText = ""
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing.lg)
                }
            }

            Spacer()
        }
    }

    private func clearAllFilters() {
        searchText = ""
        showOnlyFavorites = false
        difficultyFilter = .all
    }

    private func reload(reset: Bool, debounced: Bool) {
        pendingReloadTask?.cancel()

        let action = { @MainActor in
            if reset {
                page = 1
                expandedWordId = nil
            }
            loadPage(reset: reset)
        }

        if debounced {
            pendingReloadTask = Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                action()
            }
        } else {
            Task { action() }
        }
    }

    private func loadPage(reset: Bool) {
        guard !isLoading else { return }
        isLoading = true

        let query = BrowseQuery(
            searchText: searchText,
            favoritesOnly: showOnlyFavorites,
            progressFilter: .all,
            difficultyFilter: difficultyFilter,
            sortOption: sortOption,
            page: page,
            pageSize: 60,
            visibleOnly: showsOnlyViewedWords,
            sourceLanguage: AppLanguage.sourceCode
        )

        let result = browseService.fetchPage(query: query, modelContext: modelContext, showsOnlyViewedWords: showsOnlyViewedWords)
        if reset {
            visibleWords = result.rows
        } else {
            let newRows = result.rows.filter { row in
                !visibleWords.contains(where: { $0.id == row.id })
            }
            visibleWords.append(contentsOf: newRows)
        }

        totalCount = result.totalCount
        hasMorePages = result.hasMorePages
        isLoading = false
    }

    private func loadNextPageIfNeeded(for row: BrowseWordRow) {
        guard row.id == visibleWords.last?.id, hasMorePages, !isLoading else { return }
        page += 1
        loadPage(reset: false)
    }

    private func toggleFavorite(for row: BrowseWordRow) {
        let snapshot = userStateStore.toggleFavorite(in: modelContext, wordID: row.id)
        try? modelContext.save()

        if let index = visibleWords.firstIndex(where: { $0.id == row.id }) {
            let updated = BrowseWordRow(detail: visibleWords[index].detail, state: snapshot)
            if showOnlyFavorites && !snapshot.isFavorite {
                visibleWords.remove(at: index)
                totalCount = max(totalCount - 1, 0)
            } else {
                visibleWords[index] = updated
            }
        }
    }

    private func pronounceWord(_ row: BrowseWordRow) {
        speechSynthesizer.speak(
            text: row.word,
            language: row.pronunciationCode,
            style: .normal
        )

        FirebaseAnalyticsManager.shared.logWordListened(
            word: row.word,
            language: row.sourceLanguage
        )
    }

    private func suggestionChip(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(DesignTokens.typography.caption(weight: .semibold))
            }
            .foregroundStyle(DesignTokens.color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DesignTokens.color.primary.opacity(0.1))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var difficultyMenuTitle: String {
        switch difficultyFilter {
        case .all:
            return L10n.Browse.difficulty
        case .easy:
            return L10n.Difficulty.easy
        case .medium:
            return L10n.Difficulty.medium
        case .hard:
            return L10n.Difficulty.hard
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(DesignTokens.typography.caption(weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.white : DesignTokens.color.textTertiary)
            .padding(.horizontal, DesignTokens.spacing.md)
            .padding(.vertical, DesignTokens.spacing.sm)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [DesignTokens.color.info, DesignTokens.color.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [DesignTokens.color.cardBackground, DesignTokens.color.cardBackground],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .designSystemShadow(DesignTokens.shadow.light)
            )
        }
    }
}

struct FilterChipLabel: View {
    let title: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(DesignTokens.typography.caption(weight: .semibold))
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(isSelected ? Color.white : DesignTokens.color.textTertiary)
        .padding(.horizontal, DesignTokens.spacing.md)
        .padding(.vertical, DesignTokens.spacing.sm)
        .background(
            Capsule()
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [DesignTokens.color.info, DesignTokens.color.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [DesignTokens.color.cardBackground, DesignTokens.color.cardBackground],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .designSystemShadow(DesignTokens.shadow.light)
        )
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DesignTokens.typography.footnote(weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.spacing.sm)
            .padding(.vertical, DesignTokens.spacing.xs)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

enum ProgressFilter: CaseIterable {
    case all
    case learning
    case learned
    case dueReview

    static var quickFilters: [ProgressFilter] {
        [.learning, .learned, .dueReview]
    }

    var title: String {
        switch self {
        case .all: return L10n.Browse.all
        case .learning: return L10n.Browse.learning
        case .learned: return L10n.Browse.learned
        case .dueReview: return L10n.Browse.due
        }
    }

    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .learning: return "bolt.fill"
        case .learned: return "checkmark.circle.fill"
        case .dueReview: return "clock.arrow.circlepath"
        }
    }
}

enum DifficultyFilter: CaseIterable {
    case all
    case easy
    case medium
    case hard

    static var quickFilters: [DifficultyFilter] {
        [.easy, .medium, .hard]
    }

    var title: String {
        switch self {
        case .all: return L10n.Browse.all
        case .easy: return L10n.Difficulty.easy
        case .medium: return L10n.Difficulty.medium
        case .hard: return L10n.Difficulty.hard
        }
    }

    var icon: String {
        switch self {
        case .all: return "dial.low.fill"
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}

enum SortOption: CaseIterable {
    case dateAdded
    case alphabetical
    case difficulty

    var title: String {
        switch self {
        case .dateAdded: return L10n.Browse.dateAdded
        case .alphabetical: return L10n.Browse.alphabetical
        case .difficulty: return L10n.Browse.difficulty
        }
    }
}

#Preview {
    BrowseWordsView()
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
