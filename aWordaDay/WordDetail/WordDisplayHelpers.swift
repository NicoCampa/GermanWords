//
//  WordDisplayHelpers.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    func pronunciationButton(systemName: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        let accent = isActive ? DesignTokens.color.success : DesignTokens.color.pronunciationAccent
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(accent.opacity(0.12))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    func subtleCircleButton(icon: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        let accent = isActive ? DesignTokens.color.learningGreen : DesignTokens.color.accentBlue
        let background = DesignTokens.color.skyBlue.opacity(isActive ? 0.75 : 0.55)

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(background)
                        .shadow(color: accent.opacity(0.18), radius: 10, x: 0, y: 6)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
    }

    func usageSummary<WordType: WordDisplayable>(for word: WordType) -> String {
        let trimmed = word.localizedUsageNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? word.localizedTranslation : trimmed
    }

    func detailCard(icon: String, title: String, text: String, accent: Color) -> some View {
        let pastel = accent.opacity(0.12)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Text(title)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textDark)

                Spacer()
            }

            Text(text)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(pastel)
                .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }

    func metadataItems<WordType: WordDisplayable>(for word: WordType) -> [MetadataChip] {
        var items: [MetadataChip] = []
        let nounColor = genderColor(for: word)

        if let article = word.displayArticle?.capitalized, !article.isEmpty {
            items.append(MetadataChip(icon: "textformat.abc", text: article, tint: nounColor ?? DesignTokens.color.accentBlue))
        }

        if let gender = word.displayGender, !gender.isEmpty {
            items.append(MetadataChip(icon: "person.crop.square", text: gender, tint: nounColor ?? DesignTokens.color.interactiveBlue))
        }

        items.append(MetadataChip(icon: "chart.bar", text: word.displayDifficulty, tint: DesignTokens.color.learningGreen))

        if let partOfSpeech = word.partOfSpeech?.capitalized, !partOfSpeech.isEmpty {
            items.append(MetadataChip(icon: "textformat", text: partOfSpeech, tint: DesignTokens.color.textSubtle))
        }

        return items
    }

    func timelineEntries(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.newlines)
            .flatMap { $0.components(separatedBy: "•") }
            .map { sanitizeBulletEntry($0) }
            .filter { !$0.isEmpty }
    }

    func sanitizeBulletEntry(_ raw: String) -> String {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while let first = trimmed.first, ["-", "•"].contains(first) {
            trimmed.removeFirst()
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    func genderColor<WordType: WordDisplayable>(for word: WordType) -> Color? {
        guard isNoun(word) else { return nil }
        let gender = word.gender?.lowercased() ?? inferredGender(from: word.displayArticle)
        switch gender {
        case "masculine", "maskulin", "m", "der":
            return DesignTokens.color.genderMasculine
        case "feminine", "feminin", "f", "die":
            return DesignTokens.color.genderFeminine
        case "neuter", "neutral", "n", "das":
            return DesignTokens.color.genderNeuter
        default:
            return nil
        }
    }

    func inferredGender(from article: String?) -> String? {
        guard let article = article?.lowercased() else { return nil }
        if article.contains("der") { return "der" }
        if article.contains("die") { return "die" }
        if article.contains("das") { return "das" }
        return nil
    }

    func timelineCard(icon: String, title: String, entries: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }

                Text(title)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textDark)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    TimelineRow(text: entry, accent: accent, isLast: index == entries.count - 1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(accent.opacity(0.12))
                .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 8)
        )
    }

    func isNoun<WordType: WordDisplayable>(_ word: WordType) -> Bool {
        word.partOfSpeech?.lowercased().contains("noun") == true || word.displayArticle != nil
    }

    func isVerb<WordType: WordDisplayable>(_ word: WordType) -> Bool {
        word.partOfSpeech?.lowercased().contains("verb") == true
    }

    @ViewBuilder
    func relatedWordsCard<WordType: WordDisplayable>(for word: WordType) -> some View {
        let accent = DesignTokens.color.relatedAccent
        let hasContent = (word.plural?.isEmpty == false)
            || !word.relatedWords.isEmpty

        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accent.opacity(0.16))
                            .frame(width: 46, height: 46)
                        Image(systemName: "link")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    Text("Related Words")
                        .font(DesignTokens.typography.headline(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textDark)
                    Spacer()
                }

                if let plural = word.plural, !plural.isEmpty {
                    Text("Plural: \(plural)")
                        .font(DesignTokens.typography.callout(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textSecondary)
                }

                ForEach(word.relatedWords, id: \.word) { entry in
                    relatedWordRow(entry: entry)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(accent.opacity(0.12))
                    .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 8)
            )
        }
    }

    @ViewBuilder
    private func relatedWordRow(entry: RelatedWordEntry) -> some View {
        let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        HStack(spacing: 6) {
            Text(entry.word)
                .font(DesignTokens.typography.callout(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textDark)
            if !note.isEmpty {
                Text("— \(note)")
                    .font(DesignTokens.typography.caption(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

}
