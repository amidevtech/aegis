//
//  ExpiryCalculator.swift
//  aegis
//

import Foundation

/// Czysta logika terminów ważności - bez SwiftData i bez SwiftUI, żeby dała się
/// testować w oderwaniu od reszty aplikacji.
///
/// Wszystkie daty są normalizowane do początku dnia. Lek z terminem "3 sierpnia"
/// jest ważny przez cały 3 sierpnia i traci ważność dopiero 4 sierpnia.
nonisolated enum ExpiryCalculator {

    /// Termin liczony od momentu otwarcia opakowania.
    /// Ręcznie wybrana data ma pierwszeństwo przed liczbą dni.
    static func openedExpiry(
        openedAt: Date?,
        daysAfterOpening: Int?,
        override: Date?,
        calendar: Calendar = .current
    ) -> Date? {
        if let override {
            return calendar.startOfDay(for: override)
        }
        guard let openedAt, let days = daysAfterOpening, days > 0 else { return nil }
        return calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: openedAt))
    }

    /// Wcześniejszy z dwóch terminów: tego z opakowania i tego liczonego od otwarcia.
    static func effectiveExpiry(
        packageExpiry: Date,
        isOpened: Bool,
        openedAt: Date?,
        daysAfterOpening: Int?,
        openedExpiryOverride: Date?,
        calendar: Calendar = .current
    ) -> Date {
        let package = calendar.startOfDay(for: packageExpiry)
        guard isOpened,
              let opened = openedExpiry(
                openedAt: openedAt,
                daysAfterOpening: daysAfterOpening,
                override: openedExpiryOverride,
                calendar: calendar)
        else { return package }
        return min(package, opened)
    }

    /// Liczba pełnych dni dzielących dziś od podanego terminu.
    /// Wartość ujemna oznacza, że termin już minął.
    static func daysRemaining(
        until expiry: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: expiry)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    static func status(
        effectiveExpiry: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> MedicineStatus {
        let days = daysRemaining(until: effectiveExpiry, now: now, calendar: calendar)
        if days < 0 { return .expired }
        if days <= MedicineStatus.soonThresholdInDays { return .expiringSoon }
        return .valid
    }

    /// Granica używana w zapytaniach SwiftData: wszystko wcześniejsze jest po terminie.
    static func startOfToday(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    /// Granica sekcji "wkrótce wygasają".
    static func soonThresholdDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(
            byAdding: .day,
            value: MedicineStatus.soonThresholdInDays,
            to: calendar.startOfDay(for: now)
        ) ?? now
    }
}
