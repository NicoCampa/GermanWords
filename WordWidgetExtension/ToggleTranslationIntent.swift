//
//  ToggleTranslationIntent.swift
//  WordWidgetExtension
//
//  Created on 17.02.26.
//

import AppIntents
import WidgetKit

struct ToggleTranslationIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Translation"
    static var description: IntentDescription = IntentDescription("Show or hide the translation in the widget.")

    func perform() async throws -> some IntentResult {
        guard let defaults = UserDefaults(suiteName: "group.com.nicolocampagnoli.aWordaDay") else {
            return .result()
        }

        let current = defaults.bool(forKey: "widget_show_translation")
        defaults.set(!current, forKey: "widget_show_translation")

        WidgetCenter.shared.reloadTimelines(ofKind: "WortyWordWidget")

        return .result()
    }
}
