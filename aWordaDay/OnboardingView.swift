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
                    Text(L10n.Onboarding.welcomeTitle)
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

                    Text(L10n.Onboarding.welcomeSubtitle)
                        .font(DesignTokens.typography.body(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    onboardingCallout(
                        icon: "text.book.closed.fill",
                        tint: DesignTokens.color.primary,
                        title: L10n.Onboarding.examplesAndNotes,
                        detail: L10n.Onboarding.examplesAndNotesDesc
                    )

                    onboardingCallout(
                        icon: "heart.fill",
                        tint: DesignTokens.color.difficultyHard,
                        title: L10n.Onboarding.doubleTapToSave,
                        detail: L10n.Onboarding.doubleTapToSaveDesc
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
        ScrollView {
            VStack(spacing: DesignTokens.spacing.xl) {
                VStack(spacing: DesignTokens.spacing.md) {
                    Text(L10n.Onboarding.howItWorks)
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

                    Text(L10n.Onboarding.howItWorksSubtitle)
                        .font(DesignTokens.typography.body(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, DesignTokens.spacing.xl)

                VStack(spacing: DesignTokens.spacing.md) {
                    OnboardingFeatureRow(
                        icon: "book.fill",
                        iconColor: DesignTokens.color.primary,
                        title: L10n.Onboarding.oneWordAtATime,
                        description: L10n.Onboarding.oneWordAtATimeDesc
                    )
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 20)

                    OnboardingFeatureRow(
                        icon: "heart.fill",
                        iconColor: DesignTokens.color.difficultyHard,
                        title: L10n.Onboarding.saveFavorites,
                        description: L10n.Onboarding.saveFavoritesDesc
                    )
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showFeatures)

                    OnboardingFeatureRow(
                        icon: "books.vertical.fill",
                        iconColor: DesignTokens.color.info,
                        title: L10n.Onboarding.browseYourLibrary,
                        description: L10n.Onboarding.browseYourLibraryDesc
                    )
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showFeatures)

                    OnboardingFeatureRow(
                        icon: "bell.fill",
                        iconColor: DesignTokens.color.warning,
                        title: L10n.Onboarding.optionalDailyReminder,
                        description: L10n.Onboarding.optionalDailyReminderDesc
                    )
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showFeatures)
                }
                .padding(.horizontal, DesignTokens.spacing.lg2)

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
    @State private var mascotScale: CGFloat = 0.92
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.spacing.xxl) {
            Spacer()

            SharedCloudMascot(scale: mascotScale)
                .designSystemShadow(DesignTokens.shadow.medium)
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.65)) {
                        mascotScale = 1.12
                    }
                }

            VStack(spacing: DesignTokens.spacing.lg) {
                Text(L10n.Onboarding.readyTitle)
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

                Text(L10n.Onboarding.readySubtitle)
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
                    Text(L10n.Onboarding.startLearning)
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
                    .fixedSize(horizontal: false, vertical: true)
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
