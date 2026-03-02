//
//  OnboardingView.swift
//  aWordaDay
//
//  Created by Claude on 15.10.25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedDifficulty: Int? = nil
    @State private var allowMixed: Bool = false
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundGradientTop,
                    DesignTokens.color.backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (page 1 only)
                HStack {
                    Spacer()
                    Button(L10n.Common.skip) {
                        onComplete()
                    }
                    .font(DesignTokens.typography.callout(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .padding(.trailing, DesignTokens.spacing.xl)
                    .padding(.top, DesignTokens.spacing.lg)
                }
                .opacity(currentPage <= 1 ? 1 : 0)

                // Page content
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage(
                        selectedDifficulty: $selectedDifficulty,
                        allowMixed: $allowMixed,
                        onContinue: {
                            withAnimation { currentPage = 1 }
                        }
                    )
                    .tag(0)

                    OnboardingFeaturesPage(onContinue: {
                        withAnimation { currentPage = 2 }
                    })
                    .tag(1)

                    OnboardingReadyPage(onComplete: onComplete)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }
}

// MARK: - Page 1: Welcome + Difficulty Selection

struct OnboardingWelcomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]

    @State private var mascotScale: CGFloat = 0.8
    @State private var selectedTargetLanguage: TargetLanguage = .english
    @Binding var selectedDifficulty: Int?
    @Binding var allowMixed: Bool
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing.xl) {
                // Mascot
                SharedCloudMascot(scale: mascotScale)
                    .designSystemShadow(DesignTokens.shadow.medium)
                    .onAppear {
                        withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                            mascotScale = 1.3
                        }
                    }

                // Title
                VStack(spacing: 10) {
                    Text(L10n.Onboarding.welcomeToWorty)
                        .font(DesignTokens.typography.largeTitle(weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignTokens.color.textPrimary,
                                    DesignTokens.color.headingPrimary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)

                    Text(L10n.Onboarding.pickLevel)
                        .font(DesignTokens.typography.body(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                }

                // Difficulty Cards
                VStack(spacing: 14) {
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
                        exampleWords: ["Gleichwohl", "Gegebenheit"],
                        isSelected: selectedDifficulty == 3,
                        onTap: { selectedDifficulty = 3 }
                    )
                }
                .padding(.horizontal, DesignTokens.spacing.lg2)

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
                .padding(.horizontal, DesignTokens.spacing.xl)
                .padding(.vertical, DesignTokens.spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                        .fill(DesignTokens.color.sectionBackground)
                        .designSystemShadow(DesignTokens.shadow.light)
                )
                .padding(.horizontal, DesignTokens.spacing.lg2)

                // Language selector
                HStack(spacing: DesignTokens.spacing.md) {
                    Text(L10n.Onboarding.explanationsIn)
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textPrimary)

                    Spacer()

                    Menu {
                        ForEach(TargetLanguage.allCases, id: \.self) { lang in
                            Button {
                                selectedTargetLanguage = lang
                            } label: {
                                HStack {
                                    Text("\(lang.flagEmoji) \(lang.displayName)")
                                    if selectedTargetLanguage == lang {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(selectedTargetLanguage.flagEmoji) \(selectedTargetLanguage.displayName)")
                                .font(DesignTokens.typography.callout(weight: .semibold))
                                .foregroundStyle(DesignTokens.color.primary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DesignTokens.color.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, DesignTokens.spacing.sm)
                        .background(
                            Capsule()
                                .fill(DesignTokens.color.primary.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.spacing.xl)
                .padding(.vertical, DesignTokens.spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                        .fill(DesignTokens.color.sectionBackground)
                        .designSystemShadow(DesignTokens.shadow.light)
                )
                .padding(.horizontal, DesignTokens.spacing.lg2)

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
                    .padding(.vertical, DesignTokens.spacing.lg)
                    .background(
                        LinearGradient(
                            colors: [
                                selectedDifficulty != nil ? DesignTokens.color.info : DesignTokens.color.textMuted.opacity(0.5),
                                selectedDifficulty != nil ? DesignTokens.color.primary : DesignTokens.color.textMuted.opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous))
                        .shadow(color: selectedDifficulty != nil ? DesignTokens.color.primary.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                    )
                }
                .disabled(selectedDifficulty == nil)
                .padding(.horizontal, DesignTokens.spacing.lg2)
                .padding(.bottom, 40)
            }
            .padding(.top, DesignTokens.spacing.md)
        }
    }

    private func saveDifficultyPreference() {
        guard let progress = userProgress.first else { return }
        progress.preferredDifficultyLevel = selectedDifficulty
        progress.allowMixedDifficulty = allowMixed
        progress.targetLanguage = selectedTargetLanguage
        AppLanguage.activeTargetLanguage = selectedTargetLanguage
        try? modelContext.save()
    }
}

// MARK: - Page 2: Feature Showcase

struct OnboardingFeaturesPage: View {
    let onContinue: () -> Void
    @State private var showFeatures = false

    var body: some View {
        VStack(spacing: DesignTokens.spacing.xl) {
            Spacer()

            // Header
            VStack(spacing: DesignTokens.spacing.md) {
                Text(L10n.Onboarding.whatYoullGet)
                    .font(DesignTokens.typography.largeTitle(weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignTokens.color.textPrimary,
                                DesignTokens.color.headingPrimary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text(L10n.Onboarding.everythingToMaster)
                    .font(DesignTokens.typography.body(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
            }

            // Feature rows
            VStack(spacing: DesignTokens.spacing.md) {
                OnboardingFeatureRow(
                    icon: "book.fill",
                    iconColor: DesignTokens.color.primary,
                    title: L10n.Onboarding.dailyWords,
                    description: L10n.Onboarding.dailyWordsDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)

                OnboardingFeatureRow(
                    icon: "gamecontroller.fill",
                    iconColor: DesignTokens.color.success,
                    title: L10n.Onboarding.funGames,
                    description: L10n.Onboarding.funGamesDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showFeatures)

                OnboardingFeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: DesignTokens.color.info,
                    title: L10n.Onboarding.aiTutor,
                    description: L10n.Onboarding.aiTutorDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showFeatures)

                OnboardingFeatureRow(
                    icon: "widget.small",
                    iconColor: DesignTokens.color.warning,
                    title: L10n.Onboarding.homeWidget,
                    description: L10n.Onboarding.homeWidgetDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showFeatures)
            }
            .padding(.horizontal, DesignTokens.spacing.lg2)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text(L10n.Common.continueButton)
                        .font(DesignTokens.typography.headline(weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacing.lg)
                .background(
                    LinearGradient(
                        colors: [DesignTokens.color.info, DesignTokens.color.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous))
                    .shadow(color: DesignTokens.color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .padding(.horizontal, DesignTokens.spacing.lg2)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showFeatures = true
            }
        }
    }
}

// MARK: - Page 3: Ready

struct OnboardingReadyPage: View {
    @State private var isAnimating = false
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.spacing.xxl) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.color.success,
                                DesignTokens.color.success.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)

                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            .designSystemShadow(DesignTokens.shadow.heavy)

            VStack(spacing: DesignTokens.spacing.lg) {
                Text(L10n.Onboarding.youreAllSet)
                    .font(DesignTokens.typography.largeTitle(weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                DesignTokens.color.textPrimary,
                                DesignTokens.color.headingPrimary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text(L10n.Onboarding.letsStart)
                    .font(DesignTokens.typography.headline(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.spacing.xxl)
            }

            // Get Started button
            Button(action: {
                FirebaseAnalyticsManager.shared.logOnboardingCompleted()
                onComplete()
            }) {
                HStack(spacing: DesignTokens.spacing.md) {
                    Text(L10n.Onboarding.getStarted)
                        .font(DesignTokens.typography.headline(weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.spacing.xxxl)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.color.primary,
                                    DesignTokens.color.genderMasculine
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: DesignTokens.color.genderMasculine.opacity(0.4), radius: 20, x: 0, y: 10)
            }
            .padding(.top, DesignTokens.spacing.lg)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Feature Row Component (kept for potential reuse)

struct OnboardingFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.typography.body(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textDark)

                Text(description)
                    .font(DesignTokens.typography.caption(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.vertical, DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(DesignTokens.color.sectionBackground)
        )
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
