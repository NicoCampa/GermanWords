//
//  WidgetDataWriter.swift
//  aWordaDay
//
//  Created by Codex on 17.11.24.
//

import Foundation
import WidgetKit

enum AppGroupIdentifiers {
    static let shared = "group.com.nicolocampagnoli.aWordaDay"
}

private enum WidgetSharedKeys {
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
}

enum WidgetDataWriter {
    static func updateWidgetData(word: Word?, progress: UserProgress?) {
        guard let userDefaults = UserDefaults(suiteName: AppGroupIdentifiers.shared) else {
            return
        }

        if userDefaults.object(forKey: "widget_show_translation") == nil {
            userDefaults.set(true, forKey: "widget_show_translation")
        }

        // Write target language preference so the widget knows which translation to show
        userDefaults.set(AppLanguage.activeTargetLanguage.rawValue, forKey: "widget_target_language")

        if let word {
            let detail = word.examples.first ?? word.localizedUsageNotes
            let snapshot = WidgetWordSnapshot(
                word: word.word,
                translation: word.translation,
                translationZh: word.translationZh,
                detail: detail,
                cefrLevel: word.cefrLevel,
                streak: progress?.currentStreak ?? 0,
                updatedAt: Date()
            )

            do {
                let data = try JSONEncoder().encode(snapshot)
                userDefaults.set(data, forKey: WidgetSharedKeys.snapshot)
            } catch {
                print("❌ Failed to encode widget snapshot: \(error)")
            }
        } else {
            userDefaults.removeObject(forKey: WidgetSharedKeys.snapshot)
        }

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedKeys.widgetKind)
        }
    }
}
