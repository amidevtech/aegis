//
//  L10n.swift
//  aegis
//

import Foundation

/// Wszystkie teksty interfejsu w jednym miejscu.
///
/// Klucze są symboliczne i niezależne od brzmienia tekstu, dzięki czemu zmiana
/// polskiego wariantu nie unieważnia pozostałych tłumaczeń. Wartości domyślne
/// są po polsku - to język źródłowy projektu.
nonisolated enum L10n {

    enum App {
        static let title = LocalizedStringResource(
            "app.title", defaultValue: "Domowa Apteczka",
            comment: "Nazwa aplikacji widoczna na ekranie przeglądu")
    }

    enum Common {
        static let cancel = LocalizedStringResource(
            "common.cancel", defaultValue: "Anuluj",
            comment: "Przycisk zamykający arkusz bez zapisywania")
        static let save = LocalizedStringResource(
            "common.save", defaultValue: "Zapisz",
            comment: "Przycisk zapisujący formularz")
        static let done = LocalizedStringResource(
            "common.done", defaultValue: "Gotowe",
            comment: "Przycisk zamykający arkusz informacyjny")
        static let delete = LocalizedStringResource(
            "common.delete", defaultValue: "Usuń",
            comment: "Akcja trwałego usunięcia")
        static let edit = LocalizedStringResource(
            "common.edit", defaultValue: "Edytuj",
            comment: "Akcja otwierająca formularz edycji")
        static let notProvided = LocalizedStringResource(
            "common.not_provided", defaultValue: "Nie podano",
            comment: "Zastępnik dla pustego pola w szczegółach leku")
    }

    enum Tab {
        static let overview = LocalizedStringResource(
            "tab.overview", defaultValue: "Przegląd",
            comment: "Zakładka z podsumowaniem apteczki")
        static let medicines = LocalizedStringResource(
            "tab.medicines", defaultValue: "Leki",
            comment: "Zakładka z listą wszystkich leków")
        static let archive = LocalizedStringResource(
            "tab.archive", defaultValue: "Archiwum",
            comment: "Zakładka z historią leków")
    }

    enum Dashboard {
        static let greetingMorning = LocalizedStringResource(
            "dashboard.greeting.morning", defaultValue: "Dzień dobry",
            comment: "Powitanie wyświetlane rano")
        static let greetingAfternoon = LocalizedStringResource(
            "dashboard.greeting.afternoon", defaultValue: "Dzień dobry",
            comment: "Powitanie wyświetlane po południu")
        static let greetingEvening = LocalizedStringResource(
            "dashboard.greeting.evening", defaultValue: "Dobry wieczór",
            comment: "Powitanie wyświetlane wieczorem")
        static let subtitle = LocalizedStringResource(
            "dashboard.subtitle", defaultValue: "Sprawdź stan swojej domowej apteczki",
            comment: "Podtytuł pod powitaniem na ekranie przeglądu")

        static let statActiveTitle = LocalizedStringResource(
            "dashboard.stat.active.title", defaultValue: "Aktywne leki",
            comment: "Tytuł kafelka z liczbą leków w apteczce")
        static let statActiveCaption = LocalizedStringResource(
            "dashboard.stat.active.caption", defaultValue: "leki dostępne w domu",
            comment: "Opis pod liczbą aktywnych leków")
        static let statOpenedTitle = LocalizedStringResource(
            "dashboard.stat.opened.title", defaultValue: "Otwarte",
            comment: "Tytuł kafelka z liczbą otwartych opakowań")
        static let statOpenedCaption = LocalizedStringResource(
            "dashboard.stat.opened.caption", defaultValue: "opakowania otwarte",
            comment: "Opis pod liczbą otwartych opakowań")
        static let statExpiringTitle = LocalizedStringResource(
            "dashboard.stat.expiring.title", defaultValue: "Wkrótce wygasają",
            comment: "Tytuł kafelka z liczbą leków bliskich przeterminowania")
        static let statExpiringCaption = LocalizedStringResource(
            "dashboard.stat.expiring.caption", defaultValue: "w ciągu najbliższych 30 dni",
            comment: "Opis pod liczbą leków bliskich przeterminowania")

        static let medicinesTitle = LocalizedStringResource(
            "dashboard.medicines.title", defaultValue: "Leki w domu",
            comment: "Nagłówek sekcji z aktywnymi lekami")
        static let seeAll = LocalizedStringResource(
            "dashboard.medicines.see_all", defaultValue: "Zobacz wszystkie",
            comment: "Przycisk przechodzący do pełnej listy leków")
        static let emptyTitle = LocalizedStringResource(
            "dashboard.empty.title", defaultValue: "Dodaj pierwszy lek",
            comment: "Nagłówek pustej apteczki")
        static let emptyMessage = LocalizedStringResource(
            "dashboard.empty.message",
            defaultValue: "Dane leku będą bezpiecznie zapisane i łatwe do znalezienia.",
            comment: "Opis pod nagłówkiem pustej apteczki")

        static let attentionTitle = LocalizedStringResource(
            "dashboard.attention.title", defaultValue: "Wymagają uwagi",
            comment: "Nagłówek panelu z lekami przeterminowanymi")
        static let attentionAllGood = LocalizedStringResource(
            "dashboard.attention.all_good",
            defaultValue: "Wszystkie leki mają aktualny termin ważności.",
            comment: "Komunikat, gdy nic nie jest przeterminowane")

        static func attentionCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "dashboard.attention.count",
                defaultValue: "\(count) leków jest przeterminowanych",
                comment: "Liczba przeterminowanych leków w panelu Wymagają uwagi")
        }
    }

    enum Medicines {
        static let title = LocalizedStringResource(
            "medicines.title", defaultValue: "Leki",
            comment: "Tytuł ekranu z listą leków")
        static let add = LocalizedStringResource(
            "medicines.add", defaultValue: "Dodaj lek",
            comment: "Akcja otwierająca formularz nowego leku")
        static let searchPrompt = LocalizedStringResource(
            "medicines.search_prompt", defaultValue: "Szukaj leku, zastosowania lub osoby",
            comment: "Podpowiedź w polu wyszukiwania")
        static let emptyTitle = LocalizedStringResource(
            "medicines.empty.title", defaultValue: "Apteczka jest pusta",
            comment: "Nagłówek pustej listy leków")
        static let emptyMessage = LocalizedStringResource(
            "medicines.empty.message",
            defaultValue: "Dodaj lek, aby mieć pod ręką termin ważności i dawkowanie.",
            comment: "Opis pustej listy leków")
        static let noResultsTitle = LocalizedStringResource(
            "medicines.no_results.title", defaultValue: "Brak wyników",
            comment: "Nagłówek, gdy wyszukiwanie nic nie znalazło")
        static let noResultsMessage = LocalizedStringResource(
            "medicines.no_results.message",
            defaultValue: "Spróbuj innej nazwy, substancji czynnej lub imienia.",
            comment: "Opis, gdy wyszukiwanie nic nie znalazło")

        static let sectionExpired = LocalizedStringResource(
            "medicines.section.expired", defaultValue: "Przeterminowane",
            comment: "Nagłówek sekcji listy z lekami po terminie")
        static let sectionExpiringSoon = LocalizedStringResource(
            "medicines.section.expiring_soon", defaultValue: "Wkrótce wygasają",
            comment: "Nagłówek sekcji listy z lekami bliskimi terminu")
        static let sectionValid = LocalizedStringResource(
            "medicines.section.valid", defaultValue: "Aktualne",
            comment: "Nagłówek sekcji listy z lekami w terminie")

        static let sort = LocalizedStringResource(
            "medicines.sort", defaultValue: "Sortowanie",
            comment: "Menu wyboru kolejności listy")
        static let sortByExpiry = LocalizedStringResource(
            "medicines.sort.expiry", defaultValue: "Termin ważności",
            comment: "Sortowanie listy według terminu ważności")
        static let sortByName = LocalizedStringResource(
            "medicines.sort.name", defaultValue: "Nazwa",
            comment: "Sortowanie listy alfabetycznie")
        static let sortByPerson = LocalizedStringResource(
            "medicines.sort.person", defaultValue: "Osoba",
            comment: "Sortowanie listy według osoby")
    }

    enum Search {
        static func personToken(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.person", defaultValue: "Osoba: \(name)",
                comment: "Token wyszukiwania zawężający wyniki do jednej osoby")
        }
        static func indicationToken(_ indication: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.indication", defaultValue: "Zastosowanie: \(indication)",
                comment: "Token wyszukiwania zawężający wyniki do jednej dolegliwości")
        }
        static func substanceToken(_ substance: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.substance", defaultValue: "Substancja: \(substance)",
                comment: "Token wyszukiwania zawężający wyniki do jednej substancji czynnej")
        }
    }

    enum Detail {
        static let substance = LocalizedStringResource(
            "detail.substance", defaultValue: "Substancja czynna",
            comment: "Etykieta pola z substancją czynną")
        static let person = LocalizedStringResource(
            "detail.person", defaultValue: "Na kogo przepisany",
            comment: "Etykieta pola z osobą, dla której lek przepisano")
        static let indication = LocalizedStringResource(
            "detail.indication", defaultValue: "Na co przepisany",
            comment: "Etykieta pola z dolegliwością")
        static let dosage = LocalizedStringResource(
            "detail.dosage", defaultValue: "Dawkowanie",
            comment: "Etykieta pola z dawkowaniem")
        static let quantity = LocalizedStringResource(
            "detail.quantity", defaultValue: "Ilość / opakowanie",
            comment: "Etykieta pola z wielkością opakowania")
        static let form = LocalizedStringResource(
            "detail.form", defaultValue: "Postać",
            comment: "Etykieta pola z postacią leku")
        static let expiry = LocalizedStringResource(
            "detail.expiry", defaultValue: "Termin ważności",
            comment: "Etykieta pola z terminem z opakowania")
        static let openedExpiry = LocalizedStringResource(
            "detail.opened_expiry", defaultValue: "Ważny po otwarciu do",
            comment: "Etykieta pola z terminem liczonym od otwarcia")
        static let openedAt = LocalizedStringResource(
            "detail.opened_at", defaultValue: "Otwarty",
            comment: "Etykieta pola z datą otwarcia opakowania")
        static let notes = LocalizedStringResource(
            "detail.notes", defaultValue: "Notatki",
            comment: "Etykieta pola z notatkami")
        static let added = LocalizedStringResource(
            "detail.added", defaultValue: "Dodany",
            comment: "Etykieta pola z datą dodania leku do apteczki")
        static let effectiveExpiry = LocalizedStringResource(
            "detail.effective_expiry", defaultValue: "Obowiązujący termin",
            comment: "Etykieta wcześniejszego z dwóch terminów ważności")

        static let markOpened = LocalizedStringResource(
            "detail.mark_opened", defaultValue: "Oznacz jako otwarty",
            comment: "Akcja odnotowująca otwarcie opakowania")
        static let markUnopened = LocalizedStringResource(
            "detail.mark_unopened", defaultValue: "Oznacz jako nieotwarty",
            comment: "Akcja cofająca oznaczenie otwarcia")
        static let archive = LocalizedStringResource(
            "detail.archive", defaultValue: "Przenieś do archiwum",
            comment: "Akcja usuwająca lek z apteczki, ale zachowująca go w historii")
        static let archiveTitle = LocalizedStringResource(
            "detail.archive.title", defaultValue: "Powód archiwizacji",
            comment: "Nagłówek pytania o powód przeniesienia leku do archiwum")
    }

    enum Form {
        static let titleNew = LocalizedStringResource(
            "form.title.new", defaultValue: "Nowy lek",
            comment: "Tytuł formularza dodawania leku")
        static let titleEdit = LocalizedStringResource(
            "form.title.edit", defaultValue: "Edycja leku",
            comment: "Tytuł formularza edycji leku")

        static let sectionMedicine = LocalizedStringResource(
            "form.section.medicine", defaultValue: "Lek",
            comment: "Nagłówek sekcji z nazwą i opakowaniem")
        static let sectionPrescription = LocalizedStringResource(
            "form.section.prescription", defaultValue: "Recepta",
            comment: "Nagłówek sekcji z osobą, dolegliwością i dawkowaniem")
        static let sectionExpiry = LocalizedStringResource(
            "form.section.expiry", defaultValue: "Ważność",
            comment: "Nagłówek sekcji z terminami ważności")
        static let sectionNotes = LocalizedStringResource(
            "form.section.notes", defaultValue: "Notatki",
            comment: "Nagłówek sekcji z dodatkowymi uwagami")

        static let name = LocalizedStringResource(
            "form.name", defaultValue: "Nazwa leku",
            comment: "Etykieta pola nazwy")
        static let namePrompt = LocalizedStringResource(
            "form.name.prompt", defaultValue: "np. Apap",
            comment: "Przykładowa wartość w polu nazwy")
        static let substancePrompt = LocalizedStringResource(
            "form.substance.prompt", defaultValue: "np. paracetamol",
            comment: "Przykładowa wartość w polu substancji czynnej")
        static let quantityPrompt = LocalizedStringResource(
            "form.quantity.prompt", defaultValue: "np. 20 tabletek",
            comment: "Przykładowa wartość w polu wielkości opakowania")
        static let personPrompt = LocalizedStringResource(
            "form.person.prompt", defaultValue: "np. Ania",
            comment: "Przykładowa wartość w polu osoby")
        static let indicationPrompt = LocalizedStringResource(
            "form.indication.prompt", defaultValue: "np. ból głowy",
            comment: "Przykładowa wartość w polu dolegliwości")
        static let dosagePrompt = LocalizedStringResource(
            "form.dosage.prompt", defaultValue: "np. 1 tabletka co 8 godzin",
            comment: "Przykładowa wartość w polu dawkowania")
        static let notesPrompt = LocalizedStringResource(
            "form.notes.prompt", defaultValue: "Dodatkowe informacje",
            comment: "Przykładowa wartość w polu notatek")

        static let opened = LocalizedStringResource(
            "form.opened", defaultValue: "Opakowanie otwarte",
            comment: "Przełącznik oznaczający otwarte opakowanie")
        static let openedAt = LocalizedStringResource(
            "form.opened_at", defaultValue: "Data otwarcia",
            comment: "Etykieta wyboru daty otwarcia")
        static let daysAfterOpening = LocalizedStringResource(
            "form.days_after_opening", defaultValue: "Ważny po otwarciu",
            comment: "Etykieta liczby dni przydatności po otwarciu")
        static let useCustomDate = LocalizedStringResource(
            "form.use_custom_date", defaultValue: "Ustaw konkretną datę",
            comment: "Przełącznik zastępujący liczbę dni wyborem daty")
        static let customDate = LocalizedStringResource(
            "form.custom_date", defaultValue: "Ważny po otwarciu do",
            comment: "Etykieta ręcznie wybranej daty ważności po otwarciu")
        static let suggestions = LocalizedStringResource(
            "form.suggestions", defaultValue: "Podpowiedzi",
            comment: "Nagłówek listy wcześniej wpisanych wartości")

        static func days(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "form.days_value", defaultValue: "\(count) dni",
                comment: "Liczba dni przydatności po otwarciu")
        }
    }

    enum Status {
        static let valid = LocalizedStringResource(
            "status.valid", defaultValue: "Aktualny",
            comment: "Znacznik leku w terminie")
        static let expiringSoon = LocalizedStringResource(
            "status.expiring_soon", defaultValue: "Wygasa wkrótce",
            comment: "Znacznik leku bliskiego przeterminowania")
        static let expired = LocalizedStringResource(
            "status.expired", defaultValue: "Przeterminowany",
            comment: "Znacznik leku po terminie")
        static let opened = LocalizedStringResource(
            "status.opened", defaultValue: "Otwarty",
            comment: "Znacznik otwartego opakowania")
        static let expiresToday = LocalizedStringResource(
            "status.expires_today", defaultValue: "Wygasa dziś",
            comment: "Opis terminu upływającego dzisiaj")

        static func expiresIn(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expires_in_days", defaultValue: "Wygasa za \(days) dni",
                comment: "Liczba dni pozostałych do końca ważności")
        }
        static func expiredAgo(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expired_days_ago", defaultValue: "Po terminie od \(days) dni",
                comment: "Liczba dni, które minęły od utraty ważności")
        }
    }

    enum Archive {
        static let title = LocalizedStringResource(
            "archive.title", defaultValue: "Archiwum",
            comment: "Tytuł ekranu z historią leków")
        static let subtitle = LocalizedStringResource(
            "archive.subtitle", defaultValue: "Leki, które kiedyś były w apteczce",
            comment: "Podtytuł ekranu archiwum")
        static let emptyTitle = LocalizedStringResource(
            "archive.empty.title", defaultValue: "Archiwum jest puste",
            comment: "Nagłówek pustego archiwum")
        static let emptyMessage = LocalizedStringResource(
            "archive.empty.message",
            defaultValue: "Leki przeniesione do archiwum zostaną tu zapisane jako historia.",
            comment: "Opis pustego archiwum")
        static let searchPrompt = LocalizedStringResource(
            "archive.search_prompt", defaultValue: "Szukaj w archiwum",
            comment: "Podpowiedź w polu wyszukiwania archiwum")
        static let archivedAt = LocalizedStringResource(
            "archive.archived_at", defaultValue: "Zarchiwizowany",
            comment: "Etykieta daty przeniesienia do archiwum")
        static let restore = LocalizedStringResource(
            "archive.restore", defaultValue: "Przywróć do apteczki",
            comment: "Akcja przywracająca lek z archiwum")
        static let deleteConfirmTitle = LocalizedStringResource(
            "archive.delete.confirm.title", defaultValue: "Usunąć trwale?",
            comment: "Tytuł potwierdzenia trwałego usunięcia")
        static let deleteConfirmMessage = LocalizedStringResource(
            "archive.delete.confirm.message",
            defaultValue: "Lek zniknie z historii na wszystkich urządzeniach. Tej operacji nie można cofnąć.",
            comment: "Treść potwierdzenia trwałego usunięcia")
    }

    enum Expired {
        static let title = LocalizedStringResource(
            "expired.title", defaultValue: "Leki po terminie",
            comment: "Tytuł arkusza pokazywanego przy starcie aplikacji")
        static let archiveAll = LocalizedStringResource(
            "expired.archive_all", defaultValue: "Przenieś wszystkie do archiwum",
            comment: "Akcja archiwizująca wszystkie przeterminowane leki")
        static let archiveOne = LocalizedStringResource(
            "expired.archive_one", defaultValue: "Do archiwum",
            comment: "Akcja archiwizująca pojedynczy lek")
        static let later = LocalizedStringResource(
            "expired.later", defaultValue: "Nie teraz",
            comment: "Zamknięcie arkusza bez archiwizowania")
        static let footnote = LocalizedStringResource(
            "expired.footnote",
            defaultValue: "Zarchiwizowane leki znikają z apteczki, ale zostają w historii.",
            comment: "Wyjaśnienie, że archiwizacja nie kasuje danych")

        static func message(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.message",
                defaultValue: "\(count) leków w Twojej apteczce straciło ważność.",
                comment: "Podsumowanie liczby przeterminowanych leków")
        }
        static func expiredOn(_ dateText: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.expired_on", defaultValue: "Termin minął \(dateText)",
                comment: "Data utraty ważności w arkuszu przeterminowanych leków")
        }
    }

    enum Menu {
        static let newMedicine = LocalizedStringResource(
            "menu.new_medicine", defaultValue: "Nowy lek",
            comment: "Pozycja menu na Macu otwierająca formularz")
        static let search = LocalizedStringResource(
            "menu.search", defaultValue: "Szukaj",
            comment: "Pozycja menu na Macu ustawiająca kursor w wyszukiwarce")
    }

    /// Klucze powiadomień są rozwiązywane dopiero w chwili dostarczenia
    /// (`NSString.localizedUserNotificationString`), dlatego są tu tylko stałymi tekstowymi.
    enum NotificationKey {
        static let expiringTitle = "notification.expiring.title"
        static let expiredTitle = "notification.expired.title"
        static let bodyIn30Days = "notification.body.in_30_days"
        static let bodyIn7Days = "notification.body.in_7_days"
        static let bodyToday = "notification.body.today"
    }
}
