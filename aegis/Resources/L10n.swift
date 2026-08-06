//
//  L10n.swift
//  aegis
//

import Foundation

/// All interface copy in one place.
///
/// Keys are symbolic and independent of wording, so changing one language
/// variant does not invalidate the others.
nonisolated enum L10n {

    enum App {
        static let title = LocalizedStringResource(
            "app.title", defaultValue: "Domowa Apteczka",
            comment: "App name shown on the overview screen")
    }

    enum Common {
        static let cancel = LocalizedStringResource(
            "common.cancel", defaultValue: "Anuluj",
            comment: "Button that dismisses a sheet without saving")
        static let save = LocalizedStringResource(
            "common.save", defaultValue: "Zapisz",
            comment: "Button that saves the form")
        static let done = LocalizedStringResource(
            "common.done", defaultValue: "Gotowe",
            comment: "Button that dismisses an informational sheet")
        static let delete = LocalizedStringResource(
            "common.delete", defaultValue: "Usuń",
            comment: "Permanent delete action")
        static let edit = LocalizedStringResource(
            "common.edit", defaultValue: "Edytuj",
            comment: "Action that opens the edit form")
        static let notProvided = LocalizedStringResource(
            "common.not_provided", defaultValue: "Nie podano",
            comment: "Placeholder for an empty field in medicine details")
    }

    enum Tab {
        static let overview = LocalizedStringResource(
            "tab.overview", defaultValue: "Przegląd",
            comment: "Tab with the cabinet overview")
        static let medicines = LocalizedStringResource(
            "tab.medicines", defaultValue: "Leki",
            comment: "Tab with the full medicine list")
        static let archive = LocalizedStringResource(
            "tab.archive", defaultValue: "Archiwum",
            comment: "Tab with medicine history")
    }

    enum Dashboard {
        static let subtitle = LocalizedStringResource(
            "dashboard.subtitle", defaultValue: "Sprawdź stan swojej domowej apteczki",
            comment: "Subtitle on the overview screen")

        static let statActiveTitle = LocalizedStringResource(
            "dashboard.stat.active.title", defaultValue: "Aktywne leki",
            comment: "Title of the tile with the cabinet medicine count")
        static let statActiveCaption = LocalizedStringResource(
            "dashboard.stat.active.caption", defaultValue: "leki dostępne w domu",
            comment: "Caption under the active medicine count")
        static let statOpenedTitle = LocalizedStringResource(
            "dashboard.stat.opened.title", defaultValue: "Otwarte",
            comment: "Title of the tile with the opened-package count")
        static let statOpenedCaption = LocalizedStringResource(
            "dashboard.stat.opened.caption", defaultValue: "opakowania otwarte",
            comment: "Caption under the opened-package count")
        static let statExpiringTitle = LocalizedStringResource(
            "dashboard.stat.expiring.title", defaultValue: "Wkrótce wygasają",
            comment: "Title of the tile with medicines nearing expiry")
        static let statExpiringCaption = LocalizedStringResource(
            "dashboard.stat.expiring.caption", defaultValue: "w ciągu najbliższych 5 dni",
            comment: "Caption under the count of medicines nearing expiry")

        static let medicinesTitle = LocalizedStringResource(
            "dashboard.medicines.title", defaultValue: "Leki w domu",
            comment: "Header for the active medicines section")
        static let seeAll = LocalizedStringResource(
            "dashboard.medicines.see_all", defaultValue: "Zobacz wszystkie",
            comment: "Button that opens the full medicine list")
        static let emptyTitle = LocalizedStringResource(
            "dashboard.empty.title", defaultValue: "Dodaj pierwszy lek",
            comment: "Header for an empty cabinet")
        static let emptyMessage = LocalizedStringResource(
            "dashboard.empty.message",
            defaultValue: "Dane leku będą bezpiecznie zapisane i łatwe do znalezienia.",
            comment: "Description under the empty-cabinet header")

        static let attentionTitle = LocalizedStringResource(
            "dashboard.attention.title", defaultValue: "Wymagają uwagi",
            comment: "Header of the expired-medicines panel")
        static let attentionAllGood = LocalizedStringResource(
            "dashboard.attention.all_good",
            defaultValue: "Wszystkie leki mają aktualny termin ważności.",
            comment: "Message when nothing is expired")

        static func attentionCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "dashboard.attention.count",
                defaultValue: "\(count) leków jest przeterminowanych",
                comment: "Expired medicine count in the Needs attention panel")
        }
    }

    enum Medicines {
        static let title = LocalizedStringResource(
            "medicines.title", defaultValue: "Leki",
            comment: "Title of the medicine list screen")
        static let add = LocalizedStringResource(
            "medicines.add", defaultValue: "Dodaj lek",
            comment: "Action that opens the new-medicine form")
        static let searchPrompt = LocalizedStringResource(
            "medicines.search_prompt", defaultValue: "Szukaj leku, zastosowania lub osoby",
            comment: "Search field placeholder")
        static let emptyTitle = LocalizedStringResource(
            "medicines.empty.title", defaultValue: "Apteczka jest pusta",
            comment: "Header for an empty medicine list")
        static let emptyMessage = LocalizedStringResource(
            "medicines.empty.message",
            defaultValue: "Dodaj lek, aby mieć pod ręką termin ważności i dawkowanie.",
            comment: "Description for an empty medicine list")
        static let noResultsTitle = LocalizedStringResource(
            "medicines.no_results.title", defaultValue: "Brak wyników",
            comment: "Header when search finds nothing")
        static let noResultsMessage = LocalizedStringResource(
            "medicines.no_results.message",
            defaultValue: "Spróbuj innej nazwy, substancji czynnej lub imienia.",
            comment: "Description when search finds nothing")

        static let sectionExpired = LocalizedStringResource(
            "medicines.section.expired", defaultValue: "Przeterminowane",
            comment: "List section header for expired medicines")
        static let sectionExpiringSoon = LocalizedStringResource(
            "medicines.section.expiring_soon", defaultValue: "Wkrótce wygasają",
            comment: "List section header for medicines nearing expiry")
        static let sectionValid = LocalizedStringResource(
            "medicines.section.valid", defaultValue: "Aktualne",
            comment: "List section header for medicines still valid")

        static let sort = LocalizedStringResource(
            "medicines.sort", defaultValue: "Sortowanie",
            comment: "Menu for choosing list sort order")
        static let sortByExpiry = LocalizedStringResource(
            "medicines.sort.expiry", defaultValue: "Termin ważności",
            comment: "Sort the list by expiry date")
        static let sortByName = LocalizedStringResource(
            "medicines.sort.name", defaultValue: "Nazwa",
            comment: "Sort the list alphabetically")
        static let sortByPerson = LocalizedStringResource(
            "medicines.sort.person", defaultValue: "Osoba",
            comment: "Sort the list by person")
        static let deleteConfirmTitle = LocalizedStringResource(
            "medicines.delete.confirm.title", defaultValue: "Usunąć lek?",
            comment: "Confirm permanent delete from the active list (Free)")
        static let deleteConfirmMessage = LocalizedStringResource(
            "medicines.delete.confirm.message",
            defaultValue: "Lek zostanie trwale usunięty. W wersji Pro możesz zamiast tego przenieść go do archiwum.",
            comment: "Body of the delete confirmation when archive is unavailable")
    }

    enum Search {
        static func personToken(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.person", defaultValue: "Osoba: \(name)",
                comment: "Search token that narrows results to one person")
        }
        static func indicationToken(_ indication: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.indication", defaultValue: "Zastosowanie: \(indication)",
                comment: "Search token that narrows results to one indication")
        }
        static func substanceToken(_ substance: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.substance", defaultValue: "Substancja: \(substance)",
                comment: "Search token that narrows results to one active substance")
        }
    }

    enum Detail {
        static let substance = LocalizedStringResource(
            "detail.substance", defaultValue: "Substancja czynna",
            comment: "Label for the active substance field")
        static let person = LocalizedStringResource(
            "detail.person", defaultValue: "Na kogo przepisany",
            comment: "Label for the person the medicine was prescribed for")
        static let indication = LocalizedStringResource(
            "detail.indication", defaultValue: "Na co przepisany",
            comment: "Label for the indication field")
        static let dosage = LocalizedStringResource(
            "detail.dosage", defaultValue: "Dawkowanie",
            comment: "Label for the dosage field")
        static let quantity = LocalizedStringResource(
            "detail.quantity", defaultValue: "Ilość / opakowanie",
            comment: "Label for the package size field")
        static let form = LocalizedStringResource(
            "detail.form", defaultValue: "Postać",
            comment: "Label for the medicine form field")
        static let expiry = LocalizedStringResource(
            "detail.expiry", defaultValue: "Termin ważności",
            comment: "Label for the package expiry field")
        static let openedExpiry = LocalizedStringResource(
            "detail.opened_expiry", defaultValue: "Ważny po otwarciu do",
            comment: "Label for the post-opening expiry field")
        static let openedAt = LocalizedStringResource(
            "detail.opened_at", defaultValue: "Otwarty",
            comment: "Label for the package opening date field")
        static let notes = LocalizedStringResource(
            "detail.notes", defaultValue: "Notatki",
            comment: "Label for the notes field")
        static let added = LocalizedStringResource(
            "detail.added", defaultValue: "Dodany",
            comment: "Label for the date the medicine was added to the cabinet")
        static let effectiveExpiry = LocalizedStringResource(
            "detail.effective_expiry", defaultValue: "Obowiązujący termin",
            comment: "Label for the earlier of the two expiry dates")

        static let markOpened = LocalizedStringResource(
            "detail.mark_opened", defaultValue: "Oznacz jako otwarty",
            comment: "Action that records package opening")
        static let markUnopened = LocalizedStringResource(
            "detail.mark_unopened", defaultValue: "Oznacz jako nieotwarty",
            comment: "Action that clears the opened mark")
        static let archive = LocalizedStringResource(
            "detail.archive", defaultValue: "Przenieś do archiwum",
            comment: "Action that removes a medicine from the cabinet but keeps it in history")
        static let archiveTitle = LocalizedStringResource(
            "detail.archive.title", defaultValue: "Powód archiwizacji",
            comment: "Header asking why the medicine is being archived")
    }

    enum Form {
        static let titleNew = LocalizedStringResource(
            "form.title.new", defaultValue: "Nowy lek",
            comment: "Title of the add-medicine form")
        static let titleEdit = LocalizedStringResource(
            "form.title.edit", defaultValue: "Edycja leku",
            comment: "Title of the edit-medicine form")

        static let sectionMedicine = LocalizedStringResource(
            "form.section.medicine", defaultValue: "Lek",
            comment: "Section header for name and package")
        static let sectionPrescription = LocalizedStringResource(
            "form.section.prescription", defaultValue: "Recepta",
            comment: "Section header for person, indication, and dosage")
        static let sectionExpiry = LocalizedStringResource(
            "form.section.expiry", defaultValue: "Ważność",
            comment: "Section header for expiry dates")
        static let sectionNotes = LocalizedStringResource(
            "form.section.notes", defaultValue: "Notatki",
            comment: "Section header for extra notes")

        static let name = LocalizedStringResource(
            "form.name", defaultValue: "Nazwa leku",
            comment: "Label for the name field")
        static let namePrompt = LocalizedStringResource(
            "form.name.prompt", defaultValue: "np. Apap",
            comment: "Example value in the name field")
        static let substancePrompt = LocalizedStringResource(
            "form.substance.prompt", defaultValue: "np. paracetamol",
            comment: "Example value in the active substance field")
        static let quantityPrompt = LocalizedStringResource(
            "form.quantity.prompt", defaultValue: "np. 20 tabletek",
            comment: "Example value in the package size field")
        static let personPrompt = LocalizedStringResource(
            "form.person.prompt", defaultValue: "np. Ania",
            comment: "Example value in the person field")
        static let indicationPrompt = LocalizedStringResource(
            "form.indication.prompt", defaultValue: "np. ból głowy",
            comment: "Example value in the indication field")
        static let dosagePrompt = LocalizedStringResource(
            "form.dosage.prompt", defaultValue: "np. 1 tabletka co 8 godzin",
            comment: "Example value in the dosage field")
        static let notesPrompt = LocalizedStringResource(
            "form.notes.prompt", defaultValue: "Dodatkowe informacje",
            comment: "Example value in the notes field")

        static let opened = LocalizedStringResource(
            "form.opened", defaultValue: "Opakowanie otwarte",
            comment: "Toggle marking the package as opened")
        static let openedAt = LocalizedStringResource(
            "form.opened_at", defaultValue: "Data otwarcia",
            comment: "Label for choosing the opening date")
        static let daysAfterOpening = LocalizedStringResource(
            "form.days_after_opening", defaultValue: "Ważny po otwarciu",
            comment: "Label for days of usability after opening")
        static let useCustomDate = LocalizedStringResource(
            "form.use_custom_date", defaultValue: "Ustaw konkretną datę",
            comment: "Toggle that replaces the day count with a date picker")
        static let customDate = LocalizedStringResource(
            "form.custom_date", defaultValue: "Ważny po otwarciu do",
            comment: "Label for a manually chosen post-opening expiry date")
        static let suggestions = LocalizedStringResource(
            "form.suggestions", defaultValue: "Podpowiedzi",
            comment: "Header for previously entered value suggestions")

        static func days(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "form.days_value", defaultValue: "\(count) dni",
                comment: "Day count for usability after opening")
        }
    }

    enum Status {
        static let valid = LocalizedStringResource(
            "status.valid", defaultValue: "Aktualny",
            comment: "Badge for a medicine still within date")
        static let expiringSoon = LocalizedStringResource(
            "status.expiring_soon", defaultValue: "Wygasa wkrótce",
            comment: "Badge for a medicine nearing expiry")
        static let expired = LocalizedStringResource(
            "status.expired", defaultValue: "Przeterminowany",
            comment: "Badge for an expired medicine")
        static let opened = LocalizedStringResource(
            "status.opened", defaultValue: "Otwarty",
            comment: "Badge for an opened package")
        static let expiresToday = LocalizedStringResource(
            "status.expires_today", defaultValue: "Wygasa dziś",
            comment: "Description when expiry is today")

        static func expiresIn(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expires_in_days", defaultValue: "Wygasa za \(days) dni",
                comment: "Days remaining until expiry")
        }
        static func expiredAgo(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expired_days_ago", defaultValue: "Po terminie od \(days) dni",
                comment: "Days since the medicine expired")
        }
    }

    enum Archive {
        static let title = LocalizedStringResource(
            "archive.title", defaultValue: "Archiwum",
            comment: "Title of the medicine history screen")
        static let subtitle = LocalizedStringResource(
            "archive.subtitle", defaultValue: "Leki, które kiedyś były w apteczce",
            comment: "Subtitle of the archive screen")
        static let emptyTitle = LocalizedStringResource(
            "archive.empty.title", defaultValue: "Archiwum jest puste",
            comment: "Header for an empty archive")
        static let emptyMessage = LocalizedStringResource(
            "archive.empty.message",
            defaultValue: "Leki przeniesione do archiwum zostaną tu zapisane jako historia.",
            comment: "Description for an empty archive")
        static let searchPrompt = LocalizedStringResource(
            "archive.search_prompt", defaultValue: "Szukaj w archiwum",
            comment: "Archive search field placeholder")
        static let archivedAt = LocalizedStringResource(
            "archive.archived_at", defaultValue: "Zarchiwizowany",
            comment: "Label for the archive date")
        static let restore = LocalizedStringResource(
            "archive.restore", defaultValue: "Przywróć do apteczki",
            comment: "Action that restores a medicine from the archive")
        static let deleteConfirmTitle = LocalizedStringResource(
            "archive.delete.confirm.title", defaultValue: "Usunąć trwale?",
            comment: "Title of the permanent delete confirmation")
        static let deleteConfirmMessage = LocalizedStringResource(
            "archive.delete.confirm.message",
            defaultValue: "Lek zniknie z historii na wszystkich urządzeniach. Tej operacji nie można cofnąć.",
            comment: "Body of the permanent delete confirmation")
    }

    enum Expired {
        static let title = LocalizedStringResource(
            "expired.title", defaultValue: "Leki po terminie",
            comment: "Title of the sheet shown at app launch")
        static let archiveAll = LocalizedStringResource(
            "expired.archive_all", defaultValue: "Przenieś wszystkie do archiwum",
            comment: "Action that archives all expired medicines")
        static let deleteAll = LocalizedStringResource(
            "expired.delete_all", defaultValue: "Usuń wszystkie",
            comment: "Action that permanently deletes expired medicines on Free")
        static let archiveOne = LocalizedStringResource(
            "expired.archive_one", defaultValue: "Do archiwum",
            comment: "Action that archives a single medicine")
        static let later = LocalizedStringResource(
            "expired.later", defaultValue: "Nie teraz",
            comment: "Dismisses the sheet without archiving")
        static let footnote = LocalizedStringResource(
            "expired.footnote",
            defaultValue: "Zarchiwizowane leki znikają z apteczki, ale zostają w historii.",
            comment: "Explains that archiving does not delete data")

        static func message(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.message",
                defaultValue: "\(count) leków w Twojej apteczce straciło ważność.",
                comment: "Summary of the expired medicine count")
        }
        static func expiredOn(_ dateText: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.expired_on", defaultValue: "Termin minął \(dateText)",
                comment: "Expiry date in the expired-medicines sheet")
        }
    }

    enum Menu {
        static let newMedicine = LocalizedStringResource(
            "menu.new_medicine", defaultValue: "Nowy lek",
            comment: "Mac menu item that opens the form")
        static let search = LocalizedStringResource(
            "menu.search", defaultValue: "Szukaj",
            comment: "Mac menu item that focuses the search field")
    }

    enum Paywall {
        static let title = LocalizedStringResource(
            "paywall.title", defaultValue: "Aegis Pro",
            comment: "Title of the subscription sheet")
        static let headline = LocalizedStringResource(
            "paywall.headline", defaultValue: "Apteczka dla całej rodziny",
            comment: "Paywall headline")
        static let subtitle = LocalizedStringResource(
            "paywall.subtitle",
            defaultValue: "Synchronizacja iCloud, archiwum i wspólna apteczka przez Family Sharing.",
            comment: "Paywall subtitle")
        static let benefitSync = LocalizedStringResource(
            "paywall.benefit.sync", defaultValue: "Sync na iPhonie, iPadzie i Macu",
            comment: "Pro benefit: sync")
        static let benefitFamily = LocalizedStringResource(
            "paywall.benefit.family", defaultValue: "Wspólna apteczka w rodzinie",
            comment: "Pro benefit: sharing")
        static let benefitArchive = LocalizedStringResource(
            "paywall.benefit.archive", defaultValue: "Archiwum i przywracanie leków",
            comment: "Pro benefit: archive")
        static let restore = LocalizedStringResource(
            "paywall.restore", defaultValue: "Przywróć zakupy",
            comment: "Button to restore StoreKit purchases")
        static let debugUnlock = LocalizedStringResource(
            "paywall.debug_unlock", defaultValue: "Odblokuj Pro (debug)",
            comment: "Temporary Pro unlock in debug builds")
    }

    enum Settings {
        static let title = LocalizedStringResource(
            "settings.title", defaultValue: "Ustawienia",
            comment: "Title of the settings screen")
        static let subscriptionSection = LocalizedStringResource(
            "settings.subscription", defaultValue: "Subskrypcja",
            comment: "Pro status section")
        static let status = LocalizedStringResource(
            "settings.status", defaultValue: "Status",
            comment: "Subscription status label")
        static let statusFree = LocalizedStringResource(
            "settings.status.free", defaultValue: "Free",
            comment: "Status without a subscription")
        static let statusPro = LocalizedStringResource(
            "settings.status.pro", defaultValue: "Pro",
            comment: "Status with active Pro")
        static let upgrade = LocalizedStringResource(
            "settings.upgrade", defaultValue: "Przejdź na Pro",
            comment: "Button that opens the paywall")
        static let manageSubscription = LocalizedStringResource(
            "settings.manage", defaultValue: "Zarządzaj subskrypcją",
            comment: "Link to manage the subscription in the App Store")
        static let syncSection = LocalizedStringResource(
            "settings.sync", defaultValue: "Synchronizacja",
            comment: "iCloud status section")
        static let iCloudStatus = LocalizedStringResource(
            "settings.icloud.status", defaultValue: "Konto iCloud",
            comment: "iCloud account status label")
        static let iCloudAvailable = LocalizedStringResource(
            "settings.icloud.available", defaultValue: "Dostępne",
            comment: "iCloud available")
        static let iCloudNoAccount = LocalizedStringResource(
            "settings.icloud.no_account", defaultValue: "Brak konta",
            comment: "No signed-in iCloud account")
        static let iCloudRestricted = LocalizedStringResource(
            "settings.icloud.restricted", defaultValue: "Ograniczone",
            comment: "iCloud restricted")
        static let iCloudUnknown = LocalizedStringResource(
            "settings.icloud.unknown", defaultValue: "Nieznany",
            comment: "Unknown iCloud status")
        static let iCloudUnavailable = LocalizedStringResource(
            "settings.icloud.unavailable",
            defaultValue: "iCloud jest niedostępne na tym urządzeniu.",
            comment: "Message when sync cannot start")
        static let syncActive = LocalizedStringResource(
            "settings.sync.active", defaultValue: "Sync aktywny",
            comment: "CloudSync is running")
        static let syncInactive = LocalizedStringResource(
            "settings.sync.inactive", defaultValue: "Sync nieaktywny",
            comment: "CloudSync is off")
        static let syncNow = LocalizedStringResource(
            "settings.sync.now", defaultValue: "Synchronizuj teraz",
            comment: "Manual CloudKit refresh")
        static let sharingSection = LocalizedStringResource(
            "settings.sharing", defaultValue: "Rodzina",
            comment: "CKShare section")
        static let shareCabinet = LocalizedStringResource(
            "settings.share", defaultValue: "Udostępnij apteczkę",
            comment: "Button that opens CKShare")
        static let shareTitle = LocalizedStringResource(
            "settings.share.title", defaultValue: "Domowa apteczka",
            comment: "CKShare title")
        static let shareFootnote = LocalizedStringResource(
            "settings.share.footnote",
            defaultValue: "Zaproszeni członkowie rodziny zobaczą te same leki na swoich urządzeniach.",
            comment: "Explains sharing the medicine cabinet")
    }

    /// Notification keys are resolved only at delivery time
    /// (`NSString.localizedUserNotificationString`), so they are plain string constants here.
    enum NotificationKey {
        static let expiringTitle = "notification.expiring.title"
        static let expiredTitle = "notification.expired.title"
        static let bodyIn30Days = "notification.body.in_30_days"
        static let bodyIn7Days = "notification.body.in_7_days"
        static let bodyToday = "notification.body.today"
    }
}
