//
//  NotificationManager.swift
//  aWordaDay
//
//  Created by Claude on 08.10.25
//

import Foundation
import UserNotifications
import SwiftData

private let notificationWordIDKey = "notification_word_id"

@MainActor
@Observable
class NotificationManager: NSObject, NotificationManagerProtocol {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let selector = NotificationWordSelector()
    
    // Notification identifiers
    private let dailyWordIdentifier = "daily_word_notification"
    // Settings keys
    private let dailyNotificationTimeKey = "daily_notification_time"

    var isNotificationsEnabled = false
    var dailyNotificationTime = DateComponents(hour: 9, minute: 0)
    private(set) var pendingNotificationWordID: String?
    
    private override init() {
        super.init()
        center.delegate = self
        loadSettings()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        // Load notification time with proper error handling
        if let timeData = UserDefaults.standard.data(forKey: dailyNotificationTimeKey) {
            do {
                let time = try JSONDecoder().decode(DateComponents.self, from: timeData)
                dailyNotificationTime = time
                #if DEBUG
                print("✅ Loaded notification time: \(time.hour ?? 9):\(String(format: "%02d", time.minute ?? 0))")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to decode notification time, using default 9:00 AM: \(error)")
                #endif
                dailyNotificationTime = DateComponents(hour: 9, minute: 0)
            }
        } else {
            #if DEBUG
            print("ℹ️ No saved notification time, using default 9:00 AM")
            #endif
            dailyNotificationTime = DateComponents(hour: 9, minute: 0)
        }
    }

