import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    let currentProgress: UserProgress
    let modelContext: ModelContext
    var isEmbedded: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    @State private var notificationManager = NotificationManager.shared

    @State private var showingNotificationSettings = false
    @State private var showingDifficultyPicker = false
    @State private var showingLanguagePicker = false
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var hasScheduledReminder = false
    
    private var availableWords: [Word] {
        words.filter { $0.sourceLanguage == AppLanguage.sourceCode }
    }
    
    private var favoriteWordsCount: Int {
        words.filter { $0.isFavorite && $0.sourceLanguage == AppLanguage.sourceCode }.count
    }

    private var currentLanguageLabel: String {
        let language = currentProgress.targetLanguage
        return "\(language.flagEmoji) \(language.displayName)"
    }

    private var reminderEnabled: Bool {
        switch notificationPermissionStatus {
        case .authorized, .provisional, .ephemeral:
            return hasScheduledReminder
        default:
            return false
        }
    }

    private var reminderSubtitle: String {
        reminderEnabled
            ? "\(L10n.Notifications.dailyReminderAt) \(formattedNotificationTime())"
            : L10n.Settings.configureReminders
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        DesignTokens.color.backgroundGradientTop,
                        DesignTokens.color.backgroundLight,
                        DesignTokens.color.backgroundMedium
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(DesignTokens.color.accentBlue.opacity(0.14))
                        .frame(width: 220, height: 220)
                        .blur(radius: 50)
                        .offset(x: 70, y: -70)
                }

                ScrollView {
                    VStack(spacing: DesignTokens.spacing.lg2) {
                        overviewCard
                        progressCard
                        learningCard
                        remindersCard
                        aboutCard
                    }
                    .padding(.horizontal, DesignTokens.spacing.lg2)
                    .padding(.top, DesignTokens.spacing.md)
                    .padding(.bottom, DesignTokens.spacing.xxxl)
                }
            }
            .navigationTitle(L10n.Settings.settings)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isEmbedded {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L10n.Common.done) {
                            dismiss()
                        }
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.primary)
                    }
                }
            }
            .onAppear {
                refreshSettingsState()
                FirebaseAnalyticsManager.shared.logSettingsOpened()
                FirebaseAnalyticsManager.shared.logScreenView(FirebaseAnalyticsManager.Screen.settings)
            }
        }
        .sheet(isPresented: $showingNotificationSettings, onDismiss: refreshNotificationSummary) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingDifficultyPicker) {
            DifficultyPickerSheet(
                currentProgress: currentProgress,
                modelContext: modelContext,
                onDismiss: { showingDifficultyPicker = false }
            )
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerSheet(
                currentProgress: currentProgress,
                modelContext: modelContext,
                onDismiss: { showingLanguagePicker = false }
            )
        }
    }

    private var overviewCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg2) {
                HStack(alignment: .top, spacing: DesignTokens.spacing.lg) {
                    SettingsRowIcon(systemName: "text.book.closed.fill", tint: DesignTokens.color.accentBlue, size: 54)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Worty")
                            .font(DesignTokens.typography.largeTitle(weight: .bold))
                            .foregroundStyle(DesignTokens.color.headingPrimary)

                        Text("\(AppLanguage.flagEmoji) \(AppLanguage.displayName)")
                            .font(DesignTokens.typography.callout(weight: .semibold))
                            .foregroundStyle(DesignTokens.color.textSecondary)
                    }

                    Spacer(minLength: DesignTokens.spacing.md)

                    SettingsPill(
                        text: reminderEnabled ? L10n.Common.enabled : L10n.Common.disabled,
                        tint: reminderEnabled ? DesignTokens.color.success : DesignTokens.color.textMuted
                    )
                }

                HStack(spacing: DesignTokens.spacing.sm) {
                    SettingsPill(text: currentLanguageLabel, tint: DesignTokens.color.translationBlue)
                    SettingsPill(text: getDifficultyDisplayName(), tint: DesignTokens.color.learningGreen)
                }

                HStack(spacing: DesignTokens.spacing.md) {
                    SettingsStatTile(
                        value: "\(currentProgress.currentStreak)",
                        label: L10n.Progress.streakTitle,
                        tint: DesignTokens.color.flame,
                        icon: "flame.fill"
                    )
                    SettingsStatTile(
                        value: "\(currentProgress.currentLevel)",
                        label: L10n.Progress.levelTitle,
                        tint: DesignTokens.color.levelBlue,
                        icon: "star.fill"
                    )
                    SettingsStatTile(
                        value: "\(currentProgress.totalWordsLearned)",
                        label: L10n.Progress.wordsLearnedTitle,
                        tint: DesignTokens.color.learningGreen,
                        icon: "checkmark.seal.fill"
                    )
                }
            }
        }
    }

    private var progressCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
                sectionTitle(
                    title: L10n.Settings.progress,
                    icon: "chart.line.uptrend.xyaxis",
                    tint: DesignTokens.color.interactiveBlue
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.spacing.md), count: 2), spacing: DesignTokens.spacing.md) {
                    SettingsMetricTile(
                        title: L10n.Settings.wordsAvailable,
                        value: "\(availableWords.count)",
                        icon: "books.vertical.fill",
                        tint: DesignTokens.color.accentBlue
                    )
                    SettingsMetricTile(
                        title: L10n.Settings.favorites,
                        value: "\(favoriteWordsCount)",
                        icon: "heart.fill",
                        tint: DesignTokens.color.highlight
                    )
                    SettingsMetricTile(
                        title: L10n.Progress.weeklyGoal,
                        value: "\(currentProgress.weeklyProgress)/\(currentProgress.weeklyGoal)",
                        icon: "calendar",
                        tint: DesignTokens.color.success
                    )
                    SettingsMetricTile(
                        title: L10n.Stats.xp,
                        value: "\(currentProgress.totalXP)",
                        icon: "sparkles",
                        tint: DesignTokens.color.levelBlue
                    )
                }
            }
        }
    }

    private var learningCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                sectionTitle(
                    title: L10n.Settings.learningSection,
                    icon: "brain.head.profile",
                    tint: DesignTokens.color.learningGreen
                )

                VStack(spacing: 0) {
                    SettingsNavigationRow(
                        icon: "dial.medium.fill",
                        tint: DesignTokens.color.learningGreen,
                        title: L10n.Settings.difficultyLevel,
                        subtitle: L10n.Settings.difficultyPickerDesc,
                        value: getDifficultyDisplayName(),
                        action: { showingDifficultyPicker = true }
                    )

                    Divider()

                    SettingsNavigationRow(
                        icon: "globe.europe.africa.fill",
                        tint: DesignTokens.color.translationBlue,
                        title: L10n.Settings.displayLanguage,
                        subtitle: L10n.Settings.languagePickerDesc,
                        value: currentLanguageLabel,
                        action: { showingLanguagePicker = true }
                    )
                }
            }
        }
    }

    private var remindersCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                HStack(alignment: .center, spacing: DesignTokens.spacing.md) {
                    sectionTitle(
                        title: L10n.Settings.smartNotifications,
                        icon: "bell.badge.fill",
                        tint: DesignTokens.color.accentBlue
                    )

                    Spacer(minLength: DesignTokens.spacing.sm)

                    SettingsPill(
                        text: reminderEnabled ? L10n.Common.enabled : L10n.Common.disabled,
                        tint: reminderEnabled ? DesignTokens.color.success : DesignTokens.color.textMuted
                    )
                }

                SettingsNavigationRow(
                    icon: "bell.and.waves.left.and.right.fill",
                    tint: DesignTokens.color.accentBlue,
                    title: L10n.Settings.notificationSettings,
                    subtitle: reminderSubtitle,
                    value: reminderEnabled ? formattedNotificationTime() : nil,
                    action: { showingNotificationSettings = true }
                )
            }
        }
    }

    private var aboutCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                sectionTitle(
                    title: L10n.Settings.about,
                    icon: "info.circle",
                    tint: DesignTokens.color.textMuted
                )

                VStack(spacing: 0) {
                    SettingsInfoRow(
                        icon: "info.circle.fill",
                        tint: DesignTokens.color.textMuted,
                        title: L10n.Settings.appVersion,
                        value: appVersionText
                    )
                }
            }
        }
    }

    private func sectionTitle(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: DesignTokens.spacing.md) {
            SettingsRowIcon(systemName: icon, tint: tint, size: 42)

            Text(title)
                .font(DesignTokens.typography.headline(weight: .bold))
                .foregroundStyle(DesignTokens.color.textDark)
        }
    }

    private func refreshSettingsState() {
        currentProgress.resetDailyWordProgressIfNeeded()
        try? modelContext.save()
        refreshNotificationSummary()
    }

    private func refreshNotificationSummary() {
        Task {
            let status = await notificationManager.checkPermissionStatus()
            let hasReminder = await notificationManager.hasCurrentDailyWordNotification()

            await MainActor.run {
                notificationPermissionStatus = status
                hasScheduledReminder = hasReminder
            }
        }
    }

    private func formattedNotificationTime() -> String {
        let hour = notificationManager.dailyNotificationTime.hour ?? 9
        let minute = notificationManager.dailyNotificationTime.minute ?? 0

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func getDifficultyDisplayName() -> String {
        if currentProgress.allowMixedDifficulty == true {
            return L10n.Settings.mixedAllLevels
        }

        guard let difficulty = currentProgress.preferredDifficultyLevel else {
            return L10n.Settings.notSet
        }

        switch difficulty {
        case 1: return L10n.Settings.beginnerCEFR()
        case 2: return L10n.Settings.intermediateCEFR()
        case 3: return L10n.Settings.advancedCEFR()
        default: return L10n.Settings.notSet
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignTokens.spacing.lg2)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(DesignTokens.color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
            )
    }
}

