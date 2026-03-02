import SwiftUI
import SwiftData

// MARK: - Enhanced Progress Section
struct ProgressSection: View {
    let currentProgress: UserProgress

    var progressPercentage: Double {
        Double(currentProgress.weeklyProgress) / Double(currentProgress.weeklyGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(DesignTokens.color.learningGreen)

                Text(L10n.Progress.yourProgress)
                    .font(DesignTokens.typography.title(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textSecondary)

                Spacer()
            }

            VStack(spacing: DesignTokens.spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing.xs) {
                        Text(L10n.Progress.weeklyGoal)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textTertiary)

                        Text(L10n.Progress.weeklyGoalOf(currentProgress.weeklyProgress, currentProgress.weeklyGoal))
                            .font(DesignTokens.typography.caption(weight: .medium))
                            .foregroundStyle(DesignTokens.color.textMuted)
                    }

                    Spacer()

                    // Progress circle
                    ZStack {
                        Circle()
                            .stroke(DesignTokens.color.textMuted.opacity(0.2), lineWidth: 6)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: min(progressPercentage, 1.0))
                            .stroke(
                                DesignTokens.color.learningGreen,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(progressPercentage * 100))%")
                            .font(DesignTokens.typography.footnote(weight: .bold))
                            .foregroundStyle(DesignTokens.color.learningGreen)
                    }
                }

                EnhancedProgressBar(
                    progress: progressPercentage,
                    color: DesignTokens.color.learningGreen
                )

                if currentProgress.weeklyProgress >= currentProgress.weeklyGoal {
                    HStack {
                        Image(systemName: "party.popper.fill")
                            .foregroundStyle(DesignTokens.color.gold)
                        Text(L10n.Progress.goalAchieved)
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.learningGreen)
                        Spacer()
                    }
                    .padding(.horizontal, DesignTokens.spacing.md)
                    .padding(.vertical, DesignTokens.spacing.sm)
                    .background(
                        Capsule()
                            .fill(DesignTokens.color.learningGreen.opacity(0.1))
                    )
                }
            }
        }
        .padding(DesignTokens.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.xl)
                .fill(DesignTokens.color.cardBackground)
                .designSystemShadow(DesignTokens.shadow.heavy)
        )
    }
}

// MARK: - Enhanced Progress Bar
struct EnhancedProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignTokens.color.textMuted.opacity(0.15))

                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(progress, 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: geometry.size.width * min(progress, 1.0))
                    )
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 14)
    }
}

// MARK: - Compact Progress Bar
struct QuickStats: View {
    let currentProgress: UserProgress
    let totalWords: Int

    var body: some View {
        VStack(spacing: DesignTokens.spacing.lg) {
            Text(L10n.Progress.yourProgress)
                .font(DesignTokens.typography.callout(weight: .bold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            // Compact horizontal progress bar
            HStack(spacing: DesignTokens.spacing.xl) {
                CompactProgressItem(
                    icon: "flame.fill",
                    value: "\(currentProgress.currentStreak)",
                    color: DesignTokens.color.warning
                )

                Divider()
                    .frame(height: 32)
                    .background(DesignTokens.color.textMuted.opacity(0.3))

                CompactProgressItem(
                    icon: "star.fill",
                    value: "\(currentProgress.currentLevel)",
                    color: DesignTokens.color.gold
                )

                Divider()
                    .frame(height: 32)
                    .background(DesignTokens.color.textMuted.opacity(0.3))

                CompactProgressItem(
                    icon: "book.fill",
                    value: "\(totalWords)",
                    color: DesignTokens.color.info
                )
            }
            .frame(height: 48)
        }
        .padding(.horizontal, DesignTokens.spacing.xl)
        .padding(.vertical, DesignTokens.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(DesignTokens.color.sectionBackground)
                .designSystemShadow(DesignTokens.shadow.medium)
        )
    }
}

// MARK: - Compact Progress Item
struct CompactProgressItem: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        Button(action: {
            // Tap area for future navigation/details
        }) {
            HStack(spacing: DesignTokens.spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)

                Text(value)
                    .font(DesignTokens.typography.headline(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textSecondary)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(icon.replacingOccurrences(of: ".fill", with: "")): \(value)")
    }
}

// MARK: - Compact Stat Card
struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignTokens.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(DesignTokens.typography.callout(weight: .bold))
                .foregroundStyle(DesignTokens.color.textSecondary)

            Text(title)
                .font(DesignTokens.typography.footnote(weight: .medium))
                .foregroundStyle(DesignTokens.color.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, DesignTokens.spacing.xs + 2)
        .padding(.vertical, DesignTokens.spacing.sm + 2)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 80) // enforce equal heights across cards
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(DesignTokens.color.chipBackground)
                .designSystemShadow(DesignTokens.shadow.light)
        )
    }
}
