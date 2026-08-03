//
//  ArchiveReason.swift
//  aegis
//

import Foundation

/// Powód, dla którego lek zniknął z apteczki. Zapisywany jako stabilny `rawValue`.
nonisolated enum ArchiveReason: String, CaseIterable, Identifiable, Hashable, Sendable {
    case expired
    case usedUp
    case removed

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .expired: "calendar.badge.exclamationmark"
        case .usedUp: "shippingbox.fill"
        case .removed: "tray.full.fill"
        }
    }

    var label: LocalizedStringResource {
        switch self {
        case .expired:
            LocalizedStringResource("archive_reason.expired", defaultValue: "Przeterminowany",
                                    comment: "Powód archiwizacji leku")
        case .usedUp:
            LocalizedStringResource("archive_reason.used_up", defaultValue: "Zużyty",
                                    comment: "Powód archiwizacji leku")
        case .removed:
            LocalizedStringResource("archive_reason.removed", defaultValue: "Usunięty z apteczki",
                                    comment: "Powód archiwizacji leku")
        }
    }
}
