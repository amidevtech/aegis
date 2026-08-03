//
//  MedicineRepository.swift
//  aegis
//

import Foundation
import Observation

enum MedicineRepositoryError: Error, Equatable {
    case requiresPro
}

/// Jedyny punkt mutacji leków z UI: LocalStore zawsze, CloudSync gdy Pro.
@MainActor
@Observable
final class MedicineRepository {
    private let localStore: LocalStore
    private let cloudSync: CloudSyncService
    private let subscriptionStore: SubscriptionStore

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

    func upsert(_ medicine: Medicine, isNew: Bool) {
        medicine.touchModified()
        if isNew {
            localStore.insert(medicine)
        } else {
            localStore.save()
        }
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
        Task { await NotificationService.shared.reschedule(for: medicine) }
        enqueueCloudUpsert(medicine)
        return .success(())
    }

    /// Trwałe usunięcie — Free z aktywnej listy albo Pro z archiwum.
    func delete(_ medicine: Medicine) {
        let uuid = medicine.uuid
        NotificationService.shared.cancel(for: medicine)
        localStore.delete(medicine)
        if isPro {
            Task { await cloudSync.deleteMedicine(uuid: uuid) }
        }
    }

    func syncProState() async {
        if isPro {
            await cloudSync.start(using: localStore)
        } else {
            await cloudSync.stop()
        }
    }

    private func enqueueCloudUpsert(_ medicine: Medicine) {
        guard isPro else { return }
        let snapshot = MedicineCloudSnapshot(from: medicine)
        Task { await cloudSync.upsert(snapshot) }
    }
}
