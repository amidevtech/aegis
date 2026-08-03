//
//  NotificationService.swift
//  aegis
//

import Foundation
import UserNotifications

/// Schedules local reminders for approaching expiry dates.
///
/// Bodies are stored as keys, not finished copy — the system localizes them
/// at delivery time, so a notification scheduled six months ago appears
/// in whichever language is set today.
@Observable
final class NotificationService {
    static let shared = NotificationService()

    /// How many days before expiry we send a reminder.
    private static let leadTimesInDays = [30, 7, 0]

    /// Notification hour — morning, so there is time to react during the day.
    private static let notificationHour = 9

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    private var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional: true
        default: false
        }
    }

    /// Asks for permission only on first use. Returns `true` when scheduling is allowed.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        // Unit tests should not trigger the system notification dialog.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return false
        }

        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            await refreshAuthorizationStatus()
            return granted
        default:
            return isAuthorized
        }
    }

    // MARK: - Scheduling

    /// Reschedules reminders for the whole cabinet.
    ///
    /// Full sync instead of bookkeeping individual changes — resilient to
    /// state drift after edits on another device.
    func sync(medicines: [Medicine]) async {
        await refreshAuthorizationStatus()
        guard isAuthorized else { return }

        center.removeAllPendingNotificationRequests()

        for medicine in medicines where !medicine.isArchived {
            for request in requests(for: medicine) {
                try? await center.add(request)
            }
        }
    }

    /// Reschedules reminders for one medicine after an edit or package opening.
    func reschedule(for medicine: Medicine) async {
        cancel(for: medicine)
        guard !medicine.isArchived, await requestAuthorizationIfNeeded() else { return }
        for request in requests(for: medicine) {
            try? await center.add(request)
        }
    }

    func cancel(for medicine: Medicine) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
        center.removePendingNotificationRequests(
            withIdentifiers: Self.leadTimesInDays.map { identifier(for: medicine, leadDays: $0) })
    }

    // MARK: - Details

    private func identifier(for medicine: Medicine, leadDays: Int) -> String {
        "\(medicine.uuid.uuidString)-\(leadDays)"
    }

    private func requests(for medicine: Medicine) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let expiry = calendar.startOfDay(for: medicine.effectiveExpiryDate)
        guard expiry < .distantFuture else { return [] }

        return Self.leadTimesInDays.compactMap { leadDays in
            guard let day = calendar.date(byAdding: .day, value: -leadDays, to: expiry),
                  var components = dateComponents(for: day, calendar: calendar),
                  let fireDate = calendar.date(from: components),
                  fireDate > .now
            else { return nil }

            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(
                forKey: leadDays == 0 ? L10n.NotificationKey.expiredTitle
                                      : L10n.NotificationKey.expiringTitle,
                arguments: nil)
            content.body = NSString.localizedUserNotificationString(
                forKey: bodyKey(leadDays: leadDays),
                arguments: [medicine.name])
            content.sound = .default
            content.interruptionLevel = leadDays == 0 ? .timeSensitive : .active

            return UNNotificationRequest(
                identifier: identifier(for: medicine, leadDays: leadDays),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        }
    }

    private func bodyKey(leadDays: Int) -> String {
        switch leadDays {
        case 30: L10n.NotificationKey.bodyIn30Days
        case 7: L10n.NotificationKey.bodyIn7Days
        default: L10n.NotificationKey.bodyToday
        }
    }

    private func dateComponents(for day: Date, calendar: Calendar) -> DateComponents? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = Self.notificationHour
        components.minute = 0
        return components
    }
}