struct SettingsRowIcon: View {
    let systemName: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.14))

            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

struct SettingsPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(DesignTokens.typography.footnote(weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }
}

struct SettingsStatTile: View {
    let value: String
    let label: String
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(DesignTokens.typography.title(weight: .bold))
                .foregroundStyle(DesignTokens.color.textDark)

            Text(label)
                .font(DesignTokens.typography.footnote(weight: .medium))
                .foregroundStyle(DesignTokens.color.textLight)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.1))
        )
    }
}

struct SettingsMetricTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
            HStack(spacing: DesignTokens.spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(DesignTokens.typography.footnote(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .lineLimit(1)
            }

            Text(value)
                .font(DesignTokens.typography.headline(weight: .bold))
                .foregroundStyle(DesignTokens.color.textDark)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(DesignTokens.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(tint.opacity(0.1))
        )
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: DesignTokens.spacing.lg) {
                SettingsRowIcon(systemName: icon, tint: tint, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignTokens.typography.callout(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textDark)

                    Text(subtitle)
                        .font(DesignTokens.typography.footnote(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textLight)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DesignTokens.spacing.md)

                if let value, !value.isEmpty {
                    Text(value)
                        .font(DesignTokens.typography.footnote(weight: .semibold))
                        .foregroundStyle(DesignTokens.color.textSecondary)
                        .multilineTextAlignment(.trailing)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textMuted)
            }
            .padding(.vertical, DesignTokens.spacing.md)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacing.lg) {
            SettingsRowIcon(systemName: icon, tint: tint, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.typography.callout(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textDark)

                Text(subtitle)
                    .font(DesignTokens.typography.footnote(weight: .medium))
                    .foregroundStyle(DesignTokens.color.textLight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: DesignTokens.spacing.md)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(.vertical, DesignTokens.spacing.md)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacing.lg) {
            SettingsRowIcon(systemName: icon, tint: tint, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.typography.callout(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textDark)
            }

            Spacer(minLength: DesignTokens.spacing.md)

            Text(value)
                .font(DesignTokens.typography.footnote(weight: .semibold))
                .foregroundStyle(DesignTokens.color.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, DesignTokens.spacing.md)
    }
}

// MARK: - Word Detail View
struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.spacing.xl) {
                    // Header
                    VStack(spacing: DesignTokens.spacing.lg) {
                        HStack {
                            Spacer()
                            Text(difficultyText(level: word.difficultyLevel))
                                .font(DesignTokens.typography.footnote(weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, DesignTokens.spacing.sm)
                                .padding(.vertical, DesignTokens.spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(difficultyColor(level: word.difficultyLevel))
                                )
                        }
                        
                        VStack(spacing: DesignTokens.spacing.md) {
                            Text(word.word)
                                .font(DesignTokens.typography.largeTitle(weight: .bold))
                                .foregroundStyle(DesignTokens.color.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(word.localizedTranslation)
                                .font(DesignTokens.typography.title(weight: .semibold))
                                .foregroundStyle(DesignTokens.color.translationBlue)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top)
                    
                    // Usage Notes
                    if let usageNotes = word.localizedUsageNotes, !usageNotes.isEmpty {
                        DetailCard(title: L10n.WordDetail.usageNotes, content: usageNotes, icon: "book.fill")
                    }

                    // Examples
                    if !word.localizedExamplePairs.isEmpty {
                        let examplesText = word.localizedExamplePairs
                            .enumerated()
                            .map { index, pair -> String in
                                let translation = pair.1.isEmpty ? "" : "\n   → \(pair.1)"
                                return "\(index + 1). \(pair.0)\(translation)"
                            }
                            .joined(separator: "\n\n")
                        DetailCard(title: L10n.Common.examples, content: examplesText, icon: "quote.bubble.fill")
                    }
                    
                    // Curiosity Facts
                    if let facts = word.localizedCuriosityFacts, !facts.isEmpty {
                        DetailCard(title: L10n.WordDetail.didYouKnow, content: facts, icon: "lightbulb.fill")
                    }
                    
                    if let related = word.relatedWordsText {
                        DetailCard(title: L10n.WordDetail.relatedWords, content: related, icon: "link.circle.fill")
                    }

                    // Additional fields

                    if let cefrLevel = word.cefrLevel, !cefrLevel.isEmpty {
                        DetailCard(title: L10n.WordDetail.cefrLevel, content: cefrLevel, icon: "graduationcap.fill")
                    }

                    if let plural = word.plural, !plural.isEmpty {
                        DetailCard(title: L10n.WordDetail.pluralForm, content: L10n.WordDetail.plural(plural), icon: "character.textbox")
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, DesignTokens.spacing.lg2)
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
            .navigationTitle(L10n.WordDetail.wordDetails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func difficultyText(level: Int) -> String {
        switch level {
        case 1: return L10n.Difficulty.easy
        case 2: return L10n.Difficulty.medium
        case 3: return L10n.Difficulty.hard
        default: return L10n.Difficulty.easy
        }
    }
    
    private func difficultyColor(level: Int) -> Color {
        switch level {
        case 1: return DesignTokens.color.difficultyEasy
        case 2: return DesignTokens.color.difficultyMedium
        case 3: return DesignTokens.color.difficultyHard
        default: return DesignTokens.color.difficultyEasy
        }
    }
}

// MARK: - Detail Card
struct DetailCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.color.primary)

                Text(title)
                    .font(DesignTokens.typography.headline(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.textSecondary)

                Spacer()
            }

            Text(content)
                .font(DesignTokens.typography.callout(weight: .medium))
                .foregroundStyle(DesignTokens.color.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.spacing.lg2)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.xl)
                .fill(DesignTokens.color.sectionBackground)
                .shadow(color: DesignTokens.color.primary.opacity(0.12), radius: 10, x: 0, y: 6)
        )
    }
}

