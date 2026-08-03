//
//  MedicineFormatting.swift
//  aegis
//

import Foundation

/// Teksty pochodne od stanu leku. Wszystkie daty formatowane są przez `Date.FormatStyle`,
/// więc układ dnia i miesiąca dopasowuje się do regionu użytkownika.
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

    /// Krótki opis terminu: "Wygasa za 12 dni", "Wygasa dziś", "Po terminie od 3 dni".
    func expiryDescription(now: Date = .now) -> LocalizedStringResource {
        let days = daysRemaining(now: now)
        if days == 0 { return L10n.Status.expiresToday }
        if days < 0 { return L10n.Status.expiredAgo(days: -days) }
        return L10n.Status.expiresIn(days: days)
    }

    /// Druga linia wiersza listy: substancja czynna, a gdy jej nie podano - zastosowanie.
    var subtitleText: String? {
        let candidates = [activeSubstance, indication, quantity]
        return candidates.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Osoba i dolegliwość połączone w jedną linię, z pominięciem pustych wartości.
    var metaText: String? {
        let parts = [personName, indication].filter {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return parts.isEmpty ? nil : ListFormatter.localizedString(byJoining: parts)
    }
}
