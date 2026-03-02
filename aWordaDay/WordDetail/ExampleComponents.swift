//
//  ExampleComponents.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct TimelineRow: View {
    let text: String
    let accent: Color
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(accent)
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(accent.opacity(0.3))
                        .frame(width: 2)
                        .padding(.top, 2)
                }
            }

            Text(text)
                .font(DesignTokens.typography.caption(weight: .medium))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ExampleBubbleRow: View {
    let sentence: String
    let translation: String
    let languageCode: String
    @ObservedObject var speechSynthesizer: SpeechSynthesizerManager
    let highlightedWord: String?
    let highlightColor: Color?

    var body: some View {
        Button {
            speechSynthesizer.speak(
                text: sentence,
                language: languageCode,
                style: .normal
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                highlightedSentence

                if !translation.isEmpty {
                    Text(translation)
                        .font(DesignTokens.typography.caption(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignTokens.color.audioButtonBlue.opacity(0.5))
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Listen to example: \(sentence)")
    }
    private var highlightedSentence: some View {
        let base = sentence
        guard let target = highlightedWord, let color = highlightColor else {
            return Text(base)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textDark)
                .fixedSize(horizontal: false, vertical: true)
        }

        var attributed = AttributedString(base)
        let lowerSentence = base.lowercased()
        let lowerTarget = target.lowercased()

        // First try exact match
        var foundExact = false
        var searchRange = lowerSentence.startIndex..<lowerSentence.endIndex
        while let foundRange = lowerSentence.range(of: lowerTarget, options: [], range: searchRange) {
            foundExact = true
            if let attrRange = Range(foundRange, in: attributed) {
                attributed[attrRange].foregroundColor = color
                attributed[attrRange].underlineStyle = .single
            }
            searchRange = foundRange.upperBound..<lowerSentence.endIndex
        }

        // If no exact match, try stem-based matching for conjugated/declined forms
        if !foundExact {
            let minStemLength = max(min(lowerTarget.count - 1, lowerTarget.count), 3)
            let wordPattern = "[\\p{L}]+"
            if let regex = try? NSRegularExpression(pattern: wordPattern),
               minStemLength >= 3 {
                let nsRange = NSRange(lowerSentence.startIndex..., in: lowerSentence)
                let matches = regex.matches(in: lowerSentence, range: nsRange)
                for match in matches {
                    guard let matchRange = Range(match.range, in: lowerSentence) else { continue }
                    let word = String(lowerSentence[matchRange])
                    if sharesCommonStem(word, lowerTarget, minLength: minStemLength) {
                        if let attrRange = Range(matchRange, in: attributed) {
                            attributed[attrRange].foregroundColor = color
                            attributed[attrRange].underlineStyle = .single
                        }
                    }
                }
            }
        }

        return Text(attributed)
            .font(DesignTokens.typography.callout(weight: .medium))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Checks if two words share a common stem of at least `minLength` characters.
    /// Handles German conjugations/declinations (essen→esse, Hund→Hunde, schön→schöne).
    private func sharesCommonStem(_ a: String, _ b: String, minLength: Int) -> Bool {
        let shorter = min(a.count, b.count)
        guard shorter >= minLength else { return false }
        let prefixLen = zip(a, b).prefix(while: { $0 == $1 }).count
        return prefixLen >= minLength
    }
}
