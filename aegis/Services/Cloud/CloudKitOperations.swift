//
//  CloudKitOperations.swift
//  aegis
//

import CloudKit
import Foundation

/// CloudKit I/O that is not MainActor-isolated so network work does not contend with UI.
enum CloudKitOperations {
    static func accountStatus(for container: CKContainer) async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    static func accept(_ metadata: CKShare.Metadata, on container: CKContainer) async throws {
        try await container.accept(metadata)
    }

    static func saveZone(_ zone: CKRecordZone, to database: CKDatabase) async throws {
        do {
            _ = try await database.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists.
        } catch let error as CKError where error.code == .partialFailure {
            // Partial success when the zone already exists — continue.
        }
    }

    static func fetchRecord(id: CKRecord.ID, from database: CKDatabase) async throws -> CKRecord {
        try await database.record(for: id)
    }

    static func saveRecord(_ record: CKRecord, to database: CKDatabase) async throws -> CKRecord {
        try await database.save(record)
    }

    static func deleteRecord(id: CKRecord.ID, from database: CKDatabase) async throws {
        do {
            try await database.deleteRecord(withID: id)
        } catch let error as CKError where error.code == .unknownItem {
            // Already deleted in the cloud.
        }
    }

    static func modifyRecords(
        saving records: [CKRecord],
        deleting ids: [CKRecord.ID] = [],
        in database: CKDatabase
    ) async throws {
        guard !records.isEmpty || !ids.isEmpty else { return }
        _ = try await database.modifyRecords(saving: records, deleting: ids)
    }

    /// Fetches existing records (preserving change tags), applies snapshots, then saves.
    static func upsertMedicineRecords(
        _ snapshots: [MedicineCloudSnapshot],
        zoneID: CKRecordZone.ID,
        database: CKDatabase
    ) async throws {
        guard !snapshots.isEmpty else { return }

        let recordIDs = snapshots.map {
            MedicineRecordCoder.recordID(for: $0.uuid, zoneID: zoneID)
        }

        var existingByID: [CKRecord.ID: CKRecord] = [:]
        do {
            let results = try await database.records(for: recordIDs)
            for (id, result) in results {
                if case .success(let record) = result {
                    existingByID[id] = record
                }
            }
        } catch {
            // Fall through — treat all as creates when the batch fetch fails.
        }

        let records: [CKRecord] = snapshots.map { snapshot in
            let id = MedicineRecordCoder.recordID(for: snapshot.uuid, zoneID: zoneID)
            if let existing = existingByID[id] {
                MedicineRecordCoder.apply(snapshot, to: existing)
                return existing
            }
            return MedicineRecordCoder.makeRecord(from: snapshot, zoneID: zoneID)
        }

        for chunk in records.chunked(into: 200) {
            try await modifyRecords(saving: chunk, in: database)
        }
    }

    static func allRecordZones(in database: CKDatabase) async throws -> [CKRecordZone] {
        try await database.allRecordZones()
    }

    static func queryMedicines(
        inZone zoneID: CKRecordZone.ID,
        database: CKDatabase
    ) async throws -> [CKRecord] {
        let query = CKQuery(
            recordType: MedicineRecordCoder.recordType,
            predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query, inZoneWith: zoneID)
        return results.compactMap { _, result in
            if case .success(let record) = result { return record }
            return nil
        }
    }

    static func fetchZoneChanges(
        zoneID: CKRecordZone.ID,
        previousToken: CKServerChangeToken?,
        database: CKDatabase
    ) async throws -> ZoneChanges {
        try await withCheckedThrowingContinuation { continuation in
            var result = ZoneChanges()
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            config.previousServerChangeToken = previousToken

            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [zoneID],
                configurationsByRecordZoneID: [zoneID: config])

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

            database.add(operation)
        }
    }

    struct ZoneChanges {
        var modifications: [CKRecord] = []
        var deletions: [CKRecord.ID] = []
        var token: CKServerChangeToken?
        var moreComing = false
    }
}

extension Array {
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
