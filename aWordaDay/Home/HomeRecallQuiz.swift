//
//  HomeRecallQuiz.swift
//  aWordaDay
//
//  Mini recall quiz shown when the user taps "Get new word".
//  Tests recall of the *previous* word before transitioning to the next one.
//

import SwiftUI

struct RecallQuizSheet: View {
    let word: Word
    let distractors: [String]
    let onAnswer: (Int) -> Void   // quality: 3 correct, 0 wrong

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswer: String?
    @State private var answered = false

    private var options: [String] {
        ([word.localizedTranslation] + distractors).shuffled()
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text(L10n.RecallQuiz.quickRecall)
                    .font(DesignTokens.typography.caption(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textSubtle)
                    .textCase(.uppercase)

                Text(L10n.RecallQuiz.whatDoes)
                    .font(DesignTokens.typography.headline(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textTertiary)

                Text(word.word)
                    .font(DesignTokens.typography.largeTitle(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textPrimary)

                Text(L10n.RecallQuiz.mean)
                    .font(DesignTokens.typography.headline(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textTertiary)
            }

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        guard !answered else { return }
                        selectedAnswer = option
                        answered = true

                        let isCorrect = option == word.localizedTranslation
                        let quality = isCorrect ? 3 : 0

                        if isCorrect {
                            HapticFeedback.success()
                        } else {
                            HapticFeedback.error()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            dismiss()
                            onAnswer(quality)
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(DesignTokens.typography.body(weight: .semibold))
                                .foregroundStyle(answerTextColor(for: option))

                            Spacer()

                            if answered && option == word.localizedTranslation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DesignTokens.color.success)
                            } else if answered && option == selectedAnswer && option != word.localizedTranslation {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DesignTokens.color.error)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(answerBackground(for: option))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button(L10n.Common.skip) {
                dismiss()
                onAnswer(0)
            }
            .font(DesignTokens.typography.callout(weight: .medium))
            .foregroundStyle(DesignTokens.color.textMuted)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundLight,
                    DesignTokens.color.backgroundMedium
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .interactiveDismissDisabled()
    }

    private func answerBackground(for option: String) -> Color {
        guard answered else { return DesignTokens.color.cardBackground }
        if option == word.localizedTranslation { return DesignTokens.color.success.opacity(0.12) }
        if option == selectedAnswer { return DesignTokens.color.error.opacity(0.12) }
        return DesignTokens.color.cardBackground
    }

    private func answerTextColor(for option: String) -> Color {
        guard answered else { return DesignTokens.color.textSecondary }
        if option == word.localizedTranslation { return DesignTokens.color.success }
        if option == selectedAnswer { return DesignTokens.color.error }
        return DesignTokens.color.textTertiary
    }
}

// MARK: - ContentView integration helpers

extension ContentView {
    /// Build distractors for the recall quiz from available words.
    func recallQuizDistractors(for word: Word) -> [String] {
        let correctAnswer = word.localizedTranslation.lowercased()
        var distractors: [String] = []
        var seen = Set<String>([correctAnswer])

        let candidates = availableWords.filter { $0.id != word.id }
        for candidate in candidates.shuffled() {
            let t = candidate.localizedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { continue }
            let key = t.lowercased()
            if seen.contains(key) { continue }
            distractors.append(t)
            seen.insert(key)
            if distractors.count >= 3 { break }
        }

        return distractors
    }
}
