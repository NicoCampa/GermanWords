//
//  DifficultySelectionView.swift
//  aWordaDay
//
//  Created by Claude on 29.10.25.
//

import SwiftUI
import SwiftData

struct DifficultySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @Binding var selectedDifficulty: Int?
    @Binding var allowMixed: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text(L10n.Difficulty.chooseYourLevel)
                    .font(DesignTokens.typography.largeTitle(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textPrimary)

                Text(L10n.Difficulty.selectDifficultyDesc)
                    .font(DesignTokens.typography.callout(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textSubtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Difficulty Cards
            VStack(spacing: 16) {
                DifficultyCard(
                    level: 1,
                    title: L10n.Difficulty.beginner,
                    iconColor: DesignTokens.color.difficultyEasy,
                    cefrLevels: "A1-A2",
                    description: L10n.Difficulty.commonEverydayWords,
                    exampleWords: ["Hallo", "Danke", "Guten Morgen"],
                    isSelected: selectedDifficulty == 1,
                    onTap: { selectedDifficulty = 1 }
                )

                DifficultyCard(
                    level: 2,
                    title: L10n.Difficulty.intermediate,
                    iconColor: DesignTokens.color.difficultyMedium,
                    cefrLevels: "B1-B2",
                    description: L10n.Difficulty.moderateVocab,
                    exampleWords: ["Obwohl", "Außerdem", "Trotzdem"],
                    isSelected: selectedDifficulty == 2,
                    onTap: { selectedDifficulty = 2 }
                )

                DifficultyCard(
                    level: 3,
                    title: L10n.Difficulty.advanced,
                    iconColor: DesignTokens.color.difficultyHard,
                    cefrLevels: "C1-C2",
                    description: L10n.Difficulty.complexTerms,
                    exampleWords: ["Gleichwohl", "Gegebenheit", "Auseinandersetzung"],
                    isSelected: selectedDifficulty == 3,
                    onTap: { selectedDifficulty = 3 }
                )
            }
            .padding(.horizontal, 20)

            // Mixed difficulty toggle
            Toggle(isOn: $allowMixed) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Difficulty.mixAllLevels)
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textPrimary)

                    Text(L10n.Difficulty.mixAllLevelsDesc)
                        .font(DesignTokens.typography.caption(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: DesignTokens.color.info))
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignTokens.color.sectionBackground)
                    .designSystemShadow(DesignTokens.shadow.light)
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()

            // Continue button
            Button(action: {
                saveDifficultyPreference()
                onContinue()
            }) {
                HStack(spacing: 10) {
                    Text(L10n.Common.continueButton)
                        .font(DesignTokens.typography.headline(weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            selectedDifficulty != nil ? DesignTokens.color.info : DesignTokens.color.textMuted.opacity(0.5),
                            selectedDifficulty != nil ? DesignTokens.color.primary : DesignTokens.color.textMuted.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: selectedDifficulty != nil ? DesignTokens.color.primary.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                )
            }
            .disabled(selectedDifficulty == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundLight,
                    DesignTokens.color.backgroundMedium
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private func saveDifficultyPreference() {
        guard let progress = userProgress.first else { return }
        progress.preferredDifficultyLevel = selectedDifficulty
        progress.allowMixedDifficulty = allowMixed

        do {
            try modelContext.save()
        } catch {
            print("Error saving difficulty preference: \(error)")
        }
    }
}

// MARK: - Difficulty Card Component

struct DifficultyCard: View {
    let level: Int
    let title: String
    let iconColor: Color
    let cefrLevels: String
    let description: String
    let exampleWords: [String]
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and title
                HStack(spacing: 12) {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DesignTokens.typography.headline(weight: .bold))
                            .foregroundStyle(DesignTokens.color.textPrimary)

                        Text("CEFR \(cefrLevels)")
                            .font(DesignTokens.typography.footnote(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textLight)
                    }

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.color.info)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.color.textMuted)
                    }
                }

                // Description
                Text(description)
                    .font(DesignTokens.typography.caption(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textSubtle)
                    .lineLimit(2)

                // Example words
                HStack(spacing: 8) {
                    Text(L10n.Difficulty.examplesLabel)
                        .font(DesignTokens.typography.footnote(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textLight)

                    ForEach(exampleWords, id: \.self) { word in
                        Text(word)
                            .font(DesignTokens.typography.footnote(weight: .medium))
                            .foregroundStyle(DesignTokens.color.interactiveBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.color.chipBackground)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? DesignTokens.color.cardBackground : DesignTokens.color.sectionBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? DesignTokens.color.info : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? DesignTokens.color.primary.opacity(0.2) : DesignTokens.color.primary.opacity(0.08),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDifficulty: Int? = nil
        @State private var allowMixed: Bool = false

        var body: some View {
            DifficultySelectionView(
                selectedDifficulty: $selectedDifficulty,
                allowMixed: $allowMixed,
                onContinue: {
                    print("Selected difficulty: \(selectedDifficulty ?? 0), Mixed: \(allowMixed)")
                }
            )
        }
    }

    return PreviewWrapper()
        .modelContainer(for: [UserProgress.self, Word.self])
}
