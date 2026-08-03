//
//  MedicineForm.swift
//  aegis
//

import Foundation

/// Medicine form. A stable `rawValue` is stored so changing the UI language
/// does not break data synced through iCloud.
nonisolated enum MedicineForm: String, CaseIterable, Identifiable, Hashable, Sendable {
    case tablet
    case capsule
    case syrup
    case drops
    case eyeDrops
    case ointment
    case suppository
    case spray
    case inhaler
    case injection
    case other

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .tablet: "pills.fill"
        case .capsule: "capsule.fill"
        case .syrup: "waterbottle.fill"
        case .drops: "drop.fill"
        case .eyeDrops: "eyedropper.halffull"
        case .ointment: "bandage.fill"
        case .suppository: "oval.portrait.fill"
        case .spray: "humidifier.fill"
        case .inhaler: "inhaler.fill"
        case .injection: "syringe.fill"
        case .other: "cross.case.fill"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .tablet:
            LocalizedStringResource("medicine_form.tablet", defaultValue: "Tabletki",
                                    comment: "Medicine form")
        case .capsule:
            LocalizedStringResource("medicine_form.capsule", defaultValue: "Kapsułki",
                                    comment: "Medicine form")
        case .syrup:
            LocalizedStringResource("medicine_form.syrup", defaultValue: "Syrop",
                                    comment: "Medicine form")
        case .drops:
            LocalizedStringResource("medicine_form.drops", defaultValue: "Krople",
                                    comment: "Medicine form")
        case .eyeDrops:
            LocalizedStringResource("medicine_form.eye_drops", defaultValue: "Krople do oczu",
                                    comment: "Medicine form")
        case .ointment:
            LocalizedStringResource("medicine_form.ointment", defaultValue: "Maść / krem",
                                    comment: "Medicine form")
        case .suppository:
            LocalizedStringResource("medicine_form.suppository", defaultValue: "Czopki",
                                    comment: "Medicine form")
        case .spray:
            LocalizedStringResource("medicine_form.spray", defaultValue: "Spray",
                                    comment: "Medicine form")
        case .inhaler:
            LocalizedStringResource("medicine_form.inhaler", defaultValue: "Inhalator",
                                    comment: "Medicine form")
        case .injection:
            LocalizedStringResource("medicine_form.injection", defaultValue: "Zastrzyk",
                                    comment: "Medicine form")
        case .other:
            LocalizedStringResource("medicine_form.other", defaultValue: "Inne",
                                    comment: "Medicine form")
        }
    }

    /// Typical post-opening shelf life in days. `nil` means there is no common
    /// rule for this form and the package expiry still applies.
    var suggestedDaysAfterOpening: Int? {
        switch self {
        case .syrup: 30
        case .drops: 30
        case .eyeDrops: 28
        case .ointment: 90
        case .spray: 90
        case .inhaler: 90
        case .tablet, .capsule, .suppository, .injection, .other: nil
        }
    }
}
