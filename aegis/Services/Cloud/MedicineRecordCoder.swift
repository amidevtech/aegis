//
//  MedicineRecordCoder.swift
//  aegis
//

import CloudKit
import Foundation

/// Medicine ↔ CKRecord mapping (no SwiftData).
enum MedicineRecordCoder {
    static let recordType = "Medicine"
    static let cabinetRecordType = "Cabinet"
    static let zoneName = "CabinetZone"
    static let cabinetRecordName = "default-cabinet"

    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    static func recordID(for uuid: UUID, zoneID: CKRecordZone.ID = zoneID) -> CKRecord.ID {
        CKRecord.ID(recordName: uuid.uuidString, zoneID: zoneID)
    }

    static func cabinetRecordID(zoneID: CKRecordZone.ID = zoneID) -> CKRecord.ID {
        CKRecord.ID(recordName: cabinetRecordName, zoneID: zoneID)
    }

    static func makeRecord(
        from snapshot: MedicineCloudSnapshot,
        zoneID: CKRecordZone.ID = zoneID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: recordType,
            recordID: recordID(for: snapshot.uuid, zoneID: zoneID))
        apply(snapshot, to: record)
        return record
    }

    static func apply(_ snapshot: MedicineCloudSnapshot, to record: CKRecord) {
        record["uuid"] = snapshot.uuid.uuidString as CKRecordValue
        record["name"] = snapshot.name as CKRecordValue
        record["activeSubstance"] = snapshot.activeSubstance as CKRecordValue
        record["expiryDate"] = snapshot.expiryDate as CKRecordValue
        record["personName"] = snapshot.personName as CKRecordValue
        record["indication"] = snapshot.indication as CKRecordValue
        record["dosage"] = snapshot.dosage as CKRecordValue
        record["quantity"] = snapshot.quantity as CKRecordValue
        record["formRaw"] = snapshot.formRaw as CKRecordValue
        record["notes"] = snapshot.notes as CKRecordValue
        record["isOpened"] = snapshot.isOpened as CKRecordValue
        record["openedAt"] = snapshot.openedAt as CKRecordValue?
        if let days = snapshot.daysAfterOpening {
            record["daysAfterOpening"] = days as CKRecordValue
        } else {
            record["daysAfterOpening"] = nil
        }
        record["openedExpiryOverride"] = snapshot.openedExpiryOverride as CKRecordValue?
        record["effectiveExpiryDate"] = snapshot.effectiveExpiryDate as CKRecordValue
        record["createdAt"] = snapshot.createdAt as CKRecordValue
        record["archivedAt"] = snapshot.archivedAt as CKRecordValue?
        record["archiveReasonRaw"] = snapshot.archiveReasonRaw as CKRecordValue?
        record["modifiedAt"] = snapshot.modifiedAt as CKRecordValue
        record["cabinet"] = CKRecord.Reference(
            recordID: cabinetRecordID(zoneID: record.recordID.zoneID),
            action: .none)
    }

    static func snapshot(from record: CKRecord) -> MedicineCloudSnapshot? {
        guard record.recordType == recordType,
              let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString)
        else { return nil }

        return MedicineCloudSnapshot(
            uuid: uuid,
            name: record["name"] as? String ?? "",
            activeSubstance: record["activeSubstance"] as? String ?? "",
            expiryDate: record["expiryDate"] as? Date ?? .distantFuture,
            personName: record["personName"] as? String ?? "",
            indication: record["indication"] as? String ?? "",
            dosage: record["dosage"] as? String ?? "",
            quantity: record["quantity"] as? String ?? "",
            formRaw: record["formRaw"] as? String ?? MedicineForm.other.rawValue,
            notes: record["notes"] as? String ?? "",
            isOpened: record["isOpened"] as? Bool ?? false,
            openedAt: record["openedAt"] as? Date,
            daysAfterOpening: record["daysAfterOpening"] as? Int,
            openedExpiryOverride: record["openedExpiryOverride"] as? Date,
            effectiveExpiryDate: record["effectiveExpiryDate"] as? Date ?? .distantFuture,
            createdAt: record["createdAt"] as? Date ?? .now,
            archivedAt: record["archivedAt"] as? Date,
            archiveReasonRaw: record["archiveReasonRaw"] as? String,
            modifiedAt: record["modifiedAt"] as? Date ?? .now)
    }

    static func makeCabinetRecord(zoneID: CKRecordZone.ID = zoneID) -> CKRecord {
        let record = CKRecord(
            recordType: cabinetRecordType,
            recordID: cabinetRecordID(zoneID: zoneID))
        record["title"] = String(localized: "settings.share.title") as CKRecordValue
        record["modifiedAt"] = Date.now as CKRecordValue
        return record
    }

    static func modifiedAt(from record: CKRecord) -> Date? {
        record["modifiedAt"] as? Date
    }

    /// Upload when local is strictly newer than cloud. Skip when cloud is missing
    /// a timestamp only if we still want to upload — callers pass cloud date when known.
    /// On ties (`cloud >= local`), skip upload so devices do not thrash.
    static func shouldUpload(localModifiedAt: Date, cloudModifiedAt: Date?) -> Bool {
        guard let cloudModifiedAt else { return true }
        return localModifiedAt > cloudModifiedAt
    }

    /// Shared-zone UUIDs that were routed locally but absent from a successful pull.
    static func departedSharedUUIDs(previous: Set<UUID>, seen: Set<UUID>) -> Set<UUID> {
        previous.subtracting(seen)
    }

    /// Local deletes for shared departures — never when the pull was incomplete
    /// (partial match failures must not look like real departures).
    static func localDeletesForSharedDeparture(
        previous: Set<UUID>,
        seen: Set<UUID>,
        pullIsComplete: Bool
    ) -> Set<UUID> {
        guard pullIsComplete else { return [] }
        return departedSharedUUIDs(previous: previous, seen: seen)
    }

    /// Tombstoned shared hits keep routing / seen membership; only skip local upsert.
    static func shouldUpsertSharedPull(isTombstoned: Bool) -> Bool {
        !isTombstoned
    }

    /// Concatenate CloudKit query pages in order (cursor pagination).
    static func mergePagedResults<T>(_ pages: [[T]]) -> [T] {
        pages.flatMap { $0 }
    }

    /// One page of a CloudKit medicine query, including completeness.
    struct MatchResultsPage: Equatable {
        var records: [CKRecord]
        var isComplete: Bool

        static func == (lhs: MatchResultsPage, rhs: MatchResultsPage) -> Bool {
            lhs.isComplete == rhs.isComplete
                && lhs.records.map(\.recordID) == rhs.records.map(\.recordID)
        }
    }

    /// Parses CloudKit match results. Any `.failure` marks the page incomplete.
    static func parseMatchResults(
        _ matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)]
    ) -> MatchResultsPage {
        var records: [CKRecord] = []
        var isComplete = true
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure:
                isComplete = false
            }
        }
        return MatchResultsPage(records: records, isComplete: isComplete)
    }
}

extension MedicineCloudSnapshot {
    init(
        uuid: UUID,
        name: String,
        activeSubstance: String,
        expiryDate: Date,
        personName: String,
        indication: String,
        dosage: String,
        quantity: String,
        formRaw: String,
        notes: String,
        isOpened: Bool,
        openedAt: Date?,
        daysAfterOpening: Int?,
        openedExpiryOverride: Date?,
        effectiveExpiryDate: Date,
        createdAt: Date,
        archivedAt: Date?,
        archiveReasonRaw: String?,
        modifiedAt: Date
    ) {
        self.uuid = uuid
        self.name = name
        self.activeSubstance = activeSubstance
        self.expiryDate = expiryDate
        self.personName = personName
        self.indication = indication
        self.dosage = dosage
        self.quantity = quantity
        self.formRaw = formRaw
        self.notes = notes
        self.isOpened = isOpened
        self.openedAt = openedAt
        self.daysAfterOpening = daysAfterOpening
        self.openedExpiryOverride = openedExpiryOverride
        self.effectiveExpiryDate = effectiveExpiryDate
        self.createdAt = createdAt
        self.archivedAt = archivedAt
        self.archiveReasonRaw = archiveReasonRaw
        self.modifiedAt = modifiedAt
    }
}
