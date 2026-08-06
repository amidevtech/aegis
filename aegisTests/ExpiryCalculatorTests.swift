//
//  ExpiryCalculatorTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

/// Expiry calculation tests. The calendar is pinned to UTC so results do not
/// depend on the timezone of the machine running the tests.
struct ExpiryCalculatorTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    @Test("Post-opening expiry is counted from the opening date")
    func openedExpiryCountsFromOpeningDate() {
        let result = ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 30,
            override: nil,
            calendar: calendar)

        #expect(result == date(2026, 3, 31))
    }

    @Test("A manually chosen date takes priority over the day count")
    func overrideWinsOverDayCount() {
        let result = ExpiryCalculator.openedExpiry(
            openedAt: date(2026, 3, 1),
            daysAfterOpening: 30,
            override: date(2026, 4, 15),
            calendar: calendar)

        #expect(result == date(2026, 4, 15))
    }

    @Test("Without an opening date or day count there is no post-opening expiry")
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

    @Test("The earlier of the two dates is effective")
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

    @Test("When the package expires sooner, opening does not change anything")
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

    @Test("A closed package ignores post-opening settings")
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

    @Test("A medicine stays valid through the whole day printed on the package")
    func statusOnTheExpiryDayIsNotExpired() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.status(
            effectiveExpiry: today, now: today, calendar: calendar) == .expiringSoon)
        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 3, 9), now: today, calendar: calendar) == .expired)
    }

    @Test("The expiring-soon section boundary is 5 days")
    func statusThresholds() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 3, 15), now: today, calendar: calendar) == .expiringSoon)
        #expect(ExpiryCalculator.status(
            effectiveExpiry: date(2026, 3, 16), now: today, calendar: calendar) == .valid)
    }

    @Test("Days remaining is negative after expiry")
    func daysRemainingGoesNegativeAfterExpiry() {
        let today = date(2026, 3, 10)

        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 13), now: today, calendar: calendar) == 3)
        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 10), now: today, calendar: calendar) == 0)
        #expect(ExpiryCalculator.daysRemaining(
            until: date(2026, 3, 4), now: today, calendar: calendar) == -6)
    }

    @Test("Time of day does not affect the day count")
    func timeOfDayDoesNotAffectDayCount() {
        let morning = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 10, hour: 7)) ?? .distantPast
        let evening = calendar.date(
            from: DateComponents(year: 2026, month: 3, day: 12, hour: 23)) ?? .distantPast

        #expect(ExpiryCalculator.daysRemaining(
            until: evening, now: morning, calendar: calendar) == 2)
    }
}
