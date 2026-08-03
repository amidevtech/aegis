//
//  ExpiryCalculator.swift
//  aegis
//

import Foundation

/// Pure expiry-date logic — no SwiftData and no SwiftUI, so it can be tested
/// apart from the rest of the app.
///
/// All dates are normalized to the start of the day. A medicine dated "3 August"
/// stays valid through that whole day and expires only on 4 August.
nonisolated enum ExpiryCalculator {

    /// Expiry counted from the moment the package was opened.
    /// A manually chosen date takes priority over a day count.
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

    /// Earlier of the two dates: package expiry and post-opening expiry.
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

    /// Whole days between today and the given expiry.
    /// A negative value means the date has already passed.
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

    /// Boundary used in SwiftData queries: anything earlier is expired.
    static func startOfToday(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    /// Boundary for the "expiring soon" section.
    static func soonThresholdDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(
            byAdding: .day,
            value: MedicineStatus.soonThresholdInDays,
            to: calendar.startOfDay(for: now)
        ) ?? now
    }
}
