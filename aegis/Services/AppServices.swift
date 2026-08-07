//
//  AppServices.swift
//  aegis
//

import Foundation
import SwiftData

/// Dependency container created once at app launch.
@MainActor
final class AppServices {
    let subscriptionStore: SubscriptionStore
    let localStore: LocalStore
    let cloudSync: CloudSyncService
    let repository: MedicineRepository

    init(modelContainer: ModelContainer, outbox: CloudSyncOutbox = CloudSyncOutbox()) {
        let subscriptionStore = SubscriptionStore()
        let localStore = LocalStore(container: modelContainer)
        let cloudSync = CloudSyncService(outbox: outbox)
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
