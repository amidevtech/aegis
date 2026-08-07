//
//  CloudSyncService.swift
//  aegis
//

import CloudKit
import Foundation
import Observation

/// Mirror LocalStore ↔ CloudKit (private zone + shared DB after accepting a CKShare).
@MainActor
@Observable
final class CloudSyncService {
    private(set) var isRunning = false
    private(set) var lastErrorMessage: String?
    private(set) var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var share: CKShare?

    static let containerIdentifier = "iCloud.com.amidev.aegis"

    private let containerIdentifier: String
    private var container: CKContainer { CKContainer(identifier: containerIdentifier) }
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }
    private var sharedDatabase: CKDatabase { container.sharedCloudDatabase }
    private weak var localStore: LocalStore?

    /// Medicines that live in a shared zone (participant write-back target).
    private var sharedRecordIDs: [UUID: CKRecord.ID] = [:]

    private let outbox: CloudSyncOutbox
    private var syncChain: Task<Void, Never>?

    /// Test seams for flush I/O; nil uses real CloudKit helpers.
    private let cloudDeleteOverride: ((UUID) async throws -> Void)?
    private let cloudUpsertOverride: ((MedicineCloudSnapshot) async throws -> Void)?

    private var changeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.tokenKey) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKServerChangeToken.self, from: data)
        }
        set {
            if let newValue,
               let data = try? NSKeyedArchiver.archivedData(
                withRootObject: newValue, requiringSecureCoding: true)
            {
                UserDefaults.standard.set(data, forKey: Self.tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.tokenKey)
            }
        }
    }

    private static let tokenKey = "cloudSync.cabinetZoneChangeToken"

    init(
        containerIdentifier: String = CloudSyncService.containerIdentifier,
        outbox: CloudSyncOutbox = CloudSyncOutbox(),
        cloudDelete: ((UUID) async throws -> Void)? = nil,
        cloudUpsert: ((MedicineCloudSnapshot) async throws -> Void)? = nil
    ) {
        self.containerIdentifier = containerIdentifier
        self.outbox = outbox
        self.cloudDeleteOverride = cloudDelete
        self.cloudUpsertOverride = cloudUpsert
    }

    var accountAvailable: Bool {
        iCloudAccountStatus == .available
    }

    /// Pending cloud deletes (tombstones), used to block resurrection on pull.
    var pendingDeleteUUIDs: Set<UUID> { outbox.pendingDeleteUUIDs }

    func clearError() {
        lastErrorMessage = nil
    }

    func refreshAccountStatus() async {
        do {
            iCloudAccountStatus = try await CloudKitOperations.accountStatus(for: container)
        } catch {
            iCloudAccountStatus = .couldNotDetermine
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Serial queue

    @discardableResult
    private func enqueue(_ work: @escaping () async -> Void) -> Task<Void, Never> {
        let previous = syncChain
        let task = Task { @MainActor in
            _ = await previous?.value
            await work()
        }
        syncChain = task
        return task
    }

    // MARK: - Public API

    func start(using localStore: LocalStore) async {
        await enqueue { [weak self] in
            await self?.performStart(using: localStore)
        }.value
    }

    func stop() async {
        await enqueue { [weak self] in
            self?.performStop()
        }.value
    }

    /// Enqueues an upsert and flushes when sync is running.
    func enqueueUpsert(_ snapshot: MedicineCloudSnapshot) {
        outbox.enqueueUpsert(snapshot)
        // Defer the `isRunning` read / flush schedule so Observation tracking
        // does not re-enter SwiftData mid-mutation (can reset the model context).
        Task { @MainActor in
            guard self.isRunning else { return }
            self.enqueue { [weak self] in
                await self?.flushOutbox()
            }
        }
    }

    /// Enqueues a delete tombstone always; flushes when sync is running.
    func enqueueDelete(uuid: UUID) {
        outbox.enqueueDelete(uuid)
        Task { @MainActor in
            guard self.isRunning else { return }
            self.enqueue { [weak self] in
                await self?.flushOutbox()
            }
        }
    }

    func pullNow() async {
        await enqueue { [weak self] in
            await self?.performPullNow()
        }.value
    }

    // MARK: - Sharing

    func prepareShare() async throws -> CKShare {
        let previous = syncChain
        let task = Task { @MainActor in
            _ = await previous?.value
            return try await self.performPrepareShare()
        }
        syncChain = Task { @MainActor in
            _ = try? await task.value
        }
        return try await task.value
    }

    func acceptShare(metadata: CKShare.Metadata) async throws {
        let previous = syncChain
        let task = Task { @MainActor in
            _ = await previous?.value
            try await self.performAcceptShare(metadata: metadata)
        }
        syncChain = Task { @MainActor in
            _ = try? await task.value
        }
        try await task.value
    }

    // MARK: - Performers (always run on the serial chain)

    private func performStart(using localStore: LocalStore) async {
        self.localStore = localStore
        await refreshAccountStatus()
        guard accountAvailable else {
            lastErrorMessage = String(localized: "settings.icloud.unavailable")
            isRunning = false
            return
        }

        do {
            try await ensureZoneAndCabinet()
            // Pull before push so newer cloud data is applied (and LWW upload
            // skips stale local copies) before any outbox flush / bootstrap push.
            try await pullSharedMedicines()
            try await pullChanges()
            let flushSucceeded = await flushOutbox()
            try await pushAllLocalMedicines()
            try await pullSharedMedicines()
            share = try await fetchExistingShare()
            isRunning = true
            lastErrorMessage = CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
                flushSucceeded: flushSucceeded,
                flushErrorMessage: lastErrorMessage)
        } catch {
            lastErrorMessage = error.localizedDescription
            isRunning = false
        }
    }

    private func performStop() {
        isRunning = false
        share = nil
        sharedRecordIDs = [:]
        localStore = nil
    }

    private func performPullNow() async {
        guard isRunning else { return }
        do {
            try await pullChanges()
            try await pullSharedMedicines()
            let flushSucceeded = await flushOutbox()
            lastErrorMessage = CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
                flushSucceeded: flushSucceeded,
                flushErrorMessage: lastErrorMessage)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func performPrepareShare() async throws -> CKShare {
        try await ensureZoneAndCabinet()
        if let existing = try await fetchExistingShare() {
            share = existing
            return existing
        }

        let cabinetID = MedicineRecordCoder.cabinetRecordID()
        let cabinet = try await CloudKitOperations.fetchRecord(id: cabinetID, from: privateDatabase)
        let newShare = CKShare(rootRecord: cabinet)
        newShare[CKShare.SystemFieldKey.title] = String(localized: "settings.share.title")
        newShare.publicPermission = .none

        try await CloudKitOperations.modifyRecords(
            saving: [cabinet, newShare],
            in: privateDatabase)

        share = newShare
        return newShare
    }

    private func performAcceptShare(metadata: CKShare.Metadata) async throws {
        guard localStore != nil else {
            throw CloudSyncError.storeUnavailable
        }
        guard isRunning else {
            throw CloudSyncError.syncNotRunning
        }
        do {
            try await CloudKitOperations.accept(metadata, on: container)
            try await pullSharedMedicines()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Outbox

    /// Flushes pending outbox ops. Returns `true` when every op succeeded (or none pending).
    @discardableResult
    func flushOutbox() async -> Bool {
        let ops = outbox.operations
        guard !ops.isEmpty else { return true }

        var firstError: Error?

        for op in ops {
            guard case .delete(let uuid) = op else { continue }
            do {
                try await performCloudDelete(uuid: uuid)
                outbox.remove(op)
            } catch {
                firstError = firstError ?? error
            }
        }

        for op in ops {
            guard case .upsert(let snapshot) = op else { continue }
            do {
                try await performCloudUpsert(snapshot)
                outbox.remove(op)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            lastErrorMessage = firstError.localizedDescription
            return false
        }
        return true
    }

    private func performCloudUpsert(_ snapshot: MedicineCloudSnapshot) async throws {
        if let cloudUpsertOverride {
            try await cloudUpsertOverride(snapshot)
            return
        }
        try await upsertMedicineToCloud(snapshot)
    }

    private func performCloudDelete(uuid: UUID) async throws {
        if let cloudDeleteOverride {
            try await cloudDeleteOverride(uuid)
            sharedRecordIDs[uuid] = nil
            return
        }
        try await deleteMedicineFromCloud(uuid: uuid)
    }

    private func upsertMedicineToCloud(_ snapshot: MedicineCloudSnapshot) async throws {
        let target = databaseAndZone(for: snapshot.uuid)
        try await CloudKitOperations.upsertMedicineRecords(
            [snapshot],
            zoneID: target.zoneID,
            database: target.database)
    }

    private func deleteMedicineFromCloud(uuid: UUID) async throws {
        let target = databaseAndZone(for: uuid)
        let recordID = sharedRecordIDs[uuid]
            ?? MedicineRecordCoder.recordID(for: uuid, zoneID: target.zoneID)
        try await CloudKitOperations.deleteRecord(id: recordID, from: target.database)
        sharedRecordIDs[uuid] = nil
    }

    // MARK: - Routing

    private struct DatabaseTarget {
        let database: CKDatabase
        let zoneID: CKRecordZone.ID
    }

    private func databaseAndZone(for uuid: UUID) -> DatabaseTarget {
        if let sharedID = sharedRecordIDs[uuid] {
            return DatabaseTarget(database: sharedDatabase, zoneID: sharedID.zoneID)
        }
        return DatabaseTarget(database: privateDatabase, zoneID: MedicineRecordCoder.zoneID)
    }

    // MARK: - Private helpers

    private func ensureZoneAndCabinet() async throws {
        let zone = CKRecordZone(zoneID: MedicineRecordCoder.zoneID)
        try await CloudKitOperations.saveZone(zone, to: privateDatabase)

        let cabinetID = MedicineRecordCoder.cabinetRecordID()
        do {
            _ = try await CloudKitOperations.fetchRecord(id: cabinetID, from: privateDatabase)
        } catch {
            let cabinet = MedicineRecordCoder.makeCabinetRecord()
            _ = try await CloudKitOperations.saveRecord(cabinet, to: privateDatabase)
        }
    }

    /// Bootstrap / catch-up push. Upload LWW inside `upsertMedicineRecords` skips
    /// records where cloud is already newer. Skips pending delete tombstones.
    private func pushAllLocalMedicines() async throws {
        guard let localStore else { return }
        let medicines = try localStore.fetchAll()
        let tombstones = outbox.pendingDeleteUUIDs
        guard !medicines.isEmpty else { return }

        var privateSnapshots: [MedicineCloudSnapshot] = []
        var sharedByZone: [CKRecordZone.ID: [MedicineCloudSnapshot]] = [:]

        for medicine in medicines {
            if tombstones.contains(medicine.uuid) { continue }
            let snapshot = MedicineCloudSnapshot(from: medicine)
            if let sharedID = sharedRecordIDs[medicine.uuid] {
                sharedByZone[sharedID.zoneID, default: []].append(snapshot)
            } else {
                privateSnapshots.append(snapshot)
            }
        }

        try await CloudKitOperations.upsertMedicineRecords(
            privateSnapshots,
            zoneID: MedicineRecordCoder.zoneID,
            database: privateDatabase)

        for (zoneID, snapshots) in sharedByZone {
            try await CloudKitOperations.upsertMedicineRecords(
                snapshots,
                zoneID: zoneID,
                database: sharedDatabase)
        }
    }

    private func pullChanges() async throws {
        guard let localStore else { return }

        do {
            try await fetchAndApplyPrivateChanges(previousToken: changeToken)
        } catch let error as CKError where error.code == .changeTokenExpired {
            changeToken = nil
            try await fetchAndApplyPrivateChanges(previousToken: nil)
        }
    }

    private func fetchAndApplyPrivateChanges(previousToken: CKServerChangeToken?) async throws {
        guard let localStore else { return }

        let zoneID = MedicineRecordCoder.zoneID
        var pendingToken = previousToken
        var moreComing = true
        let tombstones = outbox.pendingDeleteUUIDs

        while moreComing {
            let changes = try await CloudKitOperations.fetchZoneChanges(
                zoneID: zoneID,
                previousToken: pendingToken,
                database: privateDatabase)
            for record in changes.modifications {
                if let snapshot = MedicineRecordCoder.snapshot(from: record) {
                    if tombstones.contains(snapshot.uuid) { continue }
                    try localStore.upsertFromCloud(snapshot)
                }
            }
            for recordID in changes.deletions {
                if let uuid = UUID(uuidString: recordID.recordName) {
                    sharedRecordIDs[uuid] = nil
                    try localStore.deleteByUUID(uuid)
                    NotificationService.shared.cancel(uuid: uuid)
                }
            }
            pendingToken = changes.token
            moreComing = changes.moreComing
        }

        changeToken = pendingToken
    }

    private func pullSharedMedicines() async throws {
        guard let localStore else { return }

        let previousShared = Set(sharedRecordIDs.keys)
        let zones = try await CloudKitOperations.allRecordZones(in: sharedDatabase)
        var seenSharedUUIDs: Set<UUID> = []
        let tombstones = outbox.pendingDeleteUUIDs

        for zone in zones {
            let records = try await CloudKitOperations.queryMedicines(
                inZone: zone.zoneID,
                database: sharedDatabase)
            for record in records {
                guard let snapshot = MedicineRecordCoder.snapshot(from: record) else { continue }
                // Always keep routing + seen membership for tombstones so flush
                // deletes the shared record (not the private zone fallback).
                sharedRecordIDs[snapshot.uuid] = record.recordID
                seenSharedUUIDs.insert(snapshot.uuid)
                let isTombstoned = tombstones.contains(snapshot.uuid)
                guard MedicineRecordCoder.shouldUpsertSharedPull(isTombstoned: isTombstoned)
                else { continue }
                try localStore.upsertFromCloud(snapshot)
            }
        }

        // Successful pull completed — mirror departures by deleting local copies.
        let departed = MedicineRecordCoder.departedSharedUUIDs(
            previous: previousShared,
            seen: seenSharedUUIDs)
        for uuid in departed {
            sharedRecordIDs[uuid] = nil
            try localStore.deleteByUUID(uuid)
            NotificationService.shared.cancel(uuid: uuid)
        }
    }

    private func fetchExistingShare() async throws -> CKShare? {
        let cabinetID = MedicineRecordCoder.cabinetRecordID()
        let cabinet = try await CloudKitOperations.fetchRecord(id: cabinetID, from: privateDatabase)
        guard let shareReference = cabinet.share else { return nil }
        return try await CloudKitOperations.fetchRecord(
            id: shareReference.recordID, from: privateDatabase) as? CKShare
    }
}

enum CloudSyncError: LocalizedError {
    case storeUnavailable
    case syncNotRunning

    var errorDescription: String? {
        switch self {
        case .storeUnavailable:
            String(localized: "settings.sync.store_unavailable")
        case .syncNotRunning:
            String(localized: "settings.sync.not_running")
        }
    }
}

/// Error-clearing rules after a successful pull/start chain that includes flush.
enum CloudSyncErrorPolicy {
    /// Clears the surfaced error only when flush fully succeeded; otherwise keep
    /// the flush failure message so Sync Now / start do not look healthy.
    static func errorMessageAfterSuccessfulSteps(
        flushSucceeded: Bool,
        flushErrorMessage: String?
    ) -> String? {
        flushSucceeded ? nil : flushErrorMessage
    }
}
