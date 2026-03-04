//
//  NotificationSettingsView.swift
//  aWordaDay
//
//  Created by Claude on 09.09.25.
//

import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationManager = NotificationManager.shared
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingTimePicker = false
    @State private var selectedHour = 9
    @State private var selectedMinute = 0
    @State private var showingTestAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        DesignTokens.color.backgroundLight,
                        DesignTokens.color.backgroundLight
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header with icon
                        VStack(spacing: DesignTokens.spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.color.accentBlue.opacity(0.15),
                                                DesignTokens.color.primaryDark.opacity(0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)

                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(DesignTokens.color.accentBlue)
                                    .symbolRenderingMode(.hierarchical)
                            }

                            Text(L10n.Notifications.notifications)
                                .font(DesignTokens.typography.title(weight: .bold))
                                .foregroundStyle(DesignTokens.color.headingPrimary)

                            Text(L10n.Notifications.stayOnTrack)
                                .font(DesignTokens.typography.callout(weight: .medium))
                                .foregroundStyle(DesignTokens.color.textLight)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, DesignTokens.spacing.lg2)

                        // Permission Status
                        NotificationPermissionCard()

                        // Daily Word Notification Card
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(DesignTokens.color.accentBlue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.Notifications.dailyWord)
                                        .font(DesignTokens.typography.headline(weight: .bold))
                                        .foregroundStyle(DesignTokens.color.textDark)

                                    Text(L10n.Notifications.dailyWordDesc)
                                        .font(DesignTokens.typography.caption(weight: .medium))
                                        .foregroundStyle(DesignTokens.color.textLight)
                                }
                            }
                            .padding(.horizontal, DesignTokens.spacing.lg2)
                            .padding(.top, DesignTokens.spacing.lg)

                            Text(notificationManager.isNotificationsEnabled ? L10n.Common.enabled : L10n.Common.disabled)
                                .font(DesignTokens.typography.caption(weight: .semibold))
                                .foregroundStyle(notificationManager.isNotificationsEnabled ?
                                    DesignTokens.color.success :
                                    DesignTokens.color.textMuted)
                                .padding(.horizontal, DesignTokens.spacing.lg2)
                                .padding(.bottom, DesignTokens.spacing.lg)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                                .fill(DesignTokens.color.cardBackground)
                                .designSystemShadow(DesignTokens.shadow.medium)
                        )
                        .padding(.horizontal, DesignTokens.spacing.lg2)
                        
                        // Time Settings Card
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(DesignTokens.color.accentBlue)

                                Text(L10n.Notifications.preferredTime)
                                    .font(DesignTokens.typography.headline(weight: .bold))
                                    .foregroundStyle(DesignTokens.color.textDark)
                            }
                            .padding(.horizontal, DesignTokens.spacing.lg2)

                            Button(action: { showingTimePicker = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.Notifications.dailyReminderAt)
                                            .font(DesignTokens.typography.caption(weight: .medium))
                                            .foregroundStyle(DesignTokens.color.textMuted)

                                        Text(formatTime())
                                            .font(DesignTokens.typography.headline(weight: .bold))
                                            .foregroundStyle(DesignTokens.color.accentBlue)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(DesignTokens.color.textMuted)
                                }
                                .padding(.horizontal, DesignTokens.spacing.lg2)
                                .padding(.vertical, DesignTokens.spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg, style: .continuous)
                                        .fill(DesignTokens.color.cardBackground)
                                        .designSystemShadow(DesignTokens.shadow.medium)
                                )
                            }
                            .padding(.horizontal, DesignTokens.spacing.lg2)
                        }
                        
                        // Test Notification
                        Button(action: sendTestNotification) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16, weight: .bold))

                                Text(L10n.Notifications.sendTestNotification)
                                    .font(DesignTokens.typography.callout(weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, DesignTokens.spacing.xl)
                            .padding(.vertical, DesignTokens.spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.color.primary,
                                                DesignTokens.color.primaryDark
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: DesignTokens.color.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                            )
                        }
                        .alert(L10n.Notifications.testSent, isPresented: $showingTestAlert) {
                            Button(L10n.Common.ok) { }
                        } message: {
                            Text(L10n.Notifications.checkNotifications)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, DesignTokens.spacing.lg2)
                }
            }
        }
        .navigationTitle(L10n.Notifications.notifications)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.Common.done) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerView(
                selectedHour: $selectedHour,
                selectedMinute: $selectedMinute,
                onSave: saveNotificationTime
            )
        }
        .onAppear {
            loadCurrentTime()
        }
    }
    
    
    private func scheduleAllNotifications() async {
        await notificationManager.scheduleDailyWordNotification(with: modelContext)
    }
    
    private func loadCurrentTime() {
        selectedHour = notificationManager.dailyNotificationTime.hour ?? 9
        selectedMinute = notificationManager.dailyNotificationTime.minute ?? 0
    }
    
    private func formatTime() -> String {
        let hour = notificationManager.dailyNotificationTime.hour ?? 9
        let minute = notificationManager.dailyNotificationTime.minute ?? 0
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func saveNotificationTime() {
        var newTime = DateComponents()
        newTime.hour = selectedHour
        newTime.minute = selectedMinute
        
        notificationManager.updateNotificationTime(newTime)
        
        // Reschedule daily notification with new time
        Task {
            await notificationManager.scheduleDailyWordNotification(with: modelContext)
        }
    }
    
    private func sendTestNotification() {
        Task {
            await notificationManager.sendTestNotification()
            showingTestAlert = true
        }
    }
}

