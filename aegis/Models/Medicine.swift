//
//  Medicine.swift
//  aegis
//

import Foundation
import SwiftData

/// A medicine in the home cabinet.
///
/// Model meets CloudKit requirements: every property has a default value
/// or is optional, and there are no uniqueness constraints.
@Model
final class Medicine {
    /// Stable identifier used to link a medicine to scheduled notifications.
    /// `persistentModelID` is unsuitable because it has no durable string form.
    var uuid: UUID = UUID()

    var name: String = ""
    var activeSubstance: String = ""
    var expiryDate: Date = Date.distantFuture
    var personName: String = ""
    var indication: String = ""
    var dosage: String = ""
    var quantity: String = ""
    var formRaw: String = MedicineForm.other.rawValue
    var notes: String = ""

    var isOpened: Bool = false
    var openedAt: Date?
    var daysAfterOpening: Int?
    var openedExpiryOverride: Date?

    /// Earlier of the package and post-opening expiry dates.
    ///
    /// Stored in the database rather than computed on the fly, because `#Predicate`
    /// cannot filter on computed properties. Updated by `refreshEffectiveExpiry()`.
    var effectiveExpiryDate: Date = Date.distantFuture

    var createdAt: Date = Date.now
    var archivedAt: Date?
    var archiveReasonRaw: String?

    /// Timestamp for last-write-wins when mirroring CloudKit.
    var modifiedAt: Date = Date.now

    init(
        name: String = "",
        activeSubstance: String = "",
        expiryDate: Date = .distantFuture,
        personName: String = "",
        indication: String = "",
        dosage: String = "",
        quantity: String = "",
        form: MedicineForm = .other,
        notes: String = "",
        isOpened: Bool = false,
        openedAt: Date? = nil,
        daysAfterOpening: Int? = nil,
        openedExpiryOverride: Date? = nil,
        createdAt: Date = .now,
        modifiedAt: Date = .now
    ) {
        self.name = name
        self.activeSubstance = activeSubstance
        self.expiryDate = expiryDate
        self.personName = personName
        self.indication = indication
        self.dosage = dosage
        self.quantity = quantity
        self.formRaw = form.rawValue
        self.notes = notes
        self.isOpened = isOpened
        self.openedAt = openedAt
        self.daysAfterOpening = daysAfterOpening
        self.openedExpiryOverride = openedExpiryOverride
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.effectiveExpiryDate = ExpiryCalculator.effectiveExpiry(
            packageExpiry: expiryDate,
            isOpened: isOpened,
            openedAt: openedAt,
            daysAfterOpening: daysAfterOpening,
            openedExpiryOverride: openedExpiryOverride)
    }

    func touchModified(at date: Date = .now) {
        modifiedAt = date
    }
}

extension Medicine {
    var form: MedicineForm {
        get { MedicineForm(rawValue: formRaw) ?? .other }
        set { formRaw = newValue.rawValue }
    }

    var archiveReason: ArchiveReason? {
        get { archiveReasonRaw.flatMap(ArchiveReason.init(rawValue:)) }
        set { archiveReasonRaw = newValue?.rawValue }
    }

    var isArchived: Bool { archivedAt != nil }

    /// Expiry counted from package opening, when the medicine is opened.
    var openedExpiryDate: Date? {
        guard isOpened else { return nil }
        return ExpiryCalculator.openedExpiry(
            openedAt: openedAt,
            daysAfterOpening: daysAfterOpening,
            override: openedExpiryOverride)
    }

    /// Whether the effective date is driven by opening rather than the box date.
    var isLimitedByOpening: Bool {
        guard let openedExpiryDate else { return false }
        return openedExpiryDate < Calendar.current.startOfDay(for: expiryDate)
    }

    func status(now: Date = .now) -> MedicineStatus {
        ExpiryCalculator.status(effectiveExpiry: effectiveExpiryDate, now: now)
    }

    func daysRemaining(now: Date = .now) -> Int {
        ExpiryCalculator.daysRemaining(until: effectiveExpiryDate, now: now)
    }

    /// Recalculates the stored effective expiry. Called after every date change.
    func refreshEffectiveExpiry() {
        effectiveExpiryDate = ExpiryCalculator.effectiveExpiry(
            packageExpiry: expiryDate,
            isOpened: isOpened,
            openedAt: openedAt,
            daysAfterOpening: daysAfterOpening,
            openedExpiryOverride: openedExpiryOverride)
    }

    func markOpened(on date: Date = .now) {
        isOpened = true
        openedAt = date
        if daysAfterOpening == nil, openedExpiryOverride == nil {
            daysAfterOpening = form.suggestedDaysAfterOpening
        }
        refreshEffectiveExpiry()
    }

    func markUnopened() {
        isOpened = false
        openedAt = nil
        openedExpiryOverride = nil
        refreshEffectiveExpiry()
    }

    func archive(reason: ArchiveReason, at date: Date = .now) {
        archivedAt = date
        archiveReason = reason
    }

    func restore() {
        archivedAt = nil
        archiveReason = nil
    }
}
