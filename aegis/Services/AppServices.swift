//
//  AppServices.swift
//  aegis
//

import Foundation
import SwiftData

/// Kontener zależności tworzony raz przy starcie aplikacji.
@MainActor
final class AppServices {
    let subscriptionStore: SubscriptionStore
    let localStore: LocalStore
    let cloudSync: CloudSyncService
    let repository: MedicineRepository

    init(modelContainer: ModelContainer) {
        let subscriptionStore = SubscriptionStore()
        let localStore = LocalStore(container: modelContainer)
        let cloudSync = CloudSyncService()
        let repository = MedicineRepository(
            localStore: localStore,
            cloudSync: cloudSync,
            subscriptionStore: subscriptionStore)

        self.subscriptionStore = subscriptionStore
        self.localStore = localStore
        self.cloudSync = cloudSync
        self.repository = repository
    }
}
