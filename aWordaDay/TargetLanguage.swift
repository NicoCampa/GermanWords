//
//  TargetLanguage.swift
//  aWordaDay
//

import Foundation

/// The language used for translations and explanations (not the language being learned).
enum TargetLanguage: String, CaseIterable, Codable {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "Chinese (Simplified)"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    var flagEmoji: String {
        switch self {
        case .english: return "🇬🇧"
        case .chinese: return "🇨🇳"
        }
    }

    var code: String { rawValue }

    var pronunciationCode: String {
        switch self {
        case .english: return "en-US"
        case .chinese: return "zh-CN"
        }
    }

    /// Directive for AI chat to explain in the correct target language.
    var chatExplanationDirective: String {
        switch self {
        case .english:
            return "Use simple English for explanations."
        case .chinese:
            return "Use Simplified Chinese (简体中文) for all explanations. Keep it clear and suitable for language learners."
        }
    }

    /// Display label for the target language name (used in AI game prompts).
    var targetLangName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "Chinese"
        }
    }
}
