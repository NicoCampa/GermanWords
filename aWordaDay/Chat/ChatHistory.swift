//
//  ChatHistory.swift
//  aWordaDay
//
//  SwiftData model for persisting chat messages.
//

import Foundation
import SwiftData

@Model
final class ChatHistoryMessage {
    var messageId: String
    var role: String  // "user" or "model"
    var content: String
    var timestamp: Date
    var wordContext: String?  // The word being studied when this message was sent

    init(role: String, content: String, timestamp: Date, wordContext: String? = nil) {
        self.messageId = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.wordContext = wordContext
    }

    func toChatMessage() -> ChatMessage {
        let chatRole: ChatMessage.Role = role == "user" ? .user : .assistant
        return ChatMessage(role: chatRole, content: content, timestamp: timestamp)
    }
}
