//
//  MedicineRecordCoder.swift
//  aegis
//

import CloudKit
import Foundation

/// Mapowanie Medicine ↔ CKRecord (bez SwiftData).
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
        record["title"] = "Home Cabinet" as CKRecordValue
        record["modifiedAt"] = Date.now as CKRecordValue
        return record
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
