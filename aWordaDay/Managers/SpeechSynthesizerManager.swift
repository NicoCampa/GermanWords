//
//  SpeechSynthesizerManager.swift
//  aWordaDay
//
//  Extracted from SharedComponents.swift
//

import SwiftUI
import AVFoundation

// MARK: - Speech Playback Style
enum SpeechPlaybackStyle {
    case normal
    case slow
}

// MARK: - Speech Synthesizer Manager
@MainActor
class SpeechSynthesizerManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, SpeechSynthesizerProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    private var isWarmedUp = false
    private var preloadedVoices: [String: AVSpeechSynthesisVoice] = [:]

    private let supportedLanguages = [AppLanguage.pronunciationCode, "en-US"]

    override init() {
        super.init()
        synthesizer.delegate = self
        Task {
            await warmUpSpeechEngine()
        }
    }

    @MainActor
    private func warmUpSpeechEngine() async {
        guard !isWarmedUp else { return }

        #if DEBUG
        print("🚀 Starting voice pre-loading...")
        #endif

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true)
            #if DEBUG
            print("✅ Audio session activated")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to configure audio session: \(error)")
            #endif
        }

        await preloadAllVoices()

        let warmUpUtterance = AVSpeechUtterance(string: " ")
        warmUpUtterance.volume = 0.0
        warmUpUtterance.rate = AVSpeechUtteranceMaximumSpeechRate
        warmUpUtterance.preUtteranceDelay = 0.0
        warmUpUtterance.postUtteranceDelay = 0.0
        warmUpUtterance.voice = preloadedVoices["en-US"]

        synthesizer.speak(warmUpUtterance)

        try? await Task.sleep(nanoseconds: 200_000_000)

        isWarmedUp = true
        #if DEBUG
        print("✅ All voices pre-loaded and ready!")
        #endif
    }

    private func preloadAllVoices() async {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()

        for language in supportedLanguages {
            if let voice = AVSpeechSynthesisVoice(language: language) {
                preloadedVoices[language] = voice
                await preloadVoice(voice, for: language)
            } else {
                let languageCode = String(language.prefix(2))
                if let fallbackVoice = availableVoices.first(where: { $0.language.hasPrefix(languageCode) }) {
                    preloadedVoices[language] = fallbackVoice
                    await preloadVoice(fallbackVoice, for: language)
                } else {
                    #if DEBUG
                    print("⚠️ No voice found for \(language)")
                    #endif
                }
            }
        }
    }

    private func preloadVoice(_ voice: AVSpeechSynthesisVoice, for language: String) async {
        let testUtterance = AVSpeechUtterance(string: "test")
        testUtterance.voice = voice
        testUtterance.volume = 0.0
        testUtterance.rate = AVSpeechUtteranceMaximumSpeechRate
        testUtterance.preUtteranceDelay = 0.0
        testUtterance.postUtteranceDelay = 0.0

        synthesizer.speak(testUtterance)

        try? await Task.sleep(nanoseconds: 50_000_000)

        #if DEBUG
        print("✅ Pre-loaded voice: \(voice.language) for \(language)")
        #endif
    }

    func speak(text: String, language: String, style: SpeechPlaybackStyle = .normal) {
        #if DEBUG
        print("🎯 Speak requested: '\(text)'")
        #endif

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.performSpeech(text: text, language: language, style: style)
            }
        } else {
            performSpeech(text: text, language: language, style: style)
        }
    }

    private func performSpeech(text: String, language: String, style: SpeechPlaybackStyle) {
        let utterance = AVSpeechUtterance(string: text)

        if let preloadedVoice = preloadedVoices[language] {
            utterance.voice = preloadedVoice
            #if DEBUG
            print("🎯 Using pre-loaded voice for \(language)")
            #endif
        } else {
            utterance.voice = preloadedVoices["en-US"] ?? AVSpeechSynthesisVoice(language: "en-US")
            #if DEBUG
            print("⚠️ Using fallback voice, \(language) not pre-loaded")
            #endif
        }

        switch style {
        case .normal:
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.pitchMultiplier = 1.0
        case .slow:
            utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * 0.6)
            utterance.pitchMultiplier = 0.95
        }

        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0

        DispatchQueue.main.async {
            self.isSpeaking = true
        }

        synthesizer.speak(utterance)
        #if DEBUG
        print("🔊 Speaking immediately: '\(text)' in \(utterance.voice?.language ?? "unknown")")
        #endif
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        #if DEBUG
        print("🎤 Started speaking")
        #endif
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
        #if DEBUG
        print("✅ Finished speaking")
        #endif
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
        #if DEBUG
        print("🛑 Speech cancelled")
        #endif
    }
}
