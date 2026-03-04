//
//  aWordaDayApp.swift
//  aWordaDay
//
//  Created by Nicolò Campagnoli on 18.07.25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appStates: [AppState]
    @State private var showOnboarding = false
    @State private var startupConfigured = false
    @State private var notificationManager = NotificationManager.shared

    var currentAppState: AppState {
        AppState.current(in: modelContext, cached: appStates)
    }
    
    var body: some View {
        AppTabView()
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                    currentAppState.markOnboardingComplete()
                    try? modelContext.save()
                }
            }
            .onAppear(perform: configureStartupIfNeeded)
    }

    private func configureStartupIfNeeded() {
        guard !startupConfigured else { return }
        startupConfigured = true

        let appState = currentAppState

        // Restore the user's target language preference
        AppLanguage.activeTargetLanguage = appState.targetLanguage

        #if DEBUG
        print("[Startup] onboardingComplete=\(appState.hasCompletedOnboarding), targetLanguage=\(AppLanguage.activeTargetLanguage.displayName)")
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !appState.hasCompletedOnboarding {
                #if DEBUG
                print("[Startup] -> Onboarding")
                #endif
                showOnboarding = true
            } else {
                #if DEBUG
                print("[Startup] -> Main")
                #endif
            }
        }

        Task {
            // Check if notifications are already authorized
            let status = await notificationManager.checkPermissionStatus()

            if status == .notDetermined {
                let granted = await notificationManager.requestPermission()
                if granted {
                    await notificationManager.scheduleDailyWordNotification(with: modelContext)
                }
            } else if status == .authorized || status == .provisional {
                let hasCurrentDaily = await notificationManager.hasCurrentDailyWordNotification()
                if !hasCurrentDaily {
                    await notificationManager.scheduleDailyWordNotification(with: modelContext)
                }
            }
        }
    }

}

// Global flag for database state
private var isUsingInMemoryStorageGlobal = false

@main
struct aWordaDayApp: App {
    @State private var showDatabaseErrorAlert = false
    @State private var databaseErrorMessage = ""

    private var isUsingInMemoryStorage: Bool {
        isUsingInMemoryStorageGlobal
    }

    init() {
        Self.migrateIfNeeded()
        _ = SQLiteCatalogStore.shared
        _ = NotificationManager.shared
        FirebaseAnalyticsManager.shared.configureIfAvailable()
        FirebaseAnalyticsManager.shared.logAppOpened()
    }

    private static func migrateIfNeeded() {
        let currentSchemaVersion = 4
        let key = "wordSchemaVersion"
        let stored = UserDefaults.standard.integer(forKey: key)
        if stored < currentSchemaVersion {
            let storeURL = URL.documentsDirectory.appending(path: "aWordaDay.store")
            let recoveryURL = URL.documentsDirectory.appending(path: "aWordaDay.recovery.store")
            for url in [storeURL, recoveryURL] {
                for ext in ["", ".wal", ".shm"] {
                    let fileURL = ext.isEmpty ? url : URL(fileURLWithPath: url.path() + ext)
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
        if stored < currentSchemaVersion {
            UserDefaults.standard.set(currentSchemaVersion, forKey: key)
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppState.self,
            UserWordState.self,
        ])

        // Use a unique URL for the database to avoid conflicts
        let modelConfiguration = ModelConfiguration(
            url: URL.documentsDirectory.appending(path: "aWordaDay.store"),
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let recoveryConfiguration = ModelConfiguration(
            url: URL.documentsDirectory.appending(path: "aWordaDay.recovery.store"),
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            #if DEBUG
            print("⚠️ ModelContainer creation failed: \(error)")
            #endif

            do {
                #if DEBUG
                print("🛟 Opening recovery store while preserving the original database file")
                #endif
                return try ModelContainer(for: schema, configurations: [recoveryConfiguration])
            } catch {
                #if DEBUG
                print("❌ Failed to create recovery storage, falling back to in-memory: \(error)")
                #endif

                isUsingInMemoryStorageGlobal = true

                let inMemoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainAppView()
                    .onAppear {
                        if isUsingInMemoryStorage && !showDatabaseErrorAlert {
                            databaseErrorMessage = "Unable to save your progress permanently. Your data will be lost when you close the app. Please restart the app or contact support."
                            showDatabaseErrorAlert = true
                        }
                    }

                // Database error overlay
                if isUsingInMemoryStorage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text("Temporary Storage Mode")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignTokens.color.warning)
                                .shadow(radius: 4)
                        )
                        .padding(.bottom, 20)
                    }
                }
            }
            .alert("Database Error", isPresented: $showDatabaseErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(databaseErrorMessage + " Please restart the app manually.")
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
