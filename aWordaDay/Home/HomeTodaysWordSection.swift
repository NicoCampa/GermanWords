//
//  HomeTodaysWordSection.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    func todaysWordSection<WordType: WordDisplayable>(_ word: WordType) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // MARK: Word Hero
            VStack(alignment: .leading, spacing: 10) {
                // Article + Word
                HStack(alignment: .firstTextBaseline) {
                    if let article = word.displayArticle {
                        Text(article)
                            .font(DesignTokens.typography.headline(weight: .semibold))
                            .foregroundStyle(genderColor(for: word) ?? DesignTokens.color.textSubtle)
                    }

                    Text(word.displayWord)
                        .font(DesignTokens.typography.largeTitle(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textDark)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Spacer()
                }

                // Translation
                Text(word.localizedTranslation)
                    .font(DesignTokens.typography.body(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.translationBlue)
                    .lineLimit(2)

                // Chips: POS, difficulty, plural/verb info + pronunciation button
                HStack(spacing: 8) {
                    if let pos = word.partOfSpeech, !pos.isEmpty {
                        inlineChip(text: pos.capitalized, color: DesignTokens.color.posGreen)
                    }

                    inlineChip(text: word.displayDifficulty, color: DesignTokens.color.difficultyGold)

                    if let plural = word.plural, !plural.isEmpty {
                        inlineChip(text: L10n.WordDetail.plural(plural), color: DesignTokens.color.purple)
                    }

                    // Verb-specific chips: auxiliary + past participle
                    if isVerb(word) {
                        if let aux = word.auxiliaryVerb {
                            inlineChip(text: aux, color: DesignTokens.color.accentBlue)
                        }
                        if let participle = word.pastParticiple {
                            inlineChip(text: participle, color: DesignTokens.color.accentBlue)
                        }
                    }

                    Spacer()

                    Button(action: {
                        HapticFeedback.light()
                        pronounceWord()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.pronunciationAccent)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(DesignTokens.color.pronunciationAccent.opacity(0.12))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(L10n.Home.listenToPronunciation)
                }
            }

            // MARK: Conjugation (verbs only)
            if isVerb(word), word.conjugation != nil {
                CollapsibleSection(
                    title: L10n.WordDetail.conjugation,
                    icon: "textformat.abc",
                    isExpanded: $conjugationExpanded
                ) {
                    conjugationTable(for: word)
                }
            }

            // MARK: Examples (always show max 2)
            if !word.localizedExamplePairs.isEmpty {
                let highlightColor = genderColor(for: word) ?? DesignTokens.color.skyBlue
                let highlightWord = word.displayWord
                let visiblePairs = Array(word.localizedExamplePairs.prefix(3))

                compactExamplesCard(
                    word: word,
                    visiblePairs: visiblePairs,
                    hasMore: false,
                    showAll: false,
                    highlightWord: highlightWord,
                    highlightColor: highlightColor,
                    onToggle: { }
                )
            }

            // MARK: Curiosity facts (always inline)
            if let curiosityFacts = word.localizedCuriosityFacts, !curiosityFacts.isEmpty {
                detailCard(
                    icon: "lightbulb.fill",
                    title: L10n.WordDetail.didYouKnow,
                    text: curiosityFacts,
                    accent: DesignTokens.color.gold
                )
            }

            // MARK: Collapsible: Usage notes
            let usageNotesEntries = timelineEntries(from: usageSummary(for: word))
            if !usageNotesEntries.isEmpty {
                CollapsibleSection(
                    title: L10n.WordDetail.usageNotes,
                    icon: "book.fill",
                    isExpanded: $usageNotesExpanded
                ) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(usageNotesEntries.enumerated()), id: \.offset) { index, entry in
                            TimelineRow(
                                text: entry,
                                accent: DesignTokens.color.accentBlue,
                                isLast: index == usageNotesEntries.count - 1,
                                showsMarker: false
                            )
                        }
                    }
                }
            }

            // MARK: Collapsible: Related words
            if !word.relatedWords.isEmpty {
                CollapsibleSection(
                    title: L10n.WordDetail.relatedWords,
                    icon: "link",
                    isExpanded: $relatedWordsExpanded
                ) {
                    relatedWordsContent(for: word)
                }
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignTokens.color.cardBackground)
                .designSystemShadow(DesignTokens.shadow.heavy)
        )
        .padding(.horizontal, 20)
        .onChange(of: word.id) {
            // Reset collapsible states when word changes
            showAllExamples = false
            usageNotesExpanded = false
            relatedWordsExpanded = false
            conjugationExpanded = false
        }
    }

    // MARK: - Compact Examples Card (shows 2 inline, "More" for rest)

    func compactExamplesCard(
        word: some WordDisplayable,
        visiblePairs: [(String, String)],
        hasMore: Bool,
        showAll: Bool,
        highlightWord: String?,
        highlightColor: Color?,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DesignTokens.color.skyBlue.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignTokens.color.skyBlue)
                }

                Text(L10n.Common.examples)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textDark)

                Spacer()

                if hasMore {
                    Button(action: onToggle) {
                        Text(showAll ? L10n.Common.less : L10n.Common.more)
                            .font(DesignTokens.typography.caption(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.skyBlue)
                    }
                }
            }

            ForEach(Array(visiblePairs.enumerated()), id: \.offset) { _, pair in
                ExampleBubbleRow(
                    sentence: pair.0,
                    translation: pair.1,
                    languageCode: word.pronunciationCode,
                    speechSynthesizer: speechSynthesizer,
                    highlightedWord: highlightWord,
                    highlightColor: highlightColor
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(DesignTokens.color.skyBlue.opacity(0.12))
                .shadow(color: DesignTokens.color.skyBlue.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }

    // MARK: - Related words content (without outer card wrapper, for use in CollapsibleSection)

    @ViewBuilder
    func relatedWordsContent<WordType: WordDisplayable>(for word: WordType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(word.relatedWords, id: \.word) { entry in
                relatedWordRowInline(entry: entry, accent: DesignTokens.color.relatedAccent)
            }
        }
    }

    @ViewBuilder
    private func relatedWordRowInline(entry: RelatedWordEntry, accent: Color) -> some View {
        let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        HStack(spacing: 0) {
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
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.opacity(0.08))
        )
    }

    func inlineChip(text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.typography.footnote(weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
    }

    // MARK: - Conjugation Table

    @ViewBuilder
    func conjugationTable<WordType: WordDisplayable>(for word: WordType) -> some View {
        let pairs = word.conjugationPairs
        if !pairs.isEmpty {
            VStack(spacing: 6) {
                ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                    HStack {
                        Text(pair.pronoun)
                            .font(DesignTokens.typography.caption(weight: .medium))
                            .foregroundStyle(DesignTokens.color.textTertiary)
                            .frame(width: 80, alignment: .trailing)

                        Text(pair.form)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
