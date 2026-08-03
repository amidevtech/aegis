//
//  MedicineFormatting.swift
//  aegis
//

import Foundation

/// Derived copy from medicine state. All dates use `Date.FormatStyle`,
/// so day/month layout follows the user's region.
extension Medicine {

    var expiryDateText: String {
        effectiveExpiryDate.formatted(date: .abbreviated, time: .omitted)
    }

    var packageExpiryDateText: String {
        expiryDate.formatted(date: .abbreviated, time: .omitted)
    }

    var openedAtText: String? {
        openedAt?.formatted(date: .abbreviated, time: .omitted)
    }

    var openedExpiryDateText: String? {
        openedExpiryDate?.formatted(date: .abbreviated, time: .omitted)
    }

    var createdAtText: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var archivedAtText: String? {
        archivedAt?.formatted(date: .abbreviated, time: .omitted)
    }

    /// Short expiry blurb: "Expires in 12 days", "Expires today", "Expired 3 days ago".
    func expiryDescription(now: Date = .now) -> LocalizedStringResource {
        let days = daysRemaining(now: now)
        if days == 0 { return L10n.Status.expiresToday }
        if days < 0 { return L10n.Status.expiredAgo(days: -days) }
        return L10n.Status.expiresIn(days: days)
    }

    /// Second line of a list row: active substance, or indication when substance is empty.
    var subtitleText: String? {
        let candidates = [activeSubstance, indication, quantity]
        return candidates.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Person and indication joined into one line, skipping empty values.
    var metaText: String? {
        let parts = [personName, indication].filter {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return parts.isEmpty ? nil : ListFormatter.localizedString(byJoining: parts)
    }
}
