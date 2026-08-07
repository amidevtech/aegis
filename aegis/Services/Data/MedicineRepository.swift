//
//  MedicineRepository.swift
//  aegis
//

import Foundation
import Observation

enum MedicineRepositoryError: Error, Equatable {
    case requiresPro
}

/// Single mutation entry point from UI: LocalStore always, CloudSync when Pro.
@MainActor
@Observable
final class MedicineRepository {
    private let localStore: LocalStore
    private let cloudSync: CloudSyncService
    private let subscriptionStore: SubscriptionStore

    /// Last local persistence failure for UI surfacing.
    private(set) var lastErrorMessage: String?

    var isPro: Bool { subscriptionStore.isPro }

    init(
        localStore: LocalStore,
        cloudSync: CloudSyncService,
        subscriptionStore: SubscriptionStore
    ) {
        self.localStore = localStore
        self.cloudSync = cloudSync
        self.subscriptionStore = subscriptionStore
    }

    func clearError() {
        lastErrorMessage = nil
        localStore.clearError()
    }

    func upsert(_ medicine: Medicine, isNew: Bool) {
        medicine.touchModified()
        if isNew {
            localStore.insert(medicine)
        } else {
            localStore.save()
        }
        capturePersistenceError()
        Task { await NotificationService.shared.reschedule(for: medicine) }
        enqueueCloudUpsert(medicine)
    }

    func setOpened(_ isOpened: Bool, for medicine: Medicine) {
        if isOpened {
            medicine.markOpened()
        } else {
            medicine.markUnopened()
        }
        medicine.touchModified()
        localStore.save()
        capturePersistenceError()
        Task { await NotificationService.shared.reschedule(for: medicine) }
        enqueueCloudUpsert(medicine)
    }

    @discardableResult
    func archive(_ medicine: Medicine, reason: ArchiveReason) -> Result<Void, MedicineRepositoryError> {
        guard isPro else { return .failure(.requiresPro) }
        medicine.archive(reason: reason)
        medicine.touchModified()
        NotificationService.shared.cancel(for: medicine)
        localStore.save()
        capturePersistenceError()
        enqueueCloudUpsert(medicine)
        return .success(())
    }

    @discardableResult
    func archive(_ medicines: [Medicine], reason: ArchiveReason) -> Result<Void, MedicineRepositoryError> {
        guard isPro else { return .failure(.requiresPro) }
        for medicine in medicines {
            medicine.archive(reason: reason)
            medicine.touchModified()
            NotificationService.shared.cancel(for: medicine)
        }
        localStore.save()
        capturePersistenceError()
        for medicine in medicines {
            enqueueCloudUpsert(medicine)
        }
        return .success(())
    }

    @discardableResult
    func restore(_ medicine: Medicine) -> Result<Void, MedicineRepositoryError> {
        guard isPro else { return .failure(.requiresPro) }
        medicine.restore()
        medicine.refreshEffectiveExpiry()
        medicine.touchModified()
        localStore.save()
        capturePersistenceError()
        Task { await NotificationService.shared.reschedule(for: medicine) }
        enqueueCloudUpsert(medicine)
        return .success(())
    }

    /// Permanent delete — Free from the active list, or Pro from the archive.
    /// Always tombstones the UUID in the cloud outbox so Free→Pro cannot resurrect.
    func delete(_ medicine: Medicine) {
        let uuid = medicine.uuid
        NotificationService.shared.cancel(for: medicine)
        localStore.delete(medicine)
        capturePersistenceError()
        // Tombstone synchronously so Free→Pro cannot resurrect even if the
        // process dies before a flush Task runs.
        cloudSync.enqueueDelete(uuid: uuid)
    }

    func syncProState() async {
        if isPro {
            await cloudSync.start(using: localStore)
        } else {
            await cloudSync.stop()
        }
    }

    func fetchActiveMedicines() throws -> [Medicine] {
        try localStore.fetchActive()
    }

    private func capturePersistenceError() {
        lastErrorMessage = localStore.lastErrorMessage
    }

    private func enqueueCloudUpsert(_ medicine: Medicine) {
        guard isPro else { return }
        // Snapshot now; hop before touching @Observable CloudSyncService so
        // Observation does not re-enter SwiftData mid-mutation.
        let snapshot = MedicineCloudSnapshot(from: medicine)
        Task { @MainActor in
            cloudSync.enqueueUpsert(snapshot)
        }
    }
}
