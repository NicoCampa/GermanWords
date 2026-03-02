//
//  WordSupportingTypes.swift
//  aWordaDay
//
//  Extracted from Item.swift
//

import Foundation

struct RelatedWordEntry: Codable, Hashable {
    var word: String
    var note: String?
}

struct PracticeQuiz: Codable, Hashable {
    var question: String
    var correctAnswer: String
    var distractors: [String]
}

struct AntonymPayload: Codable {
    let word: String
    let note: String?
}

struct AdjectiveFormsPayload: Codable {
    let comparative: String?
    let superlative: String?
}
