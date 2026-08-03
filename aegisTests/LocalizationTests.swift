//
//  LocalizationTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

/// Ensures every key has a translation. Without this, a missing entry
/// only shows up as a raw key on screen or in a notification.
struct LocalizationTests {

    private static let supportedLanguages = ["pl", "en"]

    /// Representative keys from each area of the app.
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
        "medicines.delete.confirm.title",
        "form.title.new",
        "form.opened",
        "detail.substance",
        "detail.archive",
        "archive.restore",
        "archive.delete.confirm.message",
        "archive_reason.used_up",
        "expired.title",
        "expired.footnote",
        "expired.delete_all",
        "paywall.title",
        "settings.title",
        "settings.share",
        "medicine_form.eye_drops",
        "status.expired",
        "menu.new_medicine"
    ]

    /// Notifications have no default value in code — the system resolves them
    /// at delivery time, so a missing entry would be visible to the user.
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
            "Missing \(language).lproj directory in the app bundle")
        return try #require(Bundle(path: path))
    }

    @Test("Each language has its own localization catalog", arguments: supportedLanguages)
    func languageBundleExists(language: String) throws {
        _ = try bundle(for: language)
    }

    @Test("Interface keys are translated in every language",
          arguments: supportedLanguages)
    func interfaceKeysAreTranslated(language: String) throws {
        let bundle = try bundle(for: language)

        for key in Self.sampledKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(value != key, "Missing \(language) translation for key \(key)")
            #expect(!value.isEmpty)
        }
    }

    @Test("Notification copy is translated in every language",
          arguments: supportedLanguages)
    func notificationKeysAreTranslated(language: String) throws {
        let bundle = try bundle(for: language)

        for key in Self.notificationKeys {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(value != key, "Missing \(language) translation for notification \(key)")
        }
    }

    @Test("Polish and English translations actually differ")
    func translationsDiffer() throws {
        let polish = try bundle(for: "pl")
        let english = try bundle(for: "en")

        for key in ["tab.overview", "medicines.add", "status.expired"] {
            let plValue = polish.localizedString(forKey: key, value: nil, table: "Localizable")
            let enValue = english.localizedString(forKey: key, value: nil, table: "Localizable")
            #expect(plValue != enValue, "Key \(key) has identical text in both languages")
        }
    }

    @Test("App display name is localized", arguments: supportedLanguages)
    func displayNameIsLocalized(language: String) throws {
        let bundle = try bundle(for: language)
        let value = bundle.localizedString(
            forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist")

        #expect(value != "CFBundleDisplayName")
        #expect(!value.isEmpty)
    }

    @Test("Polish plurals cover every plural form")
    func polishPluralsCoverEveryForm() throws {
        let polish = try bundle(for: "pl")
        let variants = [1, 2, 5, 22, 25].map { count in
            String.localizedStringWithFormat(
                polish.localizedString(
                    forKey: "status.expires_in_days", value: nil, table: "Localizable"),
                count)
        }

        #expect(variants[0].contains("dzień"), "expected singular for 1")
        #expect(variants[1].contains("dni"), "expected plural for 2")
        #expect(variants[2].contains("dni"), "expected plural for 5")
        #expect(variants[3].contains("dni"), "expected plural for 22")
        #expect(variants[4].contains("dni"), "expected plural for 25")
    }
}