    private func saveSettings() {
        // Save notification time with proper error handling
        do {
            let timeData = try JSONEncoder().encode(dailyNotificationTime)
            UserDefaults.standard.set(timeData, forKey: dailyNotificationTimeKey)
            #if DEBUG
            print("✅ Saved notification time: \(dailyNotificationTime.hour ?? 9):\(String(format: "%02d", dailyNotificationTime.minute ?? 0))")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to encode notification time: \(error)")
            #endif
        }
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .provisional])
            await updateNotificationStatus()
            #if DEBUG
            print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
            #endif
            return granted
        } catch {
            #if DEBUG
            print("❌ Error requesting notification permission: \(error)")
            #endif
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    private func updateNotificationStatus() async {
        let status = await checkPermissionStatus()
        isNotificationsEnabled = status == .authorized || status == .provisional
    }
    
    // MARK: - Smart Daily Notifications
    
    func scheduleDailyWordNotification(with modelContext: ModelContext) async {
        let status = await checkPermissionStatus()
        guard status == .authorized || status == .provisional else {
            #if DEBUG
            print("❌ Notifications not authorized")
            #endif
            return
        }

        await removeLegacyNotificationsIfNeeded()

        // Cancel existing daily notification only (not test notifications)
        center.removePendingNotificationRequests(withIdentifiers: [dailyWordIdentifier])
        #if DEBUG
        print("🗑️ Cleared existing daily word notification")
        #endif

        let content: UNMutableNotificationContent
        if let word = selector.selectWord(modelContext: modelContext, language: AppLanguage.sourceCode) {
            content = createDailyWordContent(for: word)
        } else {
            let fallback = UNMutableNotificationContent()
            fallback.title = L10n.Notifications.dailyWordAwaits
            fallback.body = L10n.Notifications.openAppToDiscover
            fallback.sound = .default
            fallback.badge = NSNumber(value: 1)
            fallback.categoryIdentifier = "DAILY_WORD"
            content = fallback
        }

        // Create calendar trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dailyNotificationTime, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyWordIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            #if DEBUG
            print("✅ Daily notification reminder scheduled")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error scheduling daily notification: \(error)")
            #endif
        }
    }

    // MARK: - Smart Content Generation
    
    private func createDailyWordContent(for word: CatalogWordDetail) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Personalized titles based on user progress
        let titles = [
            "🌟 \(L10n.Notifications.todaysWord): \(word.word)",
            "📚 \(L10n.Notifications.learnColon): \(word.word)",
            "🎯 \(L10n.Notifications.newChallenge): \(word.word)",
            "💡 \(L10n.Notifications.discoverColon): \(word.word)"
        ]

        content.title = titles.randomElement() ?? "\(L10n.Notifications.todaysWord): \(word.word)"
        
        // Generate fun fallback message if word doesn't have custom notification
        let fallbackBody: String = generateFunNotification(for: word)
        
        if let rawMessage = word.localizedNotificationMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawMessage.isEmpty {
            if rawMessage.count <= 45 {
                content.body = rawMessage
            } else {
                #if DEBUG
                print("⚠️ Notification message for \(word.word) exceeds 45 chars (\(rawMessage.count)). Using fallback copy.")
                #endif
                content.body = fallbackBody
            }
        } else {
            content.body = fallbackBody
        }
        
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DAILY_WORD"
        content.targetContentIdentifier = word.id
        content.userInfo = [notificationWordIDKey: word.id]
        
        return content
    }

    /// Generate a fun, emoji-rich notification message for words without custom messages
    private func generateFunNotification(for word: CatalogWordDetail) -> String {
        let w = word.word
        let t = word.localizedTranslation
        let zh = AppLanguage.activeTargetLanguage == .chinese

        let templates: [(emoji: String, templates: [String])] = [
            // Food & Drink
            ("🍞🥐🍰🍕🍝", zh ? [
                "🍞 来学习 '\(w)' - \(t)！",
                "🥐 学个新词？试试 '\(w)'！",
                "🍰 发现 '\(w)'"
            ] : [
                "🍞 Hungry? Learn '\(w)' - \(t)!",
                "🥐 Craving vocab? Try '\(w)'!",
                "🍰 Sweet! Discover '\(w)' today"
            ]),
            // Travel & Places
            ("✈️🌍🏖️🗺️🚂", zh ? [
                "✈️ 准备旅行？学 '\(w)'！",
                "🌍 探索 '\(w)' - \(t)",
                "🗺️ 新词：'\(w)'"
            ] : [
                "✈️ Ready to travel? Say '\(w)'!",
                "🌍 Explore '\(w)' - \(t)",
                "🗺️ New destination: '\(w)'"
            ]),
            // Emotions & Feelings
            ("😊❤️😢😡🎉", zh ? [
                "😊 '\(w)' 的意思是 \(t)",
                "❤️ 喜欢这个：'\(w)'！",
                "🎉 学习 '\(w)'"
            ] : [
                "😊 Feel it! '\(w)' means \(t)",
                "❤️ Loving this: '\(w)'!",
                "🎉 Celebrate with '\(w)'"
            ]),
            // Time & Weather
            ("⏰☀️🌧️❄️🌙", zh ? [
                "☀️ 今天学 '\(w)'！",
                "⏰ 是时候学 '\(w)' 了！",
                "🌙 今晚的单词：'\(w)'"
            ] : [
                "☀️ Shine with '\(w)' today!",
                "⏰ Time to learn '\(w)'!",
                "🌙 Nightly word: '\(w)'"
            ]),
            // General Learning
            ("🎯💡✨🚀📚", zh ? [
                "🎯 掌握 '\(w)' - \(t)！",
                "💡 好词：'\(w)'",
                "✨ 学习 '\(w)'！",
                "🚀 开始学 '\(w)'",
                "📚 今日单词：'\(w)'"
            ] : [
                "🎯 Master '\(w)' - \(t)!",
                "💡 Bright idea: '\(w)'",
                "✨ Sparkle with '\(w)'!",
                "🚀 Launch into '\(w)'",
                "📚 Unlock '\(w)' today"
            ])
        ]

        // Pick a random template set
        let templateSet = templates.randomElement() ?? templates[4]
        let fallbackMsg = zh ? "学习 '\(w)' - \(t)" : "Learn '\(w)' - \(t)"
        let message = templateSet.templates.randomElement() ?? fallbackMsg

        // Ensure it's under 45 characters
        if message.count <= 45 {
            return message
        }

        // Fallback to shorter version
        let shortFallbacks: [String] = zh ? [
            "✨ '\(w)' = \(t)！",
            "🎯 今天学 '\(w)'！",
            "💡 '\(w)' 是 \(t)",
            "🚀 说 '\(w)'！",
            "📚 新词：'\(w)'"
        ] : [
            "✨ '\(w)' = \(t)!",
            "🎯 Learn '\(w)' today!",
            "💡 '\(w)' means \(t)",
            "🚀 Say '\(w)'!",
            "📚 New word: '\(w)'"
        ]

        let shortFallback = zh ? "学习 '\(w)'" : "Learn '\(w)'"
        return shortFallbacks.randomElement() ?? shortFallback
    }

    private func removeLegacyNotificationsIfNeeded() async {
        let requests = await center.pendingNotificationRequests()
        let legacyIdentifiers = requests
            .map(\.identifier)
            .filter { identifier in
                identifier != dailyWordIdentifier && !identifier.hasPrefix("test_notification_")
            }

        if !legacyIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: legacyIdentifiers)
            #if DEBUG
            print("🧹 Removed legacy notifications: \(legacyIdentifiers)")
            #endif
        }
    }

    func hasCurrentDailyWordNotification() async -> Bool {
        let requests = await center.pendingNotificationRequests()
        return requests.contains { $0.identifier == dailyWordIdentifier }
    }

    func consumePendingNotificationWordID() -> String? {
        let wordID = pendingNotificationWordID
        pendingNotificationWordID = nil
        return wordID
    }

    // MARK: - Settings & Control

    func updateNotificationTime(_ time: DateComponents) {
        dailyNotificationTime = time
        saveSettings()
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        #if DEBUG
        print("✅ All notifications cancelled")
        #endif
    }
    
    // MARK: - Testing & Debugging
    
    func sendTestNotification() async {
        let status = await checkPermissionStatus()
        guard status == .authorized || status == .provisional else {
            #if DEBUG
            print("❌ Notifications not authorized for test")
            #endif
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = L10n.Notifications.testNotificationTitle
        content.body = L10n.Notifications.testNotificationBody
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            #if DEBUG
            print("✅ Test notification scheduled")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error scheduling test notification: \(error)")
            #endif
        }
    }
    
    func getPendingNotificationCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
    
    func listPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        #if DEBUG
        print("📱 Pending notifications (\(requests.count)):")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
        #endif
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        guard let wordID = response.notification.request.content.userInfo[notificationWordIDKey] as? String,
              !wordID.isEmpty else { return }

        await MainActor.run {
            pendingNotificationWordID = wordID
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}
