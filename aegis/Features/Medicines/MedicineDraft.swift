//
//  MedicineDraft.swift
//  aegis
//

import Foundation

/// Editable copy of a medicine. The form works on this instead of the stored
/// object, so cancelling does not leave partial changes behind.
nonisolated struct MedicineDraft {
    var name = ""
    var activeSubstance = ""
    var expiryDate = MedicineDraft.defaultExpiryDate
    var personName = ""
    var indication = ""
    var dosage = ""
    var quantity = ""
    var form: MedicineForm = .tablet
    var notes = ""

    var isOpened = false
    var openedAt = Date.now
    var daysAfterOpening = 30
    var usesCustomOpenedDate = false
    var customOpenedExpiry = MedicineDraft.defaultOpenedExpiryDate

    static var defaultExpiryDate: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    }

    static var defaultOpenedExpiryDate: Date {
        Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Effective expiry, shown live under the form fields.
    var effectiveExpiryDate: Date {
        ExpiryCalculator.effectiveExpiry(
            packageExpiry: expiryDate,
            isOpened: isOpened,
            openedAt: openedAt,
            daysAfterOpening: usesCustomOpenedDate ? nil : daysAfterOpening,
            openedExpiryOverride: usesCustomOpenedDate ? customOpenedExpiry : nil)
    }

    init() {}

    init(from medicine: Medicine) {
        name = medicine.name
        activeSubstance = medicine.activeSubstance
        expiryDate = medicine.expiryDate
        personName = medicine.personName
        indication = medicine.indication
        dosage = medicine.dosage
        quantity = medicine.quantity
        form = medicine.form
        notes = medicine.notes
        isOpened = medicine.isOpened
        openedAt = medicine.openedAt ?? .now
        daysAfterOpening = medicine.daysAfterOpening
            ?? medicine.form.suggestedDaysAfterOpening
            ?? 30
        usesCustomOpenedDate = medicine.openedExpiryOverride != nil
        customOpenedExpiry = medicine.openedExpiryOverride ?? Self.defaultOpenedExpiryDate
    }

    func apply(to medicine: Medicine) {
        medicine.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.activeSubstance = activeSubstance.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.expiryDate = expiryDate
        medicine.personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.indication = indication.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.dosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.quantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.form = form
        medicine.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        medicine.isOpened = isOpened
        medicine.openedAt = isOpened ? openedAt : nil
        medicine.daysAfterOpening = isOpened && !usesCustomOpenedDate ? daysAfterOpening : nil
        medicine.openedExpiryOverride = isOpened && usesCustomOpenedDate ? customOpenedExpiry : nil

        medicine.refreshEffectiveExpiry()
    }

    /// After changing the medicine form, suggest the typical post-opening
    /// shelf life unless the user already set their own value.
    mutating func applySuggestedShelfLife(for form: MedicineForm) {
        guard let suggested = form.suggestedDaysAfterOpening else { return }
        daysAfterOpening = suggested
    }
}
