//
//  HomeEventHandlers.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    func pronounceWord(style: SpeechPlaybackStyle = .normal) {
        guard let word = todaysWord else { return }

        FirebaseAnalyticsManager.shared.logWordListened(
            word: word.word,
            language: word.sourceLanguage
        )

        speechSynthesizer.speak(
            text: word.word,
            language: word.pronunciationCode,
            style: style
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            showingPronunciation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingPronunciation = false
            }
        }
    }

    func handleNewWordRequest() {
        FirebaseAnalyticsManager.shared.logNewWordRequested(language: AppLanguage.sourceCode)

        let previousWord = viewModel.prepareWordTransition()

        if previousWord != nil || (todaysWord == nil && !availableWords.isEmpty) {
            viewModel.completeWordTransition(
                word: previousWord,
                quality: 3,
                onXPGained: { xp in triggerXPGainAnimation(amount: xp) },
                onAchievement: { msg in showAchievementToast(msg) }
            )
        }
    }

    func triggerXPGainAnimation(amount: Int) {
        guard amount > 0 else { return }
        xpGained = amount
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showingXPAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingXPAnimation = false
            }
        }
    }

    func showAchievementToast(_ message: String) {
        achievementMessage = message
        HapticFeedback.success()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingAchievementToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                showingAchievementToast = false
            }
        }
    }
}
