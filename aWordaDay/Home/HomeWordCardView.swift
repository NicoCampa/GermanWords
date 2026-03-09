import SwiftUI

struct HomeWordCardView<WordType: WordDisplayable>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingExamplesSheet = false
    @State private var favoriteBurstVisible = false
    @State private var favoriteBurstScale: CGFloat = 0.55
    @State private var favoriteBurstOpacity = 0.0
    @State private var favoriteBurstOffset: CGFloat = 0
    @State private var favoriteRingScale: CGFloat = 0.78
    @State private var favoriteRingOpacity = 0.0

    let word: WordType
    @Binding var selectedPage: WordCardPageKind
    @ObservedObject var speechSynthesizer: SpeechSynthesizerManager
    let isFavorite: Bool
    let isPronunciationActive: Bool
    let onPronounce: () -> Void
    let onToggleFavorite: () -> Void

    private var pages: [WordCardPage] { wordCardPages(for: word) }
    private var pageKinds: [WordCardPageKind] { pages.map(\.kind) }

    private var selectedPageModel: WordCardPage {
        pages.first(where: { $0.kind == selectedPage }) ?? pages[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            heroSection

            VStack(alignment: .leading, spacing: 12) {
                pageHeader

                TabView(selection: $selectedPage) {
                    ForEach(pages) { page in
                        pageBody(for: page)
                            .tag(page.kind)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if pages.count > 1 {
                    pageDots
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.color.surfaceElevated,
                            DesignTokens.color.surfaceInset
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            isFavorite ? DesignTokens.color.difficultyHard : DesignTokens.color.surfaceStroke,
                            lineWidth: isFavorite ? 2 : 1
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            DesignTokens.color.difficultyHard.opacity(favoriteRingOpacity),
                            lineWidth: 5
                        )
                        .scaleEffect(favoriteRingScale)
                )
                .shadow(color: DesignTokens.color.panelShadow, radius: 20, x: 0, y: 12)
        )
        .overlay(alignment: .center) {
            if favoriteBurstVisible {
                favoriteConfirmationOverlay
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture(count: 2) {
            handleFavoriteToggle()
        }
        .sheet(isPresented: $isShowingExamplesSheet) {
            allExamplesSheet
        }
        .onAppear(perform: sanitizeSelectedPage)
        .onChange(of: pageKinds) { _, _ in
            sanitizeSelectedPage()
        }
        .onChange(of: word.id) { _, _ in
            isShowingExamplesSheet = false
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: isFavorite)
    }

    private var favoriteConfirmationOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Color.white)
                .shadow(color: DesignTokens.color.difficultyHard.opacity(0.22), radius: 8, x: 0, y: 4)

            Text("Favorite")
                .font(DesignTokens.typography.callout(weight: .bold))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.color.difficultyHard,
                            DesignTokens.color.warning
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: DesignTokens.color.difficultyHard.opacity(0.28), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(favoriteBurstScale)
        .opacity(favoriteBurstOpacity)
        .offset(y: favoriteBurstOffset)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        if let article = word.displayArticle {
                            Text(article)
                                .font(DesignTokens.typography.headline(weight: .semibold))
                                .foregroundStyle(wordCardGenderColor(for: word) ?? DesignTokens.color.textSubtle)
                        }

                        Text(word.displayWord)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(DesignTokens.color.textDark)
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                    }

                    Text(word.localizedTranslation)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.translationBlue)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onPronounce) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(isPronunciationActive ? Color.white : DesignTokens.color.headingPrimary)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                isPronunciationActive
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.color.success,
                                            DesignTokens.color.learningGreen
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(DesignTokens.color.surfaceInset)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        isPronunciationActive
                                        ? Color.white.opacity(0.22)
                                        : DesignTokens.color.surfaceStroke,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: DesignTokens.color.primary.opacity(isPronunciationActive ? 0.22 : 0.08), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Home.listenToPronunciation)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let pos = word.partOfSpeech, !pos.isEmpty {
                        inlineChip(text: pos.capitalized, color: DesignTokens.color.posGreen)
                    }

                    inlineChip(text: word.displayDifficulty, color: DesignTokens.color.difficultyGold)

                    if let plural = word.plural, !plural.isEmpty {
                        inlineChip(text: L10n.WordDetail.plural(plural), color: DesignTokens.color.purple)
                    }

                    if wordCardIsVerb(word) {
                        if let auxiliaryVerb = word.auxiliaryVerb, !auxiliaryVerb.isEmpty {
                            inlineChip(text: auxiliaryVerb, color: DesignTokens.color.accentBlue)
                        }

                        if let pastParticiple = word.pastParticiple, !pastParticiple.isEmpty {
                            inlineChip(text: pastParticiple, color: DesignTokens.color.accentBlue)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 2)
    }

    private var pageHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(pages) { page in
                    Button {
                        selectedPage = page.kind
                    } label: {
                        Text(page.shortTitle)
                            .font(DesignTokens.typography.footnote(weight: .bold))
                            .foregroundStyle(page.kind == selectedPage ? Color.white : DesignTokens.color.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        page.kind == selectedPage
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [page.accent, page.accent.opacity(0.74)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(DesignTokens.color.surfaceInset)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages) { page in
            Capsule()
                .fill(page.kind == selectedPage ? selectedPageModel.accent : DesignTokens.color.textMuted.opacity(colorScheme == .dark ? 0.42 : 0.3))
                .frame(width: page.kind == selectedPage ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: selectedPage)
    }

    @ViewBuilder
    private func pageBody(for page: WordCardPage) -> some View {
        pageSurface(title: page.title, accent: page.accent) {
            switch page.kind {
            case .examples:
                examplesPage
            case .didYouKnow:
                didYouKnowPage
            case .usageNotes:
                usageNotesPage
            case .relatedWords:
                relatedWordsPage
            case .conjugation:
                conjugationPage
            case .detailsFallback:
                detailsFallbackPage
            }
        }
        .padding(.horizontal, 2)
    }

    private func pageSurface<Content: View>(title: String, accent: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignTokens.typography.callout(weight: .bold))
                .foregroundStyle(DesignTokens.color.headingPrimary)

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.color.sectionBackground,
                            accent.opacity(colorScheme == .dark ? 0.18 : 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accent.opacity(colorScheme == .dark ? 0.2 : 0.18), lineWidth: 1)
                )
        )
    }

    private var examplesPage: some View {
        let visiblePairs = Array(word.localizedExamplePairs.prefix(2))
        let hiddenExampleCount = max(word.localizedExamplePairs.count - visiblePairs.count, 0)

        return VStack(alignment: .leading, spacing: 12) {
            exampleRows(for: visiblePairs, highlightColor: exampleHighlightColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hiddenExampleCount > 0 {
                Button {
                    isShowingExamplesSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 14, weight: .semibold))

                        Text(L10n.Chat.chipMoreExamples)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                    }
                    .foregroundStyle(DesignTokens.color.skyBlue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(DesignTokens.color.skyBlue.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the remaining example sentences")
            }
        }
    }

    private func exampleRows(for pairs: [(String, String)], highlightColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                ExampleBubbleRow(
                    sentence: pair.0,
                    translation: pair.1,
                    languageCode: word.pronunciationCode,
                    speechSynthesizer: speechSynthesizer,
                    highlightedWord: word.displayWord,
                    highlightColor: highlightColor
                )
            }
        }
    }

    private var didYouKnowPage: some View {
        let text = word.localizedCuriosityFacts?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ScrollView(.vertical, showsIndicators: false) {
            Text(text)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private var usageNotesPage: some View {
        let allEntries = wordCardUsageEntries(for: word)
        return ScrollView(.vertical, showsIndicators: false) {
            timelineRows(for: allEntries, accent: WordCardPageKind.usageNotes.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private func timelineRows(for entries: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                TimelineRow(
                    text: entry,
                    accent: accent,
                    isLast: index == entries.count - 1,
                    showsMarker: false
                )
            }
        }
    }

    private var relatedWordsPage: some View {
        let allEntries = word.relatedWords
        return ScrollView(.vertical, showsIndicators: false) {
            relatedWordRows(for: allEntries)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private func relatedWordRows(for entries: [RelatedWordEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(entries, id: \.word) { entry in
                let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.word)
                        .font(DesignTokens.typography.callout(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textDark)

                    if !note.isEmpty {
                        Text(note)
                            .font(DesignTokens.typography.caption(weight: .medium))
                            .foregroundStyle(DesignTokens.color.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WordCardPageKind.relatedWords.accent.opacity(colorScheme == .dark ? 0.18 : 0.14))
                )
            }
        }
    }

    private var conjugationPage: some View {
        let allPairs = word.conjugationPairs
        return ScrollView(.vertical, showsIndicators: false) {
            conjugationRows(for: allPairs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }

    private func conjugationRows(for pairs: [(pronoun: String, form: String)]) -> some View {
        let singularCount = (pairs.count + 1) / 2
        let singularPairs = Array(pairs.prefix(singularCount))
        let pluralPairs = Array(pairs.dropFirst(singularCount))

        return VStack(spacing: 10) {
            ForEach(singularPairs.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 10) {
                    conjugationCell(for: singularPairs[index])

                    if pluralPairs.indices.contains(index) {
                        conjugationCell(for: pluralPairs[index])
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, minHeight: 58)
                    }
                }
            }
        }
    }

    private func conjugationCell(for pair: (pronoun: String, form: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pair.pronoun)
                .font(DesignTokens.typography.caption(weight: .medium))
                .foregroundStyle(DesignTokens.color.textTertiary)
                .lineLimit(1)

            Text(pair.form)
                .font(DesignTokens.typography.callout(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WordCardPageKind.conjugation.accent.opacity(colorScheme == .dark ? 0.18 : 0.14))
        )
    }

    private var detailsFallbackPage: some View {
        Text(L10n.WordDetail.noAdditionalDetails)
            .font(DesignTokens.typography.callout(weight: .medium))
            .foregroundStyle(DesignTokens.color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var exampleHighlightColor: Color {
        wordCardGenderColor(for: word) ?? DesignTokens.color.skyBlue
    }

    private var allExamplesSheet: some View {
        NavigationStack {
            ScrollView {
                exampleRows(for: word.localizedExamplePairs, highlightColor: exampleHighlightColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
            .background(DesignTokens.color.backgroundLight.ignoresSafeArea())
            .navigationTitle(L10n.Common.examples)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done) {
                        isShowingExamplesSheet = false
                    }
                    .font(DesignTokens.typography.callout(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func inlineChip(text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.typography.footnote(weight: .bold))
            .foregroundStyle(color.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.16))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(colorScheme == .dark ? 0.16 : 0.14), lineWidth: 1)
                    )
            )
    }

    private func sanitizeSelectedPage() {
        guard let firstPage = pages.first else { return }
        guard pageKinds.contains(selectedPage) else {
            selectedPage = firstPage.kind
            return
        }
    }

    private func handleFavoriteToggle() {
        let willFavorite = !isFavorite
        onToggleFavorite()

        guard willFavorite else {
            HapticFeedback.light()
            return
        }

        triggerFavoriteAnimation()
    }

    private func triggerFavoriteAnimation() {
        favoriteBurstVisible = true
        favoriteBurstScale = 0.5
        favoriteBurstOpacity = 1
        favoriteBurstOffset = 0
        favoriteRingScale = 0.78
        favoriteRingOpacity = 0.32

        HapticFeedback.success()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            favoriteBurstOffset = -80
            favoriteBurstScale = 1
            favoriteBurstOpacity = 1
            favoriteRingScale = 1.04
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            favoriteBurstOpacity = 0
            favoriteRingOpacity = 0
            favoriteRingScale = 1.12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            favoriteBurstVisible = false
            favoriteBurstScale = 0.5
            favoriteBurstOffset = 0
            favoriteRingScale = 0.78
        }
    }
}
