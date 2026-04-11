//
//  HomeEventHandlers.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

extension ContentView {
    func pronounceWord(style: SpeechPlaybackStyle = .normal) {
        guard let word = activeWord else { return }

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
        viewModel.requestNewWord(
            onXPGained: { xp in triggerXPGainAnimation(amount: xp) },
            onAchievement: { msg in showAchievementToast(msg) }
        )
    }

    func triggerXPGainAnimation(amount: Int) {
        guard amount > 0 else { return }

        pendingXPAnimationWordCount += 1
        pendingXPAnimationAmount += amount

        guard pendingXPAnimationWordCount >= 3 else { return }

        xpHideWorkItem?.cancel()
        xpGained = pendingXPAnimationAmount
        xpAnimationToken = UUID()
        pendingXPAnimationWordCount = 0
        pendingXPAnimationAmount = 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showingXPAnimation = true
        }

        let hideWorkItem = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.3)) {
                showingXPAnimation = false
            }
        }
        xpHideWorkItem = hideWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: hideWorkItem)
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
