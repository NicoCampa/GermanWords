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
private let scheduledWordIDsKey = "daily_notification_word_ids"

@MainActor
@Observable
class NotificationManager: NSObject, NotificationManagerProtocol {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let catalogStore: CatalogStoreProtocol = SQLiteCatalogStore.shared
    private let selector = NotificationWordSelector()
    
    // Notification identifiers
    private let legacyDailyWordIdentifier = "daily_word_notification"
    private let dailyWordIdentifierPrefix = "daily_word_notification_"
    // Settings keys
    private let dailyNotificationTimeKey = "daily_notification_time"
    private let scheduleHorizonDays = 30

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

        let now = Date()
        let scheduledDates = upcomingNotificationDates(count: scheduleHorizonDays, from: now)
        let validDateKeys = Set(scheduledDates.map(dateKey(for:)))

        var scheduledWordIDs = loadScheduledWordSchedule()
            .filter { validDateKeys.contains($0.key) }
        var reservedWordIDs = Set(scheduledWordIDs.values)

        for date in scheduledDates {
            let key = dateKey(for: date)

            if let existingWordID = scheduledWordIDs[key],
               catalogStore.fetchWord(id: existingWordID) != nil {
                continue
            }

            let selectedWord = selector.selectWord(
                modelContext: modelContext,
                language: AppLanguage.sourceCode,
                excluding: reservedWordIDs
            ) ?? selector.selectWord(
                modelContext: modelContext,
                language: AppLanguage.sourceCode
            )

            guard let selectedWord else {
                scheduledWordIDs.removeValue(forKey: key)
                continue
            }

            scheduledWordIDs[key] = selectedWord.id
            reservedWordIDs.insert(selectedWord.id)
        }

        saveScheduledWordSchedule(scheduledWordIDs)
        await removePendingDailyWordNotifications()

        var scheduledRequestCount = 0
        for date in scheduledDates {
            let key = dateKey(for: date)
            let triggerDate = notificationTriggerDate(for: date)

            guard triggerDate > now else { continue }

            let content: UNMutableNotificationContent
            if let wordID = scheduledWordIDs[key],
               let word = catalogStore.fetchWord(id: wordID) {
                content = createDailyWordContent(for: word)
            } else {
                content = createFallbackDailyWordContent()
            }

            let triggerComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: key),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            )

            do {
                try await center.add(request)
                scheduledRequestCount += 1
            } catch {
                #if DEBUG
                print("❌ Error scheduling daily notification for \(key): \(error)")
                #endif
            }
        }

        #if DEBUG
        print("✅ Scheduled \(scheduledRequestCount) daily word notifications")
        #endif
    }

    func scheduledNotificationWordID(for date: Date) -> String? {
        let key = dateKey(for: date)
        guard let wordID = loadScheduledWordSchedule()[key] else { return nil }
        guard catalogStore.fetchWord(id: wordID) != nil else { return nil }
        return wordID
    }

    private var calendar: Calendar {
        var current = Calendar.autoupdatingCurrent
        current.timeZone = .autoupdatingCurrent
        return current
    }

    private func createFallbackDailyWordContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = L10n.Notifications.dailyWordAwaits
        content.body = L10n.Notifications.openAppToDiscover
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DAILY_WORD"
        return content
    }

    private func upcomingNotificationDates(count: Int, from date: Date) -> [Date] {
        guard count > 0 else { return [] }

        let startOfToday = calendar.startOfDay(for: date)
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfToday)
        }
    }

    private func notificationTriggerDate(for day: Date) -> Date {
        let hour = dailyNotificationTime.hour ?? 9
        let minute = dailyNotificationTime.minute ?? 0
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
    }

    private func notificationIdentifier(for dateKey: String) -> String {
        dailyWordIdentifierPrefix + dateKey
    }

    private func dateKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func loadScheduledWordSchedule() -> [String: String] {
        guard let stored = UserDefaults.standard.dictionary(forKey: scheduledWordIDsKey) as? [String: String] else {
            return [:]
        }
        return stored
    }

    private func saveScheduledWordSchedule(_ schedule: [String: String]) {
        UserDefaults.standard.set(schedule, forKey: scheduledWordIDsKey)
    }

    private func clearScheduledWordSchedule() {
        UserDefaults.standard.removeObject(forKey: scheduledWordIDsKey)
    }

    private func removePendingDailyWordNotifications() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { isDailyWordNotificationIdentifier($0) }

        guard !identifiers.isEmpty else { return }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        #if DEBUG
        print("🗑️ Cleared daily word notifications: \(identifiers)")
        #endif
    }

    private func isDailyWordNotificationIdentifier(_ identifier: String) -> Bool {
        identifier == legacyDailyWordIdentifier || identifier.hasPrefix(dailyWordIdentifierPrefix)
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
        let templates: [(emoji: String, templates: [String])] = [
            ("🍞🥐🍰🍕🍝", [
                "🍞 Hungry? Learn '\(w)' - \(t)!",
                "🥐 Craving vocab? Try '\(w)'!",
                "🍰 Sweet! Discover '\(w)' today"
            ]),
            ("✈️🌍🏖️🗺️🚂", [
                "✈️ Ready to travel? Say '\(w)'!",
                "🌍 Explore '\(w)' - \(t)",
                "🗺️ New destination: '\(w)'"
            ]),
            ("😊❤️😢😡🎉", [
                "😊 Feel it! '\(w)' means \(t)",
                "❤️ Loving this: '\(w)'!",
                "🎉 Celebrate with '\(w)'"
            ]),
            ("⏰☀️🌧️❄️🌙", [
                "☀️ Shine with '\(w)' today!",
                "⏰ Time to learn '\(w)'!",
                "🌙 Nightly word: '\(w)'"
            ]),
            ("🎯💡✨🚀📚", [
                "🎯 Master '\(w)' - \(t)!",
                "💡 Bright idea: '\(w)'",
                "✨ Sparkle with '\(w)'!",
                "🚀 Launch into '\(w)'",
                "📚 Unlock '\(w)' today"
            ])
        ]

        // Pick a random template set
        let templateSet = templates.randomElement() ?? templates[4]
        let fallbackMsg = "Learn '\(w)' - \(t)"
        let message = templateSet.templates.randomElement() ?? fallbackMsg

        // Ensure it's under 45 characters
        if message.count <= 45 {
            return message
        }

        // Fallback to shorter version
        let shortFallbacks: [String] = [
            "✨ '\(w)' = \(t)!",
            "🎯 Learn '\(w)' today!",
            "💡 '\(w)' means \(t)",
            "🚀 Say '\(w)'!",
            "📚 New word: '\(w)'"
        ]

        let shortFallback = "Learn '\(w)'"
        return shortFallbacks.randomElement() ?? shortFallback
    }

    func hasCurrentDailyWordNotification() async -> Bool {
        let requests = await center.pendingNotificationRequests()
        return requests.contains { isDailyWordNotificationIdentifier($0.identifier) }
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
        clearScheduledWordSchedule()
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
