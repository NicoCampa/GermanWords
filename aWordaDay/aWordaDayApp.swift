//
//  aWordaDayApp.swift
//  aWordaDay
//
//  Created by Nicolò Campagnoli on 18.07.25.
//

import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

struct LaunchScreenView: View {
    @State private var cloudScale: CGFloat = 1.0
    @State private var titleOpacity: Double = 1
    @State private var taglineOpacity: Double = 1

    var body: some View {
        ZStack {
            // Background gradient with subtle blobs
            LinearGradient(
                colors: [
                    DesignTokens.color.backgroundGradientTop,
                    DesignTokens.color.backgroundGradientBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft decorative blobs
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .offset(x: -130, y: -240)
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 140, height: 140)
                    .blur(radius: 18)
                    .offset(x: 140, y: 230)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // Main content centered
                VStack(spacing: 24) {
                    // Mascot - Much bigger and prominent
                    SharedCloudMascot(scale: cloudScale)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: cloudScale)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                    // Title + Tagline
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Worty")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
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
                                .opacity(titleOpacity)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Text("Learn a word, every day")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(DesignTokens.color.textPrimary)
                                .opacity(titleOpacity)
                        }

                        Text("Smart, simple, and encouraging")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(DesignTokens.color.textLight)
                            .opacity(taglineOpacity)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Worty. Learn a word every day. Smart, simple, and encouraging.")
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                cloudScale = 1.4
            }
        }
    }
}

// Subtle three-dot loading indicator
struct PulsingDots: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(DesignTokens.color.primary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .shadow(color: DesignTokens.color.primary.opacity(0.2), radius: 2, x: 0, y: 1)
                    .scaleEffect(1 + 0.25 * CGFloat(sin(phase + Double(i) * .pi / 2)))
                    .opacity(0.7 + 0.3 * Double((sin(phase + Double(i) * .pi / 2) + 1) / 2))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
        .accessibilityHidden(true)
    }
}

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProgress: [UserProgress]
    @State private var showOnboarding = false
    @State private var startupConfigured = false
    @State private var notificationManager = NotificationManager.shared

    var currentProgress: UserProgress {
        UserProgress.current(in: modelContext, cached: userProgress)
    }
    
    var body: some View {
        AppTabView()
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                }
            }
            .onAppear(perform: configureStartupIfNeeded)
    }

    private func configureStartupIfNeeded() {
        guard !startupConfigured else { return }
        startupConfigured = true

        let progress = currentProgress

        // Restore the user's target language preference
        AppLanguage.activeTargetLanguage = progress.targetLanguage

        #if DEBUG
        print("[Startup] isFirstLaunch=\(progress.isFirstLaunch), targetLanguage=\(AppLanguage.activeTargetLanguage.displayName)")
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if progress.isFirstLaunch {
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
                // Only request permission if not yet determined
                let granted = await notificationManager.requestPermission()
                if granted {
                    await notificationManager.scheduleDailyWordNotification(with: modelContext)
                }
            } else if status == .authorized || status == .provisional {
                // Already authorized, ensure the new smart notification is scheduled
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
        FirebaseAnalyticsManager.shared.configureIfAvailable()
        FirebaseAnalyticsManager.shared.logAppOpened()
    }

    private static func migrateIfNeeded() {
        let currentSchemaVersion = 3
        let key = "wordSchemaVersion"
        let stored = UserDefaults.standard.integer(forKey: key)
        if stored < 2 {
            // v1→v2: destructive migration (wipe DB)
            let storeURL = URL.documentsDirectory.appending(path: "aWordaDay.store")
            let recoveryURL = URL.documentsDirectory.appending(path: "aWordaDay.recovery.store")
            for url in [storeURL, recoveryURL] {
                for ext in ["", ".wal", ".shm"] {
                    let fileURL = ext.isEmpty ? url : URL(fileURLWithPath: url.path() + ext)
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        }
        // v2→v3: additive only (new optional fields on Word + UserProgress) — no DB wipe needed
        if stored < currentSchemaVersion {
            UserDefaults.standard.set(currentSchemaVersion, forKey: key)
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Word.self,
            UserProgress.self,
            ChatHistoryMessage.self,
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
                        // Check if we fell back to in-memory storage
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
