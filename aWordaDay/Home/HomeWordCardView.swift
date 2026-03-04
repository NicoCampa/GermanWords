import SwiftUI

struct HomeWordCardView<WordType: WordDisplayable>: View {
    let word: WordType
    @Binding var selectedPage: WordCardPageKind
    @ObservedObject var speechSynthesizer: SpeechSynthesizerManager
    let isPronunciationActive: Bool
    let onPronounce: () -> Void

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
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.975, green: 0.985, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(red: 0.83, green: 0.89, blue: 0.97), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.16, green: 0.28, blue: 0.54).opacity(0.1), radius: 20, x: 0, y: 12)
        )
        .onAppear(perform: sanitizeSelectedPage)
        .onChange(of: pageKinds) { _, _ in
            sanitizeSelectedPage()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    headerEyebrow

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
                    VStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Audio")
                            .font(DesignTokens.typography.footnote(weight: .bold))
                    }
                    .foregroundStyle(isPronunciationActive ? Color.white : DesignTokens.color.headingPrimary)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                                : AnyShapeStyle(Color(red: 0.96, green: 0.975, blue: 1.0))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        isPronunciationActive
                                        ? Color.white.opacity(0.22)
                                        : Color(red: 0.84, green: 0.89, blue: 0.97),
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

    private var headerEyebrow: some View {
        HStack(spacing: 8) {
            Text("Word of the day")
                .font(DesignTokens.typography.footnote(weight: .bold))
                .foregroundStyle(DesignTokens.color.textSecondary.opacity(0.8))

            Capsule()
                .fill(selectedPageModel.accent.opacity(0.18))
                .frame(width: 28, height: 8)
        }
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
                                        : AnyShapeStyle(Color(red: 0.95, green: 0.96, blue: 0.985))
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
                    .fill(page.kind == selectedPage ? selectedPageModel.accent : DesignTokens.color.textMuted.opacity(0.22))
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
                            Color.white,
                            accent.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(accent.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var examplesPage: some View {
        let visiblePairs = Array(word.localizedExamplePairs.prefix(2))
        let highlightColor = wordCardGenderColor(for: word) ?? DesignTokens.color.skyBlue

        return VStack(alignment: .leading, spacing: 12) {
            exampleRows(for: visiblePairs, highlightColor: highlightColor)
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
                    highlightedWord: word.word,
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
        }
    }

    private var usageNotesPage: some View {
        let allEntries = wordCardUsageEntries(for: word)
        return ScrollView(.vertical, showsIndicators: false) {
            timelineRows(for: allEntries, accent: WordCardPageKind.usageNotes.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func timelineRows(for entries: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                TimelineRow(text: entry, accent: accent, isLast: index == entries.count - 1)
            }
        }
    }

    private var relatedWordsPage: some View {
        let allEntries = word.relatedWords
        return ScrollView(.vertical, showsIndicators: false) {
            relatedWordRows(for: allEntries)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                        .fill(WordCardPageKind.relatedWords.accent.opacity(0.08))
                )
            }
        }
    }

    private var conjugationPage: some View {
        let allPairs = word.conjugationPairs
        return ScrollView(.vertical, showsIndicators: false) {
            conjugationRows(for: allPairs)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func conjugationRows(for pairs: [(pronoun: String, form: String)]) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 12) {
                    Text(pair.pronoun)
                        .font(DesignTokens.typography.caption(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textTertiary)
                        .frame(width: 82, alignment: .trailing)

                    Text(pair.form)
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(WordCardPageKind.conjugation.accent.opacity(0.08))
                )
            }
        }
    }

    private var detailsFallbackPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.WordDetail.noAdditionalDetails)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func inlineChip(text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.typography.footnote(weight: .bold))
            .foregroundStyle(color.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.08), lineWidth: 1)
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
}
