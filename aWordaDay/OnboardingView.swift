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

// MARK: - Page 1: Welcome

struct OnboardingWelcomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appStates: [AppState]

    @State private var mascotScale: CGFloat = 0.8
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

                    Text(L10n.Onboarding.startFullCatalog)
                        .font(DesignTokens.typography.body(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    onboardingCallout(
                        icon: "sparkles",
                        tint: DesignTokens.color.learningGreen,
                        title: "All levels included",
                        detail: "New words now come from the full German catalog automatically."
                    )

                    onboardingCallout(
                        icon: "heart.fill",
                        tint: DesignTokens.color.difficultyHard,
                        title: "Double-tap to favorite",
                        detail: "Double-tap any word card to save it. A red heart pop confirms it instantly."
                    )
                }
                .padding(.horizontal, DesignTokens.spacing.lg2)

                // Continue button
                Button(action: {
                    initializeLearningPreferences()
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
                                DesignTokens.color.info,
                                DesignTokens.color.primary
                            ],
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
            .padding(.top, DesignTokens.spacing.md)
        }
    }

    private func onboardingCallout(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.typography.callout(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textPrimary)

                Text(detail)
                    .font(DesignTokens.typography.caption(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.spacing.lg)
        .padding(.vertical, DesignTokens.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(DesignTokens.color.sectionBackground)
                .designSystemShadow(DesignTokens.shadow.light)
        )
    }

    private func initializeLearningPreferences() {
        let progress = AppState.current(in: modelContext, cached: appStates)
        progress.targetLanguage = .english
        AppLanguage.activeTargetLanguage = .english
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
                    icon: "sparkles",
                    iconColor: DesignTokens.color.success,
                    title: L10n.Onboarding.smartReview,
                    description: L10n.Onboarding.smartReviewDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showFeatures)

                OnboardingFeatureRow(
                    icon: "text.magnifyingglass",
                    iconColor: DesignTokens.color.info,
                    title: L10n.Onboarding.browseLibrary,
                    description: L10n.Onboarding.browseLibraryDesc
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showFeatures)

                OnboardingFeatureRow(
                    icon: "sparkle.magnifyingglass",
                    iconColor: DesignTokens.color.warning,
                    title: L10n.Onboarding.funGames,
                    description: L10n.Onboarding.funGamesDesc
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
