//
//  ArchiveReason.swift
//  aegis
//

import Foundation

/// Why a medicine left the cabinet. Stored as a stable `rawValue`.
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
            LocalizedStringResource("archive_reason.expired", defaultValue: "Expired",
                                    comment: "Reason for archiving a medicine")
        case .usedUp:
            LocalizedStringResource("archive_reason.used_up", defaultValue: "Used up",
                                    comment: "Reason for archiving a medicine")
        case .removed:
            LocalizedStringResource("archive_reason.removed", defaultValue: "Removed from cabinet",
                                    comment: "Reason for archiving a medicine")
        }
    }
}
