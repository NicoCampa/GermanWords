//
//  MetadataComponents.swift
//  aWordaDay
//
//  Extracted from ContentView.swift
//

import SwiftUI

struct FlexibleChipView: View {
    let words: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(DesignTokens.typography.caption(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DesignTokens.color.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
            }
        }
    }
}

struct MetadataChip: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let tint: Color
}

struct MetadataChipGrid: View {
    let items: [MetadataChip]

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 8, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(item.tint)
                    Text(item.text)
                        .font(DesignTokens.typography.caption(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textDark)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(item.tint.opacity(0.12))
                )
            }
        }
    }
}

