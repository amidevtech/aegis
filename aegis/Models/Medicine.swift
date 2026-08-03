//
//  Medicine.swift
//  aegis
//

import Foundation
import SwiftData

/// Lek w domowej apteczce.
///
/// Model jest zgodny z wymaganiami CloudKit: każda właściwość ma wartość domyślną
/// albo jest opcjonalna, nie ma też ograniczeń unikalności.
@Model
final class Medicine {
    /// Stabilny identyfikator używany do powiązania leku z zaplanowanymi powiadomieniami.
    /// `persistentModelID` się do tego nie nadaje, bo nie ma trwałej reprezentacji tekstowej.
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

    /// Wcześniejszy z terminów - z opakowania i po otwarciu.
    ///
    /// Trzymany w bazie, a nie liczony w locie, bo `#Predicate` nie potrafi filtrować
    /// po właściwościach obliczanych. Aktualizuje go `refreshEffectiveExpiry()`.
    var effectiveExpiryDate: Date = Date.distantFuture

    var createdAt: Date = Date.now
    var archivedAt: Date?
    var archiveReasonRaw: String?

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
        createdAt: Date = .now
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
        self.effectiveExpiryDate = ExpiryCalculator.effectiveExpiry(
            packageExpiry: expiryDate,
            isOpened: isOpened,
            openedAt: openedAt,
            daysAfterOpening: daysAfterOpening,
            openedExpiryOverride: openedExpiryOverride)
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

    /// Termin liczony od otwarcia opakowania, o ile lek jest otwarty.
    var openedExpiryDate: Date? {
        guard isOpened else { return nil }
        return ExpiryCalculator.openedExpiry(
            openedAt: openedAt,
            daysAfterOpening: daysAfterOpening,
            override: openedExpiryOverride)
    }

    /// Czy o terminie decyduje otwarcie opakowania, a nie data z pudełka.
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

    /// Przelicza zapisany termin obowiązujący. Wywoływane po każdej zmianie dat.
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
