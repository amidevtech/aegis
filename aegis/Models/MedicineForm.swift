//
//  MedicineForm.swift
//  aegis
//

import Foundation

/// Postać leku. W bazie zapisywany jest stabilny `rawValue`, żeby zmiana języka
/// interfejsu nie naruszyła danych zsynchronizowanych przez iCloud.
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
                                    comment: "Postać leku")
        case .capsule:
            LocalizedStringResource("medicine_form.capsule", defaultValue: "Kapsułki",
                                    comment: "Postać leku")
        case .syrup:
            LocalizedStringResource("medicine_form.syrup", defaultValue: "Syrop",
                                    comment: "Postać leku")
        case .drops:
            LocalizedStringResource("medicine_form.drops", defaultValue: "Krople",
                                    comment: "Postać leku")
        case .eyeDrops:
            LocalizedStringResource("medicine_form.eye_drops", defaultValue: "Krople do oczu",
                                    comment: "Postać leku")
        case .ointment:
            LocalizedStringResource("medicine_form.ointment", defaultValue: "Maść / krem",
                                    comment: "Postać leku")
        case .suppository:
            LocalizedStringResource("medicine_form.suppository", defaultValue: "Czopki",
                                    comment: "Postać leku")
        case .spray:
            LocalizedStringResource("medicine_form.spray", defaultValue: "Spray",
                                    comment: "Postać leku")
        case .inhaler:
            LocalizedStringResource("medicine_form.inhaler", defaultValue: "Inhalator",
                                    comment: "Postać leku")
        case .injection:
            LocalizedStringResource("medicine_form.injection", defaultValue: "Zastrzyk",
                                    comment: "Postać leku")
        case .other:
            LocalizedStringResource("medicine_form.other", defaultValue: "Inne",
                                    comment: "Postać leku")
        }
    }

    /// Typowa przydatność po otwarciu w dniach. `nil` oznacza, że dla tej postaci
    /// nie ma powszechnej normy i termin z opakowania obowiązuje dalej.
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
