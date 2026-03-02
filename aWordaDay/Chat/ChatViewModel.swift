//
//  ChatViewModel.swift
//  aWordaDay
//
//  View model for chat with Gemini.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var error: String? = nil

    private let gemini = GeminiService()
    var modelContext: ModelContext?
    private static let maxPersistedMessages = 50
    private(set) var wordContext: Word?
    private var canSend: Bool = true

    var hasWordContext: Bool { wordContext != nil }

    var suggestionChips: [String] {
        guard let word = wordContext else {
            return [L10n.Chat.chipTeachNewWord, L10n.Chat.chipExplainCases, L10n.Chat.chipCommonPhrases]
        }

        var chips = [L10n.Chat.chipMoreExamples, L10n.Chat.chipUseInSentence]

        switch word.partOfSpeech?.lowercased() {
        case let pos where pos?.contains("verb") == true:
            chips += [L10n.Chat.chipConjugatePast, L10n.Chat.chipHabenOderSein, L10n.Chat.chipSimilarVerbs]
        case let pos where pos?.contains("adjective") == true || pos?.contains("adjektiv") == true:
            chips += [L10n.Chat.chipComparativeSuperlative, L10n.Chat.chipOpposite, L10n.Chat.chipSimilarAdjectives]
        case let pos where pos?.contains("noun") == true || pos?.contains("nomen") == true || pos?.contains("substantiv") == true:
            chips += [L10n.Chat.chipExplainGrammar, L10n.Chat.chipSimilarWords]
        default:
            chips += [L10n.Chat.chipExplainGrammar, L10n.Chat.chipSimilarWords]
        }

        return chips
    }

    func setWordContext(_ word: Word) {
        wordContext = word
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        sendMessage(text)
    }

    func sendSuggestion(_ text: String) {
        sendMessage(text)
    }

    func clearChat() {
        withAnimation(.easeOut(duration: 0.25)) {
            messages = []
        }
        error = nil

        // Clear persisted history
        if let modelContext {
            let descriptor = FetchDescriptor<ChatHistoryMessage>()
            if let saved = try? modelContext.fetch(descriptor) {
                for msg in saved {
                    modelContext.delete(msg)
                }
                try? modelContext.save()
            }
        }
    }

    func loadHistory(from modelContext: ModelContext) {
        self.modelContext = modelContext

        var descriptor = FetchDescriptor<ChatHistoryMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = Self.maxPersistedMessages

        guard let saved = try? modelContext.fetch(descriptor) else { return }

        messages = saved.map { $0.toChatMessage() }
    }

    // MARK: - Private

    private func sendMessage(_ text: String) {
        guard canSend else { return }
        canSend = false
        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            messages.append(userMessage)
        }
        persistMessage(userMessage)
        error = nil
        isLoading = true

        Task { @MainActor in
            do {
                let response = try await gemini.send(messages: recentMessagesForRequest(), systemPrompt: systemPrompt)
                let assistantMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    messages.append(assistantMessage)
                }
                persistMessage(assistantMessage)
            } catch {
                self.error = error.localizedDescription
                if !(error is GeminiError) {
                    ErrorPresenter.shared.present(error, context: "chat message")
                }
            }
            isLoading = false
            try? await Task.sleep(for: .seconds(1))
            self.canSend = true
        }
    }

    private func persistMessage(_ message: ChatMessage) {
        guard let modelContext else { return }
        let historyMessage = ChatHistoryMessage(
            role: message.role.rawValue,
            content: message.content,
            timestamp: message.timestamp,
            wordContext: wordContext?.word
        )
        modelContext.insert(historyMessage)
        try? modelContext.save()
    }

    private var systemPrompt: String {
        var prompt = """
        You are Worty, a friendly German language tutor. You help users learn German vocabulary.
        Keep answers concise (1-3 short sentences, max ~80 words) unless the user asks for detail.
        \(AppLanguage.activeTargetLanguage.chatExplanationDirective) Include German examples when helpful.
        Prefer plain text over lists unless the user asks for a list.
        """

        if let word = wordContext {
            prompt += "\n\nThe user is currently studying the word \"\(word.word)\" (\(word.localizedTranslation))."
            if let article = word.displayArticle {
                prompt += "\nArticle: \(article)"
            }
            if let gender = word.gender {
                prompt += ", Gender: \(gender)"
            }
            if let plural = word.plural, !plural.isEmpty {
                prompt += ", Plural: \(plural)"
            }
            if let pos = word.partOfSpeech {
                prompt += "\nPart of speech: \(pos)"
            }
            if let cefr = word.cefrLevel {
                prompt += ", CEFR: \(cefr)"
            }
            // Verb-specific context
            if let conjugation = word.conjugation, !conjugation.isEmpty {
                prompt += "\nPresent tense: \(conjugation)"
            }
            if let aux = word.auxiliaryVerb {
                prompt += "\nAuxiliary verb (Perfekt): \(aux)"
            }
            if let participle = word.pastParticiple {
                prompt += "\nPast participle: \(participle)"
            }


        }

        return prompt
    }

    /// Send only recent turns to control token usage and keep responses focused.
    private func recentMessagesForRequest(limit: Int = 12) -> [ChatMessage] {
        if messages.count <= limit { return messages }
        return Array(messages.suffix(limit))
    }
}
