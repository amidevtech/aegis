//
//  MedicineStatus.swift
//  aegis
//

import Foundation

/// Medicine expiry status derived from the effective date.
nonisolated enum MedicineStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case valid
    case expiringSoon
    case expired

    /// How many days before expiry a medicine enters the "expiring soon" section.
    static let soonThresholdInDays = 5

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
