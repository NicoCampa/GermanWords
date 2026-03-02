//
//  ChatBubble.swift
//  aWordaDay
//
//  Individual message bubble for chat UI.
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                assistantAvatar
            }

            if message.role == .user { Spacer(minLength: 48) }

            bubbleContent

            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Bubble content

    private var bubbleContent: some View {
        Text(parseMarkdown(message.content))
            .font(DesignTokens.typography.body())
            .foregroundStyle(message.role == .user ? .white : DesignTokens.color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bubbleBackground)
    }

    private var bubbleBackground: some View {
        Group {
            if message.role == .user {
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                    .fill(DesignTokens.color.primary)
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .designSystemShadow(DesignTokens.shadow.light)
            }
        }
    }

    // MARK: - Avatar

    private var assistantAvatar: some View {
        Image("wordy")
            .resizable()
            .interpolation(.medium)
            .antialiased(true)
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .clipShape(Circle())
    }

    // MARK: - Simple markdown parsing

    private func parseMarkdown(_ text: String) -> AttributedString {
        // Try to use iOS built-in markdown parsing
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }

        // Fallback: plain text
        return AttributedString(text)
    }
}
