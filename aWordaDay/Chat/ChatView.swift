//
//  ChatView.swift
//  aWordaDay
//
//  Full chat UI for Gemini-powered language tutor.
//

import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss

    let word: Word?
    let isSheet: Bool

    init(word: Word? = nil, isSheet: Bool = false) {
        self.word = word
        self.isSheet = isSheet
    }

    var body: some View {
        Group {
            if isSheet {
                VStack(spacing: 0) {
                    sheetHeader
                    chatContent
                    inputBar
                }
            } else {
                NavigationStack {
                    VStack(spacing: 0) {
                        chatContent
                        inputBar
                    }
                    .navigationTitle(L10n.Chat.chatWithWorty)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { viewModel.clearChat() }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(DesignTokens.color.textMuted)
                            }
                            .disabled(viewModel.messages.isEmpty)
                        }
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundGradientTop,
                    DesignTokens.color.backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            if let word {
                viewModel.setWordContext(word)
            }
        }
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.color.textMuted)
            }

            Spacer()

            Text(L10n.Chat.chatWithWorty)
                .font(DesignTokens.typography.headline())
                .foregroundStyle(DesignTokens.color.textPrimary)

            Spacer()

            // Balance the close button
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.vertical, DesignTokens.spacing.md)
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.spacing.md) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    }

                    if let word, viewModel.hasWordContext {
                        wordContextChip(word)
                    }

                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    if viewModel.isLoading {
                        typingIndicator
                    }

                    if let error = viewModel.error {
                        errorView(error)
                    }

                    if !viewModel.isLoading {
                        suggestionChipsView
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, DesignTokens.spacing.lg)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isLoading) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.spacing.lg) {
            Spacer().frame(height: 40)

            SharedCloudMascot(scale: 0.7)

            Text(L10n.Chat.emptyTitle)
                .font(DesignTokens.typography.headline())
                .foregroundStyle(DesignTokens.color.textPrimary)

            Text(L10n.Chat.emptySubtitle)
                .font(DesignTokens.typography.body(weight: .regular))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignTokens.spacing.xl)
    }

    // MARK: - Word Context Chip

    private func wordContextChip(_ word: Word) -> some View {
        HStack(spacing: DesignTokens.spacing.sm) {
            Image(systemName: "book.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.color.primary)

            Text(L10n.WordDetail.studying(word.word))
                .font(DesignTokens.typography.caption(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            if let article = word.displayArticle {
                Text("(\(article))")
                    .font(DesignTokens.typography.caption())
                    .foregroundStyle(DesignTokens.color.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, DesignTokens.spacing.sm)
        .background(
            Capsule()
                .fill(DesignTokens.color.primary.opacity(0.1))
        )
        .padding(.horizontal, DesignTokens.spacing.lg)
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
            Image("wordy")
                .resizable()
                .interpolation(.medium)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(Circle())

            HStack(spacing: 6) {
                PulsingDots()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, DesignTokens.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .designSystemShadow(DesignTokens.shadow.light)
            )

            Spacer(minLength: 48)
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: DesignTokens.spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.color.error)

            Text(message)
                .font(DesignTokens.typography.caption())
                .foregroundStyle(DesignTokens.color.error)
                .lineLimit(2)

            Spacer()

            Button(L10n.Common.retry) {
                viewModel.error = nil
                if let lastUserMessage = viewModel.messages.last(where: { $0.role == .user }) {
                    viewModel.messages.removeLast()
                    viewModel.sendSuggestion(lastUserMessage.content)
                }
            }
            .font(DesignTokens.typography.caption(weight: .semibold))
            .foregroundStyle(DesignTokens.color.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md, style: .continuous)
                .fill(DesignTokens.color.error.opacity(0.1))
        )
        .padding(.horizontal, DesignTokens.spacing.lg)
    }

    // MARK: - Suggestion Chips

    private var suggestionChipsView: some View {
        VStack(spacing: DesignTokens.spacing.sm) {
            ForEach(viewModel.suggestionChips, id: \.self) { chip in
                Button(action: {
                    HapticFeedback.light()
                    viewModel.sendSuggestion(chip)
                }) {
                    HStack {
                        Text(chip)
                            .font(DesignTokens.typography.caption(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DesignTokens.color.primary.opacity(0.5))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md, style: .continuous)
                            .fill(DesignTokens.color.primary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md, style: .continuous)
                                    .strokeBorder(DesignTokens.color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(L10n.Chat.inputPlaceholder, text: $viewModel.inputText, axis: .vertical)
                .font(DesignTokens.typography.body())
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                        .fill(DesignTokens.color.cardBackground)
                        .designSystemShadow(DesignTokens.shadow.light)
                )
                .onSubmit { viewModel.send() }

            Button(action: {
                HapticFeedback.light()
                viewModel.send()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? DesignTokens.color.textMuted
                            : DesignTokens.color.primary
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview("Standalone") {
    ChatView()
}

#Preview("With Word Context") {
    ChatView(
        word: Word(word: "Schmetterling", translation: "butterfly", difficultyLevel: 2, cefrLevel: "B1", article: "der", gender: "masculine", partOfSpeech: "noun", plural: "Schmetterlinge"),
        isSheet: true
    )
}
