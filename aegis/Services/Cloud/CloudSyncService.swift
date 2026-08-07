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

    init(containerIdentifier: String = CloudSyncService.containerIdentifier) {
        self.containerIdentifier = containerIdentifier
    }

    var accountAvailable: Bool {
        iCloudAccountStatus == .available
    }

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

    func start(using localStore: LocalStore) async {
        self.localStore = localStore
        await refreshAccountStatus()
        guard accountAvailable else {
            lastErrorMessage = String(localized: "settings.icloud.unavailable")
            isRunning = false
            return
        }

        do {
            try await ensureZoneAndCabinet()
            // Populate shared-zone routing before push so participant edits
            // do not land in the private database.
            try await pullSharedMedicines()
            try await pushAllLocalMedicines()
            try await pullChanges()
            try await pullSharedMedicines()
            share = try await fetchExistingShare()
            isRunning = true
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            isRunning = false
        }
    }

    func stop() async {
        isRunning = false
        share = nil
        sharedRecordIDs = [:]
    }

    func upsert(_ snapshot: MedicineCloudSnapshot) async {
        guard isRunning else { return }
        do {
            let target = databaseAndZone(for: snapshot.uuid)
            try await CloudKitOperations.upsertMedicineRecords(
                [snapshot],
                zoneID: target.zoneID,
                database: target.database)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func deleteMedicine(uuid: UUID) async {
        guard isRunning else { return }
        do {
            let target = databaseAndZone(for: uuid)
            let recordID = sharedRecordIDs[uuid]
                ?? MedicineRecordCoder.recordID(for: uuid, zoneID: target.zoneID)
            try await CloudKitOperations.deleteRecord(id: recordID, from: target.database)
            sharedRecordIDs[uuid] = nil
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func pullNow() async {
        guard isRunning else { return }
        do {
            try await pullChanges()
            try await pullSharedMedicines()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Sharing

    func prepareShare() async throws -> CKShare {
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

    func acceptShare(metadata: CKShare.Metadata) async throws {
        do {
            guard localStore != nil else {
                throw CloudSyncError.storeUnavailable
            }
            try await CloudKitOperations.accept(metadata, on: container)
            try await pullSharedMedicines()
            isRunning = true
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            throw error
        }
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

    private func pushAllLocalMedicines() async throws {
        guard let localStore else { return }
        let medicines = try localStore.fetchAll()
        guard !medicines.isEmpty else { return }

        var privateSnapshots: [MedicineCloudSnapshot] = []
        var sharedByZone: [CKRecordZone.ID: [MedicineCloudSnapshot]] = [:]

        for medicine in medicines {
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

        let zoneID = MedicineRecordCoder.zoneID
        var pendingToken = changeToken
        var moreComing = true

        while moreComing {
            let changes = try await CloudKitOperations.fetchZoneChanges(
                zoneID: zoneID,
                previousToken: pendingToken,
                database: privateDatabase)
            for record in changes.modifications {
                if let snapshot = MedicineRecordCoder.snapshot(from: record) {
                    try localStore.upsertFromCloud(snapshot)
                }
            }
            for recordID in changes.deletions {
                if let uuid = UUID(uuidString: recordID.recordName) {
                    sharedRecordIDs[uuid] = nil
                    try localStore.deleteByUUID(uuid)
                }
            }
            pendingToken = changes.token
            moreComing = changes.moreComing
        }

        changeToken = pendingToken
    }

    private func pullSharedMedicines() async throws {
        guard let localStore else { return }

        let zones = try await CloudKitOperations.allRecordZones(in: sharedDatabase)
        var seenSharedUUIDs: Set<UUID> = []

        for zone in zones {
            let records = try await CloudKitOperations.queryMedicines(
                inZone: zone.zoneID,
                database: sharedDatabase)
            for record in records {
                guard let snapshot = MedicineRecordCoder.snapshot(from: record) else { continue }
                sharedRecordIDs[snapshot.uuid] = record.recordID
                seenSharedUUIDs.insert(snapshot.uuid)
                try localStore.upsertFromCloud(snapshot)
            }
        }

        // Clear stale routing so local edits to departed shared items go to the private DB.
        for uuid in Array(sharedRecordIDs.keys) where !seenSharedUUIDs.contains(uuid) {
            sharedRecordIDs[uuid] = nil
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

    var errorDescription: String? {
        switch self {
        case .storeUnavailable:
            String(localized: "settings.sync.store_unavailable")
        }
    }
}