// MARK: - Difficulty Picker Sheet

struct DifficultyPickerSheet: View {
    let currentProgress: UserProgress
    let modelContext: ModelContext
    let onDismiss: () -> Void

    @State private var selectedDifficulty: Int?
    @State private var allowMixed: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing.xl) {
                        // Header description
                        VStack(spacing: DesignTokens.spacing.md) {
                            Text(L10n.Settings.difficultyPickerDesc)
                                .font(DesignTokens.typography.callout(weight: .medium))
                                .foregroundStyle(DesignTokens.color.textSubtle)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignTokens.spacing.lg2)
                        }
                        .padding(.top, DesignTokens.spacing.lg)

                        // Difficulty Cards
                        VStack(spacing: DesignTokens.spacing.lg) {
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
                        .padding(.vertical, DesignTokens.spacing.lg2)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                                .fill(DesignTokens.color.sectionBackground)
                                .designSystemShadow(DesignTokens.shadow.light)
                        )
                        .padding(.horizontal, DesignTokens.spacing.lg2)
                    }
                    .padding(.bottom, 100)
                }

                // Save button
                VStack(spacing: 0) {
                    Divider()

                    Button(action: {
                        saveDifficultyPreference()
                        onDismiss()
                    }) {
                        HStack(spacing: 10) {
                            Text(L10n.Common.save)
                                .font(DesignTokens.typography.headline(weight: .bold))
                            Image(systemName: "checkmark")
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
                    .padding(.vertical, DesignTokens.spacing.lg)
                }
                .background(DesignTokens.color.backgroundLight)
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
            .navigationTitle(L10n.Settings.difficultyLevel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.cancel) {
                        onDismiss()
                    }
                    .font(DesignTokens.typography.callout(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.primary)
                }
            }
        }
        .onAppear {
            selectedDifficulty = currentProgress.preferredDifficultyLevel
            allowMixed = currentProgress.allowMixedDifficulty ?? false
        }
    }

    private func saveDifficultyPreference() {
        currentProgress.preferredDifficultyLevel = selectedDifficulty
        currentProgress.allowMixedDifficulty = allowMixed

        do {
            try modelContext.save()
        } catch {
            print("Error saving difficulty preference: \(error)")
        }
    }
}

