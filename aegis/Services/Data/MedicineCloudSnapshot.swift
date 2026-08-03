//
//  MedicineCloudSnapshot.swift
//  aegis
//

import Foundation

/// Stateless medicine snapshot for LocalStore ↔ CloudKit mirroring (no SwiftData dependency in the coder).
struct MedicineCloudSnapshot: Equatable, Sendable {
    var uuid: UUID
    var name: String
    var activeSubstance: String
    var expiryDate: Date
    var personName: String
    var indication: String
    var dosage: String
    var quantity: String
    var formRaw: String
    var notes: String
    var isOpened: Bool
    var openedAt: Date?
    var daysAfterOpening: Int?
    var openedExpiryOverride: Date?
    var effectiveExpiryDate: Date
    var createdAt: Date
    var archivedAt: Date?
    var archiveReasonRaw: String?
    var modifiedAt: Date

    init(from medicine: Medicine) {
        uuid = medicine.uuid
        name = medicine.name
        activeSubstance = medicine.activeSubstance
        expiryDate = medicine.expiryDate
        personName = medicine.personName
        indication = medicine.indication
        dosage = medicine.dosage
        quantity = medicine.quantity
        formRaw = medicine.formRaw
        notes = medicine.notes
        isOpened = medicine.isOpened
        openedAt = medicine.openedAt
        daysAfterOpening = medicine.daysAfterOpening
        openedExpiryOverride = medicine.openedExpiryOverride
        effectiveExpiryDate = medicine.effectiveExpiryDate
        createdAt = medicine.createdAt
        archivedAt = medicine.archivedAt
        archiveReasonRaw = medicine.archiveReasonRaw
        modifiedAt = medicine.modifiedAt
    }

    func apply(to medicine: Medicine) {
        medicine.uuid = uuid
        medicine.name = name
        medicine.activeSubstance = activeSubstance
        medicine.expiryDate = expiryDate
        medicine.personName = personName
        medicine.indication = indication
        medicine.dosage = dosage
        medicine.quantity = quantity
        medicine.formRaw = formRaw
        medicine.notes = notes
        medicine.isOpened = isOpened
        medicine.openedAt = openedAt
        medicine.daysAfterOpening = daysAfterOpening
        medicine.openedExpiryOverride = openedExpiryOverride
        medicine.effectiveExpiryDate = effectiveExpiryDate
        medicine.createdAt = createdAt
        medicine.archivedAt = archivedAt
        medicine.archiveReasonRaw = archiveReasonRaw
        medicine.modifiedAt = modifiedAt
    }
}
