//
//  CloudSyncService.swift
//  aegis
//

import CloudKit
import Foundation
import Observation

/// Mirror LocalStore ↔ CloudKit (private zone + shared DB po akceptacji CKShare).
@MainActor
@Observable
final class CloudSyncService {
    private(set) var isRunning = false
    private(set) var lastErrorMessage: String?
    private(set) var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var share: CKShare?

    private let containerIdentifier: String
    private var container: CKContainer { CKContainer(identifier: containerIdentifier) }
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }
    private var sharedDatabase: CKDatabase { container.sharedCloudDatabase }
    private weak var localStore: LocalStore?

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
    private static let containerIdentifier = "iCloud.com.amidev.aegis"

    init(containerIdentifier: String = CloudSyncService.containerIdentifier) {
        self.containerIdentifier = containerIdentifier
    }

    var accountAvailable: Bool {
        iCloudAccountStatus == .available
    }

    func refreshAccountStatus() async {
        do {
            iCloudAccountStatus = try await container.accountStatus()
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
    }

    func upsert(_ snapshot: MedicineCloudSnapshot) async {
        guard isRunning else { return }
        do {
            let record = MedicineRecordCoder.makeRecord(from: snapshot)
            _ = try await privateDatabase.save(record)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func deleteMedicine(uuid: UUID) async {
        guard isRunning else { return }
        do {
            try await privateDatabase.deleteRecord(withID: MedicineRecordCoder.recordID(for: uuid))
            lastErrorMessage = nil
        } catch let error as CKError where error.code == .unknownItem {
            // Już usunięty w chmurze.
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
        let cabinet = try await privateDatabase.record(for: cabinetID)
        let newShare = CKShare(rootRecord: cabinet)
        newShare[CKShare.SystemFieldKey.title] = String(localized: "settings.share.title")
        newShare.publicPermission = .none

        _ = try await privateDatabase.modifyRecords(
            saving: [cabinet, newShare],
            deleting: [])

        share = newShare
        return newShare
    }

    func acceptShare(metadata: CKShare.Metadata) async throws {
        try await container.accept(metadata)
        try await pullSharedMedicines()
        isRunning = true
    }

    // MARK: - Private helpers

    private func ensureZoneAndCabinet() async throws {
        let zone = CKRecordZone(zoneID: MedicineRecordCoder.zoneID)
        do {
            _ = try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Strefa już istnieje.
        } catch let error as CKError where error.code == .partialFailure {
            // Częściowy sukces przy istniejącej strefie — kontynuuj.
        }

        let cabinetID = MedicineRecordCoder.cabinetRecordID()
        do {
            _ = try await privateDatabase.record(for: cabinetID)
        } catch {
            let cabinet = MedicineRecordCoder.makeCabinetRecord()
            _ = try await privateDatabase.save(cabinet)
        }
    }

    private func pushAllLocalMedicines() async throws {
        guard let localStore else { return }
        let medicines = try localStore.fetchAll()
        guard !medicines.isEmpty else { return }

        let records = medicines.map {
            MedicineRecordCoder.makeRecord(from: MedicineCloudSnapshot(from: $0))
        }

        // Chunk, żeby nie przekroczyć limitu CloudKit.
        for chunk in records.chunked(into: 200) {
            _ = try await privateDatabase.modifyRecords(saving: chunk, deleting: [])
        }
    }

    private func pullChanges() async throws {
        guard let localStore else { return }

        let zoneID = MedicineRecordCoder.zoneID
        var pendingToken = changeToken
        var moreComing = true

        while moreComing {
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            config.previousServerChangeToken = pendingToken

            let changes = try await fetchZoneChanges(zoneID: zoneID, configuration: config)
            for record in changes.modifications {
                if let snapshot = MedicineRecordCoder.snapshot(from: record) {
                    try localStore.upsertFromCloud(snapshot)
                }
            }
            for recordID in changes.deletions {
                if let uuid = UUID(uuidString: recordID.recordName) {
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

        let zones = try await sharedDatabase.allRecordZones()
        for zone in zones {
            let query = CKQuery(
                recordType: MedicineRecordCoder.recordType,
                predicate: NSPredicate(value: true))
            let (results, _) = try await sharedDatabase.records(
                matching: query,
                inZoneWith: zone.zoneID)
            for (_, result) in results {
                if case .success(let record) = result,
                   let snapshot = MedicineRecordCoder.snapshot(from: record)
                {
                    try localStore.upsertFromCloud(snapshot)
                }
            }
        }
    }

    private func fetchExistingShare() async throws -> CKShare? {
        let cabinetID = MedicineRecordCoder.cabinetRecordID()
        let cabinet = try await privateDatabase.record(for: cabinetID)
        guard let shareReference = cabinet.share else { return nil }
        return try await privateDatabase.record(for: shareReference.recordID) as? CKShare
    }

    private struct ZoneChanges {
        var modifications: [CKRecord] = []
        var deletions: [CKRecord.ID] = []
        var token: CKServerChangeToken?
        var moreComing = false
    }

    private func fetchZoneChanges(
        zoneID: CKRecordZone.ID,
        configuration: CKFetchRecordZoneChangesOperation.ZoneConfiguration
    ) async throws -> ZoneChanges {
        try await withCheckedThrowingContinuation { continuation in
            var result = ZoneChanges()
            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: configuration])

            operation.recordWasChangedBlock = { _, recordResult in
                if case .success(let record) = recordResult {
                    result.modifications.append(record)
                }
            }
            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                result.deletions.append(recordID)
            }
            operation.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
                result.token = token
            }
            operation.recordZoneFetchResultBlock = { _, zoneResult in
                if case .success(let success) = zoneResult {
                    result.token = success.serverChangeToken
                    result.moreComing = success.moreComing
                }
            }
            operation.fetchRecordZoneChangesResultBlock = { opResult in
                switch opResult {
                case .success:
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            privateDatabase.add(operation)
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        var index = startIndex
        while index < endIndex {
            let next = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            chunks.append(Array(self[index..<next]))
            index = next
        }
        return chunks
    }
}
