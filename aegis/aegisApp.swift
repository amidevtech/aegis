//
//  aegisApp.swift
//  aegis
//
//  Created by Bartosz Pater on 03/08/2026.
//

import SwiftData
import SwiftUI
import UserNotifications

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

    /// Najpierw próbujemy magazynu synchronizowanego przez iCloud. Bez konta
    /// developerskiego albo bez zalogowanego iCloud taka konfiguracja się nie uda,
    /// więc schodzimy do bazy lokalnej - aplikacja ma działać w obu przypadkach.
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([Medicine.self])

        let candidates: [ModelConfiguration] = [
            ModelConfiguration(schema: schema, cloudKitDatabase: .automatic),
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
