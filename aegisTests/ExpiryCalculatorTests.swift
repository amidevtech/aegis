//
//  ExpiryCalculatorTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

/// Testy liczenia terminów. Kalendarz jest przypięty do UTC, żeby wynik nie zależał
/// od strefy czasowej maszyny, na której lecą testy.
struct ExpiryCalculatorTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    @Test("Termin po otwarciu liczy się od daty otwarcia")
    func openedExpiryCountsFromOpeningDate() {
        let result = ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 30,
            override: nil,
            calendar: calendar)

        #expect(result == date(2026, 3, 31))
    }

    @Test("Ręcznie wybrana data ma pierwszeństwo przed liczbą dni")
    func overrideWinsOverDayCount() {
        let result = ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 30,
            override: date(2026, 4, 15),
            calendar: calendar)

        #expect(result == date(2026, 4, 15))
    }

    @Test("Bez daty otwarcia albo bez liczby dni nie ma terminu po otwarciu")
    func openedExpiryRequiresBothInputs() {
        #expect(ExpiryCalculator.openedExpiry(
            openedAt: nil, daysAfterOpening: 30, override: nil, calendar: calendar) == nil)
        #expect(ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1), daysAfterOpening: nil, override: nil,
            calendar: calendar) == nil)
        #expect(ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1), daysAfterOpening: 0, override: nil,
            calendar: calendar) == nil)
    }

    @Test("Obowiązuje wcześniejszy z dwóch terminów")
    func effectiveExpiryPicksEarlierDate() {
        let result = ExpiryCalculator.effectiveExpiry(
            packageExpiry: date(2027, 1, 1),
            isOpened: true,
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 14,
            openedExpiryOverride: nil,
            calendar: calendar)

        #expect(result == date(2026, 3, 15))
    }

    @Test("Gdy opakowanie kończy się wcześniej, otwarcie nic nie zmienia")
    func packageExpiryWinsWhenEarlier() {
        let result = ExpiryCalculator.effectiveExpiry(
            packageExpiry: date(2026, 3, 5),
            isOpened: true,
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 30,
            openedExpiryOverride: nil,
            calendar: calendar)

        #expect(result == date(2026, 3, 5))
    }

    @Test("Zamknięte opakowanie ignoruje ustawienia po otwarciu")
    func closedPackageIgnoresOpeningSettings() {
        let result = ExpiryCalculator.effectiveExpiry(
            packageExpiry: date(2027, 1, 1),
            isOpened: false,
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 14,
            openedExpiryOverride: nil,
            calendar: calendar)

        #expect(result == date(2027, 1, 1))
    }

    @Test("Lek jest ważny przez cały dzień widniejący na opakowaniu")
    func statusOnTheExpiryDayIsNotExpired() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.status(
            effectiveExpiry: today, now: today, calendar: calendar) == .expiringSoon)
        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 3, 9), now: today, calendar: calendar) == .expired)
    }

    @Test("Granica sekcji wkrótce wygasają to 30 dni")
    func statusThresholds() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 4, 9), now: today, calendar: calendar) == .expiringSoon)
        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 4, 10), now: today, calendar: calendar) == .valid)
    }

    @Test("Liczba dni po terminie jest ujemna")
    func daysRemainingGoesNegativeAfterExpiry() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 13), now: today, calendar: calendar) == 3)
        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 10), now: today, calendar: calendar) == 0)
        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 4), now: today, calendar: calendar) == -6)
    }

    @Test("Pora dnia nie wpływa na liczenie dni")
    func timeOfDayDoesNotAffectDayCount() {
        let morning = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 10, hour: 7)) ?? .distantPast
        let evening = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 12, hour: 23)) ?? .distantPast

        #expect(ExpiryCalculator.daysRemaining(
            until: evening, now: morning, calendar: calendar) == 2)
    }
}
