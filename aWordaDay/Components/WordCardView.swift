import SwiftUI
import SwiftData

// MARK: - Overflow Menu Sheet
struct OverflowMenuSheet: View {
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Button(action: {
                    onShare()
                    dismiss()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .symbolRenderingMode(.hierarchical)

                        Text(L10n.WordDetail.shareWord)
                            .font(DesignTokens.typography.body(weight: .medium))

                        Spacer()
                    }
                    .foregroundStyle(DesignTokens.color.textPrimary)
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            .padding()
            .navigationTitle(L10n.Common.options)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Chip Component
struct Chip: View {
    let text: String
    let style: ChipStyle

    enum ChipStyle {
        case difficulty, article, gender, plural, partOfSpeech, definition

        var backgroundColor: Color {
            switch self {
            case .difficulty: return DesignTokens.color.difficultyGold.opacity(0.2)
            case .article: return DesignTokens.color.skyBlue.opacity(0.2)
            case .gender: return DesignTokens.color.deepOrange.opacity(0.2)
            case .plural: return DesignTokens.color.relatedAccent.opacity(0.2)
            case .partOfSpeech: return DesignTokens.color.posGreen.opacity(0.2)
            case .definition: return DesignTokens.color.primary.opacity(0.9)
            }
        }

        var chipForegroundColor: Color {
            switch self {
            case .difficulty: return DesignTokens.color.difficultyGold
            case .article: return DesignTokens.color.interactiveBlue
            case .gender: return DesignTokens.color.highlight
            case .plural: return DesignTokens.color.categoryPurple
            case .partOfSpeech: return DesignTokens.color.posGreen
            case .definition: return .white
            }
        }
    }

    var body: some View {
        Text(text)
            .font(DesignTokens.typography.caption(weight: .semibold))
            .foregroundStyle(style.chipForegroundColor)
            .padding(.horizontal, DesignTokens.spacing.md)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                    .fill(style.backgroundColor)
            )
    }
}
