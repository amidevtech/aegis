//
//  aegisApp.swift
//  aegis
//

import CloudKit
import SwiftData
import SwiftUI
import UserNotifications

@main
struct aegisApp: App {
    #if canImport(UIKit) && !os(watchOS)
    @UIApplicationDelegateAdaptor(AegisAppDelegate.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AegisAppDelegate.self) private var appDelegate
    #endif

    @State private var appState = AppState()

    private let modelContainer: ModelContainer
    private let services: AppServices

    init() {
        let container = Self.makeModelContainer()
        modelContainer = container
        services = AppServices(modelContainer: container)
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(services.subscriptionStore)
                .environment(services.repository)
                .environment(services.cloudSync)
                .tint(Theme.Palette.brand)
                .task {
                    installShareAcceptanceHandler()
                    services.subscriptionStore.startListeningForTransactions()
                    await services.subscriptionStore.loadProducts()
                    await services.subscriptionStore.refreshEntitlements()
                    await services.repository.syncProState()
                }
                .onChange(of: services.subscriptionStore.isPro) { _, _ in
                    Task { await services.repository.syncProState() }
                }
        }
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.Menu.newMedicine) {
                    appState.isPresentingNewMedicine = true
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(L10n.Menu.search) {
                    appState.focusSearch()
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
        #if os(macOS)
        .defaultSize(width: 1080, height: 760)
        .windowResizability(.contentMinSize)
        #endif
    }

    private func installShareAcceptanceHandler() {
        #if canImport(UIKit) && !os(watchOS)
        AegisSceneDelegate.onAcceptShare = { [services] metadata in
            Task {
                await services.repository.syncProState()
                do {
                    try await services.cloudSync.acceptShare(metadata: metadata)
                } catch {
                    // `acceptShare` already records `lastErrorMessage` for Root/Settings.
                }
            }
        }
        #elseif os(macOS)
        AegisAppDelegate.onAcceptShare = { [services] metadata in
            Task {
                await services.repository.syncProState()
                do {
                    try await services.cloudSync.acceptShare(metadata: metadata)
                } catch {
                    // `acceptShare` already records `lastErrorMessage` for Root/Settings.
                }
            }
        }
        #endif
    }

    /// Free and Pro both use local SwiftData. CloudKit is a custom sync
    /// (`CloudSyncService`) enabled only with a Pro entitlement — we do not use
    /// built-in `cloudKitDatabase: .automatic` (no CKShare support).
    ///
    /// Disk-only: never fall back to an in-memory store (that would silently
    /// discard cabinet data on quit).
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Medicine.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to open the on-disk medicine cabinet store: \(error)")
        }
    }
}

/// Presents notifications even while the app is in the foreground —
/// otherwise an expiry reminder would be silently skipped.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
