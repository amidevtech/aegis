//
//  NotificationService.swift
//  aegis
//

import Foundation
import UserNotifications

/// Planuje lokalne przypomnienia o zbliżających się terminach ważności.
///
/// Treści są zapisywane jako klucze, a nie gotowe teksty - system tłumaczy je
/// dopiero przy dostarczeniu, więc powiadomienie zaplanowane pół roku temu
/// pojawi się w języku ustawionym dzisiaj.
@Observable
final class NotificationService {
    static let shared = NotificationService()

    /// Ile dni przed terminem wysyłamy przypomnienie.
    private static let leadTimesInDays = [30, 7, 0]

    /// Godzina powiadomienia - rano, żeby dało się zareagować w ciągu dnia.
    private static let notificationHour = 9

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Zgoda

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

    /// Pyta o zgodę tylko przy pierwszym użyciu. Zwraca `true`, gdy wolno planować.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
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

    // MARK: - Planowanie

    /// Przeplanowuje przypomnienia dla całej apteczki.
    ///
    /// Pełna synchronizacja zamiast księgowania pojedynczych zmian - jest odporna
    /// na rozjazd stanu po edycji na innym urządzeniu.
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

    /// Przeplanowuje przypomnienia jednego leku po edycji lub otwarciu opakowania.
    func reschedule(for medicine: Medicine) async {
        cancel(for: medicine)
        guard !medicine.isArchived, await requestAuthorizationIfNeeded() else { return }
        for request in requests(for: medicine) {
            try? await center.add(request)
        }
    }

    func cancel(for medicine: Medicine) {
        center.removePendingNotificationRequests(
            withIdentifiers: Self.leadTimesInDays.map { identifier(for: medicine, leadDays: $0) })
    }

    // MARK: - Szczegóły

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