// MARK: - Language Picker Sheet

struct LanguagePickerSheet: View {
    let currentProgress: UserProgress
    let modelContext: ModelContext
    let onDismiss: () -> Void

    @State private var selectedLanguage: TargetLanguage = .english

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing.xl) {
                        VStack(spacing: DesignTokens.spacing.md) {
                            Text(L10n.Settings.languagePickerDesc)
                                .font(DesignTokens.typography.callout(weight: .medium))
                                .foregroundStyle(DesignTokens.color.textSubtle)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignTokens.spacing.lg2)
                        }
                        .padding(.top, DesignTokens.spacing.lg)

                        VStack(spacing: DesignTokens.spacing.lg) {
                            ForEach(TargetLanguage.allCases, id: \.self) { language in
                                Button(action: { selectedLanguage = language }) {
                                    HStack(spacing: DesignTokens.spacing.lg) {
                                        Text(language.flagEmoji)
                                            .font(.system(size: 32))

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(language.displayName)
                                                .font(DesignTokens.typography.callout(weight: .bold))
                                                .foregroundStyle(DesignTokens.color.textPrimary)

                                            Text(language.nativeName)
                                                .font(DesignTokens.typography.caption(weight: .medium))
                                                .foregroundStyle(DesignTokens.color.textLight)
                                        }

                                        Spacer()

                                        if selectedLanguage == language {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundStyle(DesignTokens.color.primary)
                                        } else {
                                            Circle()
                                                .stroke(DesignTokens.color.textMuted, lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                    .padding(DesignTokens.spacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                                            .fill(selectedLanguage == language
                                                ? DesignTokens.color.primary.opacity(0.08)
                                                : DesignTokens.color.sectionBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                                                    .stroke(
                                                        selectedLanguage == language
                                                            ? DesignTokens.color.primary.opacity(0.3)
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DesignTokens.spacing.lg2)
                    }
                    .padding(.bottom, 100)
                }

                VStack(spacing: 0) {
                    Divider()

                    Button(action: {
                        saveLanguagePreference()
                        onDismiss()
                    }) {
                        HStack(spacing: 10) {
                            Text(L10n.Common.save)
                                .font(DesignTokens.typography.headline(weight: .bold))
                            Image(systemName: "checkmark")
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
                    .padding(.vertical, DesignTokens.spacing.lg)
                }
                .background(DesignTokens.color.backgroundLight)
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
            .navigationTitle(L10n.Settings.displayLanguage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.cancel) {
                        onDismiss()
                    }
                    .font(DesignTokens.typography.callout(weight: .semibold))
                    .foregroundStyle(DesignTokens.color.primary)
                }
            }
        }
        .onAppear {
            selectedLanguage = currentProgress.targetLanguage
        }
    }

    private func saveLanguagePreference() {
        currentProgress.targetLanguage = selectedLanguage
        AppLanguage.activeTargetLanguage = selectedLanguage

        do {
            try modelContext.save()
        } catch {
            print("Error saving language preference: \(error)")
        }
    }
}
