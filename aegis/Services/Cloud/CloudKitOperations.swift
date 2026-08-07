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
        do {
            _ = try await database.modifyRecords(saving: records, deleting: ids)
        } catch let error as CKError {
            let retry = try resolveConflicts(error: error, intendedSaves: records)
            guard !retry.isEmpty || !ids.isEmpty else { return }
            if !retry.isEmpty || !ids.isEmpty {
                _ = try await database.modifyRecords(saving: retry, deleting: ids)
            }
        }
    }

    /// Fetches existing records (preserving change tags), applies snapshots with upload LWW, then saves.
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

        let records: [CKRecord] = snapshots.compactMap { snapshot in
            let id = MedicineRecordCoder.recordID(for: snapshot.uuid, zoneID: zoneID)
            if let existing = existingByID[id] {
                let cloudModified = MedicineRecordCoder.modifiedAt(from: existing)
                guard MedicineRecordCoder.shouldUpload(
                    localModifiedAt: snapshot.modifiedAt,
                    cloudModifiedAt: cloudModified)
                else {
                    return nil
                }
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

        var pages: [[CKRecord]] = []
        var cursor: CKQueryOperation.Cursor?

        let first = try await database.records(matching: query, inZoneWith: zoneID)
        pages.append(Self.records(from: first.matchResults))
        cursor = first.queryCursor

        while let current = cursor {
            let next = try await database.records(continuingMatchFrom: current)
            pages.append(Self.records(from: next.matchResults))
            cursor = next.queryCursor
        }

        return MedicineRecordCoder.mergePagedResults(pages)
    }

    private static func records(
        from matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)]
    ) -> [CKRecord] {
        matchResults.compactMap { _, result in
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

    /// Returns records that should be retried after a conflict (local still wins LWW).
    /// Throws the original error when the conflict cannot be resolved.
    private static func resolveConflicts(
        error: CKError,
        intendedSaves: [CKRecord]
    ) throws -> [CKRecord] {
        let intendedByID = Dictionary(
            uniqueKeysWithValues: intendedSaves.map { ($0.recordID, $0) })

        var serverByID: [CKRecord.ID: CKRecord] = [:]

        if error.code == .serverRecordChanged {
            if let server = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                serverByID[server.recordID] = server
            }
        }

        if error.code == .partialFailure,
           let partial = error.partialErrorsByItemID as? [CKRecord.ID: Error]
        {
            for (id, itemError) in partial {
                guard let ckError = itemError as? CKError else { continue }
                if ckError.code == .serverRecordChanged,
                   let server = ckError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
                {
                    serverByID[id] = server
                } else if ckError.code != .serverRecordChanged {
                    throw error
                }
            }
        } else if error.code != .serverRecordChanged {
            throw error
        }

        var retry: [CKRecord] = []
        for (id, server) in serverByID {
            guard let intended = intendedByID[id] else { continue }
            let localModified = MedicineRecordCoder.modifiedAt(from: intended) ?? .distantPast
            let cloudModified = MedicineRecordCoder.modifiedAt(from: server)
            guard MedicineRecordCoder.shouldUpload(
                localModifiedAt: localModified,
                cloudModifiedAt: cloudModified)
            else {
                continue
            }
            if let snapshot = MedicineRecordCoder.snapshot(from: intended) {
                MedicineRecordCoder.apply(snapshot, to: server)
                retry.append(server)
            }
        }

        // If we had conflicts but none to retry, treat as success (cloud won LWW).
        if serverByID.isEmpty {
            throw error
        }
        return retry
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
