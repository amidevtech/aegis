//
//  aegisApp.swift
//  aegis
//
//  Created by Bartosz Pater on 03/08/2026.
//

import SwiftData
import SwiftUI
import UserNotifications

/// Przełączniki magazynu danych.
///
/// `isCloudKitEnabled = false` pozwala instalować aplikację lokalnie bez płatnego
/// konta deweloperskiego Apple. Kod CloudKit zostaje - po testach ustaw `true`
/// i przywróć entitlementy z `aegis.CloudKit.entitlements`.
enum StorageOptions {
    static let isCloudKitEnabled = false
}

@main
struct aegisApp: App {
    @State private var appState = AppState()

    private let modelContainer: ModelContainer

    init() {
        modelContainer = Self.makeModelContainer()
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .tint(Theme.Palette.brand)
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

    /// Przy włączonym CloudKit najpierw próbuje magazynu iCloud, a przy niepowodzeniu
    /// schodzi do bazy lokalnej. Przy wyłączonym CloudKit od razu idzie lokalnie.
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Medicine.self])

        var candidates: [ModelConfiguration] = []
        if StorageOptions.isCloudKitEnabled {
            candidates.append(ModelConfiguration(schema: schema, cloudKitDatabase: .automatic))
        }
        candidates.append(ModelConfiguration(schema: schema, cloudKitDatabase: .none))
        candidates.append(
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))

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
