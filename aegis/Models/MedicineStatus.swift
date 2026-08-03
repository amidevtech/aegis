//
//  MedicineStatus.swift
//  aegis
//

import Foundation

/// Stan ważności leku wyliczany z obowiązującego terminu.
nonisolated enum MedicineStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case valid
    case expiringSoon
    case expired

    /// Ile dni przed terminem lek trafia do sekcji "wkrótce wygasają".
    static let soonThresholdInDays = 30

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .valid: "checkmark.circle.fill"
        case .expiringSoon: "clock.fill"
        case .expired: "exclamationmark.triangle.fill"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .valid: L10n.Status.valid
        case .expiringSoon: L10n.Status.expiringSoon
        case .expired: L10n.Status.expired
        }
    }

    var sectionTitle: LocalizedStringResource {
        switch self {
        case .valid: L10n.Medicines.sectionValid
        case .expiringSoon: L10n.Medicines.sectionExpiringSoon
        case .expired: L10n.Medicines.sectionExpired
        }
    }
}
