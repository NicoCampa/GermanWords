//
//  BrowseWordsView.swift
//  aWordaDay
//
//  Created by Claude on 15.10.25.
//

import SwiftUI
import SwiftData

struct BrowseWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWords: [Word]

    @State private var searchText = ""
    @State private var showOnlyFavorites = false
    @State private var progressFilter: ProgressFilter = .all
    @State private var difficultyFilter: DifficultyFilter = .all
    @State private var sortOption: SortOption = .dateAdded
    @State private var expandedWordId: String? = nil

    private let allowedWordIDs: Set<String>?
    private let isEmbedded: Bool

    init(allowedWordIDs: Set<String>? = nil, isEmbedded: Bool = false) {
        self.allowedWordIDs = allowedWordIDs
        self.isEmbedded = isEmbedded
    }

    @StateObject private var speechSynthesizer = SpeechSynthesizerManager()

    private var baseWords: [Word] {
        guard let allowedWordIDs else {
            return allWords
        }
        return allWords.filter { allowedWordIDs.contains($0.id) }
    }

    private var languageWords: [Word] {
        baseWords.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }

    private var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if showOnlyFavorites { count += 1 }
        if progressFilter != .all { count += 1 }
        if difficultyFilter != .all { count += 1 }
        return count
    }

    // Filtered and sorted words
    private var filteredWords: [Word] {
        var words = languageWords

        // Filter by search text
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.translation.localizedCaseInsensitiveContains(searchText) ||
                (word.usageNotes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter favorites
        if showOnlyFavorites {
            words = words.filter { $0.isFavorite }
        }

        // Filter progress
        switch progressFilter {
        case .all:
            break
        case .learning:
            words = words.filter { !$0.isLearned }
        case .learned:
            words = words.filter { $0.isLearned }
        case .dueReview:
            words = words.filter { $0.isDueForReview }
        }

        // Filter difficulty
        switch difficultyFilter {
        case .all:
            break
        case .easy:
            words = words.filter { $0.difficultyLevel <= 1 }
        case .medium:
            words = words.filter { $0.difficultyLevel == 2 }
        case .hard:
            words = words.filter { $0.difficultyLevel >= 3 }
        }

        // Sort
        switch sortOption {
        case .dateAdded:
            words = words.sorted { $0.dateAdded > $1.dateAdded }
        case .alphabetical:
            words = words.sorted { $0.word < $1.word }
        case .difficulty:
            words = words.sorted { $0.difficultyLevel < $1.difficultyLevel }
        }

        return words
    }
    
    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                    // Search bar
                    searchBar

                    // Filter chips
                    filterChips

                    // Word list
                    if filteredWords.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignTokens.spacing.md) {
                                ForEach(filteredWords) { word in
                                    wordCard(word)
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
                            Button(action: {
                                sortOption = option
                            }) {
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
            FirebaseAnalyticsManager.shared.logScreenView("Browse Words")
        }
    }

    // MARK: - Search Bar

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
                Button(action: {
                    searchText = ""
                }) {
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

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Word count
                Text("\(filteredWords.count)")
                    .font(DesignTokens.typography.caption(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(DesignTokens.color.cardBackground)
                    )

                FilterChip(
                    title: L10n.Browse.favorites,
                    icon: "star.fill",
                    isSelected: showOnlyFavorites,
                    action: { showOnlyFavorites.toggle() }
                )

                ForEach(ProgressFilter.quickFilters, id: \.self) { option in
                    FilterChip(
                        title: option.title,
                        icon: option.icon,
                        isSelected: progressFilter == option,
                        action: {
                            progressFilter = progressFilter == option ? .all : option
                        }
                    )
                }

                // Divider dot between progress and difficulty
                Circle()
                    .fill(DesignTokens.color.textMuted.opacity(0.3))
                    .frame(width: 4, height: 4)

                ForEach(DifficultyFilter.quickFilters, id: \.self) { option in
                    FilterChip(
                        title: option.title,
                        icon: option.icon,
                        isSelected: difficultyFilter == option,
                        action: {
                            difficultyFilter = difficultyFilter == option ? .all : option
                        }
                    )
                }

                if hasActiveFilters {
                    Button(action: { clearAllFilters() }) {
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

    // MARK: - Word Card

    private func wordCard(_ word: Word) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content - always visible
            VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.spacing.md) {
                    // Learned indicator
                    Circle()
                        .fill(word.isLearned ? DesignTokens.color.success : DesignTokens.color.textMuted)
                        .frame(width: 10, height: 10)
                        .padding(.top, 7)
                        .accessibilityLabel(word.isLearned ? L10n.Browse.learned : L10n.Browse.notLearned)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.displayWord)
                            .font(DesignTokens.typography.headline(weight: .bold))
                            .foregroundStyle(DesignTokens.color.textPrimary)

                        Text(word.localizedTranslation)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textLight)
                    }

                    Spacer()

                    // Favorite button
                    Button(action: {
                        HapticFeedback.light()
                        word.isFavorite.toggle()
                        try? modelContext.save()
                    }) {
                        Image(systemName: word.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(word.isFavorite ? DesignTokens.color.gold : DesignTokens.color.textMuted)
                    }
                    .accessibilityLabel(word.isFavorite ? L10n.WordDetail.removeFromFavorites : L10n.WordDetail.addToFavorites)
                }

                // Badges row
                HStack(spacing: DesignTokens.spacing.sm) {
                    // Difficulty badge
                    BadgeView(text: word.displayDifficulty, color: DesignTokens.color.info)

                    Spacer()

                    // Listen button
                    Button(action: {
                        pronounceWord(word)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.pronunciationAccent)
                    }
                    .accessibilityLabel("Listen to \(word.word)")

                    // Expand/collapse button
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            expandedWordId = expandedWordId == word.id ? nil : word.id
                        }
                    }) {
                        Image(systemName: expandedWordId == word.id ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textMuted)
                    }
                }
            }
            .padding(DesignTokens.spacing.lg)

            // Expanded content
            if expandedWordId == word.id {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                    Divider()
                        .padding(.horizontal, DesignTokens.spacing.lg)

                    if let usageNotes = word.localizedUsageNotes, !usageNotes.isEmpty {
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

                    // Examples
                    if !word.examples.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                            Text(L10n.Common.examples)
                                .font(DesignTokens.typography.footnote(weight: .bold))
                                .foregroundStyle(DesignTokens.color.textSubtle)
                                .textCase(.uppercase)

                            ForEach(word.localizedExamplePairs, id: \.0) { example, translation in
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

    // MARK: - Empty State

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

    // MARK: - Helper Functions

    private func clearAllFilters() {
        searchText = ""
        showOnlyFavorites = false
        progressFilter = .all
        difficultyFilter = .all
    }

    private func pronounceWord(_ word: Word) {
        speechSynthesizer.speak(
            text: word.word,
            language: word.pronunciationCode,
            style: .normal
        )

        FirebaseAnalyticsManager.shared.logWordListened(
            word: word.word,
            language: word.sourceLanguage
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
}

// MARK: - Supporting Views

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
                            colors: [
                                DesignTokens.color.info,
                                DesignTokens.color.primary
                            ],
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
        }
        .foregroundStyle(isSelected ? Color.white : DesignTokens.color.textTertiary)
        .padding(.horizontal, DesignTokens.spacing.md)
        .padding(.vertical, DesignTokens.spacing.sm)
        .background(
            Capsule()
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            DesignTokens.color.info,
                            DesignTokens.color.primary
                        ],
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

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DesignTokens.typography.footnote(weight: .bold))
                Text(label)
                    .font(DesignTokens.typography.footnote(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textMuted)
            }
        }
        .foregroundStyle(DesignTokens.color.interactiveBlue)
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
        .modelContainer(for: [Word.self, UserProgress.self, ChatHistoryMessage.self], inMemory: true)
}
