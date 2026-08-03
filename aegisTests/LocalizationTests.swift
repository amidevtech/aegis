//
//  LocalizationTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

/// Pilnuje, żeby żaden klucz nie został bez tłumaczenia. Bez tego brakujący wpis
/// objawia się dopiero surowym kluczem na ekranie albo w powiadomieniu.
struct LocalizationTests {

    private static let supportedLanguages = ["pl", "en"]

    /// Reprezentatywne klucze z każdego obszaru aplikacji.
    private static let sampledKeys = [
        "app.title",
        "tab.overview",
        "tab.medicines",
        "tab.archive",
        "dashboard.subtitle",
        "dashboard.attention.title",
        "medicines.add",
        "medicines.search_prompt",
        "medicines.section.expired",
        "form.title.new",
        "form.opened",
        "detail.substance",
        "detail.archive",
        "archive.restore",
        "archive.delete.confirm.message",
        "archive_reason.used_up",
        "expired.title",
        "expired.footnote",
        "medicine_form.eye_drops",
        "status.expired",
        "menu.new_medicine"
    ]

    /// Powiadomienia nie mają wartości domyślnej w kodzie - system rozwiązuje je
    /// dopiero przy dostarczeniu, więc brak wpisu byłby widoczny dla użytkownika.
    private static let notificationKeys = [
        L10n.NotificationKey.expiringTitle,
        L10n.NotificationKey.expiredTitle,
        L10n.NotificationKey.bodyIn30Days,
        L10n.NotificationKey.bodyIn7Days,
        L10n.NotificationKey.bodyToday
    ]

    private func bundle(for language: String) throws -> Bundle {
        let path = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "Brak katalogu \(language).lproj w pakiecie aplikacji")
        return try #require(Bundle(path: path))
    }

    @Test("Każdy język ma własny katalog tłumaczeń", arguments: supportedLanguages)
    func languageBundleExists(language: String) throws {
        _ = try bundle(for: language)
    }

    @Test("Klucze interfejsu są przetłumaczone we wszystkich językach",
          arguments: supportedLanguages)
    func interfaceKeysAreTranslated(language: String) throws {
        let bundle = try bundle(for: language)

        for key in Self.sampledKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(value != key, "Brak tłumaczenia \(language) dla klucza \(key)")
            #expect(!value.isEmpty)
        }
    }

    @Test("Teksty powiadomień są przetłumaczone we wszystkich językach",
          arguments: supportedLanguages)
    func notificationKeysAreTranslated(language: String) throws {
        let bundle = try bundle(for: language)

        for key in Self.notificationKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(value != key, "Brak tłumaczenia \(language) dla powiadomienia \(key)")
        }
    }

    @Test("Polski i angielski faktycznie się różnią")
    func translationsDiffer() throws {
        let polish = try bundle(for: "pl")
        let english = try bundle(for: "en")

        for key in ["tab.overview", "medicines.add", "status.expired"] {
            let plValue = polish.localizedString(forKey: key, value: nil, table: "Localizable")
            let enValue = english.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(plValue != enValue, "Klucz \(key) ma identyczny tekst w obu językach")
        }
    }

    @Test("Nazwa aplikacji jest zlokalizowana", arguments: supportedLanguages)
    func displayNameIsLocalized(language: String) throws {
        let bundle = try bundle(for: language)
        let value = bundle.localizedString(
            forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist")

        #expect(value != "CFBundleDisplayName")
        #expect(!value.isEmpty)
    }

    @Test("Polskie liczniki mają wszystkie formy liczby mnogiej")
    func polishPluralsCoverEveryForm() throws {
        let polish = try bundle(for: "pl")
        let variants = [1, 2, 5, 22, 25].map { count in
            String.localizedStringWithFormat(
                polish.localizedString(
                    forKey: "status.expires_in_days", value: nil, table: "Localizable"),
                count)
        }

        #expect(variants[0].contains("dzień"), "1 dzień")
        #expect(variants[1].contains("dni"), "2 dni")
        #expect(variants[2].contains("dni"), "5 dni")
        #expect(variants[3].contains("dni"), "22 dni")
        #expect(variants[4].contains("dni"), "25 dni")
    }
}
