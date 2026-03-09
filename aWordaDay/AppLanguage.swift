//
//  AppLanguage.swift
//  aWordaDay
//
//  Created by Codex on 24.11.25.
//

import Foundation

/// Centralized configuration for the single supported language (German).
enum AppLanguage {
    static let displayName = "German"
    static let nativeName = "Deutsch"
    static let flagEmoji = "🇩🇪"

    static let sourceCode = "de"
    static var targetCode: String { activeTargetLanguage.code }
    static let pronunciationCode = "de-DE"

    /// The user's chosen target language for translations/explanations.
    /// Set on app launch from AppState.targetLanguage.
    static var activeTargetLanguage: TargetLanguage = .english

    /// Bundled JSON export filename without the `.json` extension.
    static let exportResourceName = "wordy_words_export_german"
}