// MARK: - Permission Card
struct NotificationPermissionCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var notificationManager = NotificationManager.shared
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.lg) {
            HStack {
                Image(systemName: permissionIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(permissionColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Notifications.notificationPermission)
                        .font(DesignTokens.typography.callout(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textPrimary)

                    Text(permissionDescription)
                        .font(DesignTokens.typography.caption(weight: .medium))
                        .foregroundStyle(DesignTokens.color.textMuted)
                }

                Spacer()

                if permissionStatus == .notDetermined || permissionStatus == .denied {
                    Button(L10n.Common.enable) {
                        Task {
                            await requestPermission()
                        }
                    }
                    .font(DesignTokens.typography.caption(weight: .bold))
                    .padding(.horizontal, DesignTokens.spacing.lg)
                    .padding(.vertical, DesignTokens.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                            .fill(DesignTokens.color.primary)
                    )
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, DesignTokens.spacing.lg2)
        .padding(.vertical, DesignTokens.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(DesignTokens.color.cardBackground)
                .shadow(color: permissionColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            Task {
                permissionStatus = await notificationManager.checkPermissionStatus()
            }
        }
    }
    
    private var permissionIcon: String {
        switch permissionStatus {
        case .authorized, .provisional:
            return "checkmark.circle.fill"
        case .ephemeral:
            return "checkmark.shield.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "bell.slash.fill"
        }
    }
    
    private var permissionColor: Color {
        switch permissionStatus {
        case .authorized, .provisional:
            return DesignTokens.color.success
        case .ephemeral:
            return DesignTokens.color.accentBlue
        case .denied:
            return DesignTokens.color.error
        case .notDetermined:
            return DesignTokens.color.warning
        @unknown default:
            return DesignTokens.color.textMuted
        }
    }
    
    private var permissionDescription: String {
        switch permissionStatus {
        case .authorized:
            return L10n.Notifications.permEnabled
        case .provisional:
            return L10n.Notifications.permQuiet
        case .ephemeral:
            return L10n.Notifications.permTemporary
        case .denied:
            return L10n.Notifications.permDenied
        case .notDetermined:
            return L10n.Notifications.permNotDetermined
        @unknown default:
            return L10n.Notifications.permUnknown
        }
    }
    
    private func requestPermission() async {
        let granted = await notificationManager.requestPermission()
        if granted {
            await notificationManager.scheduleDailyWordNotification(with: modelContext)
        }
        permissionStatus = await notificationManager.checkPermissionStatus()
    }
}

// MARK: - Time Picker
struct TimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.spacing.xxl) {
                Text(L10n.Notifications.chooseNotificationTime)
                    .font(DesignTokens.typography.title(weight: .bold))
                    .foregroundStyle(DesignTokens.color.textPrimary)
                    .padding(.top, 40)
                
                HStack(spacing: DesignTokens.spacing.lg2) {
                    // Hour picker
                    VStack {
                        Text(L10n.Notifications.hour)
                            .font(DesignTokens.typography.callout(weight: .medium))
                            .foregroundStyle(DesignTokens.color.textMuted)
                        
                        Picker("Hour", selection: $selectedHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                        .clipped()
                    }
                    
                    Text(":")
                        .font(DesignTokens.typography.title(weight: .bold))
                        .foregroundStyle(DesignTokens.color.textPrimary)
                    
                    // Minute picker
                    VStack {
                        Text(L10n.Notifications.minute)
                            .font(DesignTokens.typography.callout(weight: .medium))
                            .foregroundStyle(DesignTokens.color.textMuted)
                        
                        Picker("Minute", selection: $selectedMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                        .clipped()
                    }
                }
                
                Spacer()
            }
            .navigationTitle(L10n.Notifications.setTime)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.save) {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
        .modelContainer(for: [AppState.self, UserWordState.self], inMemory: true)
}
