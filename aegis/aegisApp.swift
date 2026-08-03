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
                try? await services.cloudSync.acceptShare(metadata: metadata)
                await services.repository.syncProState()
            }
        }
        #elseif os(macOS)
        AegisAppDelegate.onAcceptShare = { [services] metadata in
            Task {
                try? await services.cloudSync.acceptShare(metadata: metadata)
                await services.repository.syncProState()
            }
        }
        #endif
    }

    /// Free i Pro korzystają z lokalnego SwiftData. CloudKit jest własnym syncem
    /// (`CloudSyncService`) włączanym dopiero przy entitlement Pro — nie używamy
    /// wbudowanego `cloudKitDatabase: .automatic` (brak CKShare).
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Medicine.self])
        let candidates: [ModelConfiguration] = [
            ModelConfiguration(schema: schema, cloudKitDatabase: .none),
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ]

        for configuration in candidates {
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return container
            }
        }

        fatalError("Nie udało się utworzyć magazynu danych w żadnej konfiguracji")
    }
}

/// Pokazuje powiadomienie także wtedy, gdy aplikacja jest akurat na wierzchu -
/// bez tego przypomnienie o terminie zostałoby po cichu pominięte.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
