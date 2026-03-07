//
//  TargetLanguage.swift
//  aWordaDay
//

import Foundation

/// The language used for translations and explanations (not the language being learned).
enum TargetLanguage: String, CaseIterable, Codable {
    case english = "en"

    var displayName: String {
        "English"
    }

    var nativeName: String {
        "English"
    }

    var flagEmoji: String {
        "🇬🇧"
    }

    var code: String { rawValue }

    var pronunciationCode: String {
        "en-US"
    }

    /// Directive for AI chat to explain in the correct target language.
    var chatExplanationDirective: String {
        "Use simple English for explanations."
    }

    /// Display label for the target language name (used in AI game prompts).
    var targetLangName: String {
        "English"
    }
}
