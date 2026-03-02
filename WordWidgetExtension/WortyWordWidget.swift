//
//  WortyWordWidget.swift
//  WordWidgetExtension
//
//  Rebuilt on 24.11.25 to provide a more resilient widget experience.
//

import AppIntents
import SwiftUI
import WidgetKit

private enum WidgetSharedKeys {
    static let appGroup = "group.com.nicolocampagnoli.aWordaDay"
    static let snapshot = "widget_word_snapshot"
    static let widgetKind = "WortyWordWidget"
}

private struct WidgetWordSnapshot: Codable {
    let word: String
    let translation: String
    let translationZh: String?
    let detail: String?
    let cefrLevel: String?
    let streak: Int
    let updatedAt: Date

    /// Returns the appropriate translation based on target language preference.
    func displayTranslation(targetLanguage: String?) -> String {
        if targetLanguage == "zh", let zh = translationZh, !zh.isEmpty {
            return zh
        }
        return translation
    }
}

private enum WortyWidgetState: String {
    case ready
    case needsSync
    case error
}

private struct WortyWidgetEntry: TimelineEntry {
    let date: Date
    let state: WortyWidgetState
    let data: WidgetWordSnapshot
    let showTranslation: Bool
    let targetLanguage: String?

    static var placeholder: WortyWidgetEntry {
        WortyWidgetEntry(
            date: Date(),
            state: .ready,
            data: WidgetWordSnapshot(
                word: "Fernweh",
                translation: "Wanderlust",
                translationZh: nil,
                detail: "Ich habe Fernweh und möchte die Welt sehen.",
                cefrLevel: "B2",
                streak: 12,
                updatedAt: Date()
            ),
            showTranslation: true,
            targetLanguage: nil
        )
    }
}

private struct WortyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WortyWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WortyWidgetEntry) -> Void) {
        completion(loadLatestEntry(fallbackState: .needsSync))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WortyWidgetEntry>) -> Void) {
        let entry = loadLatestEntry(fallbackState: .needsSync)
        // Refresh every hour so the widget stays current if the app hasn't posted new data yet.
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3_600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadLatestEntry(fallbackState: WortyWidgetState) -> WortyWidgetEntry {
        guard let defaults = UserDefaults(suiteName: WidgetSharedKeys.appGroup) else {
            return WortyWidgetEntry(date: Date(), state: .error, data: WortyWidgetEntry.placeholder.data, showTranslation: true, targetLanguage: nil)
        }

        let showTranslation = defaults.object(forKey: "widget_show_translation") == nil
            ? true
            : defaults.bool(forKey: "widget_show_translation")

        let targetLanguage = defaults.string(forKey: "widget_target_language")

        guard let snapshotData = defaults.data(forKey: WidgetSharedKeys.snapshot),
              let snapshot = try? JSONDecoder().decode(WidgetWordSnapshot.self, from: snapshotData) else {
            return WortyWidgetEntry(date: Date(), state: fallbackState, data: WortyWidgetEntry.placeholder.data, showTranslation: showTranslation, targetLanguage: targetLanguage)
        }

        return WortyWidgetEntry(date: Date(), state: .ready, data: snapshot, showTranslation: showTranslation, targetLanguage: targetLanguage)
    }
}

private struct WortyWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    var entry: WortyWidgetEntry

    var body: some View {
        switch entry.state {
        case .ready:
            readyView
        case .needsSync:
            emptyStateView(
                title: "Noch kein Wort",
                message: "Öffne Worty, um deinen Tageswortschatz zu laden."
            )
        case .error:
            emptyStateView(
                title: "Widget nicht erreichbar",
                message: "Stelle sicher, dass Worty installiert ist und App-Gruppen aktiviert sind."
            )
        }
    }

    private var readyView: some View {
        ZStack {
            angularBackdrop
            haloLayer
            VStack(alignment: .leading, spacing: 10) {
                header
                wordCard
                Spacer(minLength: 8)
                footer
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                .blendMode(.screen)
        )
        .widgetURL(URL(string: "awordaday://open"))
    }

    private var angularBackdrop: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.29, green: 0.55, blue: 0.98),
                Color(red: 0.48, green: 0.73, blue: 1.0),
                Color(red: 0.80, green: 0.92, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var haloLayer: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.20))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: 60, y: -60)
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 120, height: 120)
                .blur(radius: 25)
                .offset(x: -70, y: 50)
        }
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Heutiges Wort")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.85))

                if let cefr = entry.data.cefrLevel {
                    Text("CEFR \(cefr)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                        .foregroundColor(.white)
                }
            }

            Spacer()

            if entry.data.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("\(entry.data.streak)d")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.data.word)
                .font(.system(size: widgetFamily == .systemSmall ? 22 : 26, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.08, green: 0.2, blue: 0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if entry.showTranslation {
                Text(entry.data.displayTranslation(targetLanguage: entry.targetLanguage))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("Tap to reveal")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let detail = entry.data.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.7))
                    .lineLimit(widgetFamily == .systemSmall ? 2 : 3)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button(intent: ToggleTranslationIntent()) {
                Image(systemName: entry.showTranslation ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(.plain)

            Text("Worty")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.85))
        }
    }

    private func emptyStateView(title: String, message: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.9, green: 0.94, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.8))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.6))
                Text(message)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct WortyWordWidget: Widget {
    let kind: String = WidgetSharedKeys.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WortyWidgetProvider()) { entry in
            WortyWidgetView(entry: entry)
        }
        .configurationDisplayName("Worty Tageswort")
        .description("Sieh dein aktuelles deutsches Wort auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
