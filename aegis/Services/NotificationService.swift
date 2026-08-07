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
@MainActor
@Observable
final class NotificationService {
    static let shared = NotificationService()

    /// How many days before expiry we send a reminder.
    private static let leadTimesInDays = [30, 7, 0]

    /// Notification hour — morning, so there is time to react during the day.
    private static let notificationHour = 9

    private static let includeNameKey = "notifications.includeMedicineName"

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// When false (default), lock-screen bodies omit medicine names.
    private var includeMedicineName: Bool {
        UserDefaults.standard.bool(forKey: Self.includeNameKey)
    }

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
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
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
        // Clear stale badge counts from prior schedules.
        try? await center.setBadgeCount(0)

        let payloads = medicines
            .filter { !$0.isArchived }
            .map(NotificationPayload.init(medicine:))

        for payload in payloads {
            for request in requests(for: payload) {
                try? await center.add(request)
            }
        }
    }

    /// Reschedules reminders for one medicine after an edit or package opening.
    func reschedule(for medicine: Medicine) async {
        let payload = NotificationPayload(medicine: medicine)
        cancel(uuid: payload.uuid)
        guard !payload.isArchived, await requestAuthorizationIfNeeded() else { return }
        for request in requests(for: payload) {
            try? await center.add(request)
        }
    }

    func cancel(for medicine: Medicine) {
        cancel(uuid: medicine.uuid)
    }

    private func cancel(uuid: UUID) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }
        center.removePendingNotificationRequests(
            withIdentifiers: Self.leadTimesInDays.map { identifier(for: uuid, leadDays: $0) })
    }

    // MARK: - Details

    private struct NotificationPayload {
        let uuid: UUID
        let name: String
        let effectiveExpiryDate: Date
        let isArchived: Bool

        init(medicine: Medicine) {
            uuid = medicine.uuid
            name = medicine.name
            effectiveExpiryDate = medicine.effectiveExpiryDate
            isArchived = medicine.isArchived
        }
    }

    private func identifier(for uuid: UUID, leadDays: Int) -> String {
        "\(uuid.uuidString)-\(leadDays)"
    }

    private func requests(for payload: NotificationPayload) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let expiry = calendar.startOfDay(for: payload.effectiveExpiryDate)
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

            if includeMedicineName {
                content.body = NSString.localizedUserNotificationString(
                    forKey: bodyKey(leadDays: leadDays, private: false),
                    arguments: [payload.name])
            } else {
                content.body = NSString.localizedUserNotificationString(
                    forKey: bodyKey(leadDays: leadDays, private: true),
                    arguments: nil)
            }
            content.sound = .default
            content.interruptionLevel = leadDays == 0 ? .timeSensitive : .active

            return UNNotificationRequest(
                identifier: identifier(for: payload.uuid, leadDays: leadDays),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        }
    }

    private func bodyKey(leadDays: Int, private isPrivate: Bool) -> String {
        switch (leadDays, isPrivate) {
        case (30, false): L10n.NotificationKey.bodyIn30Days
        case (7, false): L10n.NotificationKey.bodyIn7Days
        case (_, false): L10n.NotificationKey.bodyToday
        case (30, true): L10n.NotificationKey.bodyIn30DaysPrivate
        case (7, true): L10n.NotificationKey.bodyIn7DaysPrivate
        case (_, true): L10n.NotificationKey.bodyTodayPrivate
        }
    }

    private func dateComponents(for day: Date, calendar: Calendar) -> DateComponents? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = Self.notificationHour
        components.minute = 0
        return components
    }
}
