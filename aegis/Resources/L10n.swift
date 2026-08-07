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
            "app.title", defaultValue: "Home Medicine Cabinet",
            comment: "App name shown on the overview screen")
    }

    enum Common {
        static let cancel = LocalizedStringResource(
            "common.cancel", defaultValue: "Cancel",
            comment: "Button that dismisses a sheet without saving")
        static let save = LocalizedStringResource(
            "common.save", defaultValue: "Save",
            comment: "Button that saves the form")
        static let done = LocalizedStringResource(
            "common.done", defaultValue: "Done",
            comment: "Button that dismisses an informational sheet")
        static let delete = LocalizedStringResource(
            "common.delete", defaultValue: "Delete",
            comment: "Permanent delete action")
        static let edit = LocalizedStringResource(
            "common.edit", defaultValue: "Edit",
            comment: "Action that opens the edit form")
        static let notProvided = LocalizedStringResource(
            "common.not_provided", defaultValue: "Not provided",
            comment: "Placeholder for an empty field in medicine details")
    }

    enum Tab {
        static let overview = LocalizedStringResource(
            "tab.overview", defaultValue: "Overview",
            comment: "Tab with the cabinet overview")
        static let medicines = LocalizedStringResource(
            "tab.medicines", defaultValue: "Medicines",
            comment: "Tab with the full medicine list")
        static let archive = LocalizedStringResource(
            "tab.archive", defaultValue: "Archive",
            comment: "Tab with medicine history")
    }

    enum Dashboard {
        static let subtitle = LocalizedStringResource(
            "dashboard.subtitle", defaultValue: "Check what is in your medicine cabinet",
            comment: "Subtitle on the overview screen")

        static let statActiveTitle = LocalizedStringResource(
            "dashboard.stat.active.title", defaultValue: "Active medicines",
            comment: "Title of the tile with the cabinet medicine count")
        static let statActiveCaption = LocalizedStringResource(
            "dashboard.stat.active.caption", defaultValue: "available at home",
            comment: "Caption under the active medicine count")
        static let statOpenedTitle = LocalizedStringResource(
            "dashboard.stat.opened.title", defaultValue: "Opened",
            comment: "Title of the tile with the opened-package count")
        static let statOpenedCaption = LocalizedStringResource(
            "dashboard.stat.opened.caption", defaultValue: "packages opened",
            comment: "Caption under the opened-package count")
        static let statExpiringTitle = LocalizedStringResource(
            "dashboard.stat.expiring.title", defaultValue: "Expiring soon",
            comment: "Title of the tile with medicines nearing expiry")
        static let statExpiringCaption = LocalizedStringResource(
            "dashboard.stat.expiring.caption", defaultValue: "within the next 5 days",
            comment: "Caption under the count of medicines nearing expiry")

        static let medicinesTitle = LocalizedStringResource(
            "dashboard.medicines.title", defaultValue: "Medicines at home",
            comment: "Header for the active medicines section")
        static let seeAll = LocalizedStringResource(
            "dashboard.medicines.see_all", defaultValue: "See all",
            comment: "Button that opens the full medicine list")
        static let emptyTitle = LocalizedStringResource(
            "dashboard.empty.title", defaultValue: "Add your first medicine",
            comment: "Header for an empty cabinet")
        static let emptyMessage = LocalizedStringResource(
            "dashboard.empty.message",
            defaultValue: "Details are stored safely and stay easy to find.",
            comment: "Description under the empty-cabinet header")

        static let attentionTitle = LocalizedStringResource(
            "dashboard.attention.title", defaultValue: "Needs attention",
            comment: "Header of the expired-medicines panel")
        static let attentionAllGood = LocalizedStringResource(
            "dashboard.attention.all_good",
            defaultValue: "Every medicine is within its expiry date.",
            comment: "Message when nothing is expired")

        static func attentionCount(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "dashboard.attention.count",
                defaultValue: "\(count) medicines are expired",
                comment: "Expired medicine count in the Needs attention panel")
        }
    }

    enum Medicines {
        static let title = LocalizedStringResource(
            "medicines.title", defaultValue: "Medicines",
            comment: "Title of the medicine list screen")
        static let add = LocalizedStringResource(
            "medicines.add", defaultValue: "Add medicine",
            comment: "Action that opens the new-medicine form")
        static let searchPrompt = LocalizedStringResource(
            "medicines.search_prompt", defaultValue: "Search by medicine, use or person",
            comment: "Search field placeholder")
        static let emptyTitle = LocalizedStringResource(
            "medicines.empty.title", defaultValue: "Your cabinet is empty",
            comment: "Header for an empty medicine list")
        static let emptyMessage = LocalizedStringResource(
            "medicines.empty.message",
            defaultValue: "Add a medicine to keep its expiry date and dosage at hand.",
            comment: "Description for an empty medicine list")
        static let noResultsTitle = LocalizedStringResource(
            "medicines.no_results.title", defaultValue: "No results",
            comment: "Header when search finds nothing")
        static let noResultsMessage = LocalizedStringResource(
            "medicines.no_results.message",
            defaultValue: "Try a different name, active substance or person.",
            comment: "Description when search finds nothing")

        static let sectionExpired = LocalizedStringResource(
            "medicines.section.expired", defaultValue: "Expired",
            comment: "List section header for expired medicines")
        static let sectionExpiringSoon = LocalizedStringResource(
            "medicines.section.expiring_soon", defaultValue: "Expiring soon",
            comment: "List section header for medicines nearing expiry")
        static let sectionValid = LocalizedStringResource(
            "medicines.section.valid", defaultValue: "Valid",
            comment: "List section header for medicines still valid")

        static let sort = LocalizedStringResource(
            "medicines.sort", defaultValue: "Sort",
            comment: "Menu for choosing list sort order")
        static let sortByExpiry = LocalizedStringResource(
            "medicines.sort.expiry", defaultValue: "Expiry date",
            comment: "Sort the list by expiry date")
        static let sortByName = LocalizedStringResource(
            "medicines.sort.name", defaultValue: "Name",
            comment: "Sort the list alphabetically")
        static let sortByPerson = LocalizedStringResource(
            "medicines.sort.person", defaultValue: "Person",
            comment: "Sort the list by person")
        static let deleteConfirmTitle = LocalizedStringResource(
            "medicines.delete.confirm.title", defaultValue: "Delete medicine?",
            comment: "Confirm permanent delete from the active list (Free)")
        static let deleteConfirmMessage = LocalizedStringResource(
            "medicines.delete.confirm.message",
            defaultValue: "The medicine will be permanently deleted. With Pro you can move it to the archive instead.",
            comment: "Body of the delete confirmation when archive is unavailable")
    }

    enum Search {
        static func personToken(_ name: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.person", defaultValue: "Person: \(name)",
                comment: "Search token that narrows results to one person")
        }
        static func indicationToken(_ indication: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.indication", defaultValue: "Used for: \(indication)",
                comment: "Search token that narrows results to one indication")
        }
        static func substanceToken(_ substance: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "search.token.substance", defaultValue: "Substance: \(substance)",
                comment: "Search token that narrows results to one active substance")
        }
    }

    enum Detail {
        static let substance = LocalizedStringResource(
            "detail.substance", defaultValue: "Active substance",
            comment: "Label for the active substance field")
        static let person = LocalizedStringResource(
            "detail.person", defaultValue: "Prescribed for",
            comment: "Label for the person the medicine was prescribed for")
        static let indication = LocalizedStringResource(
            "detail.indication", defaultValue: "Prescribed to treat",
            comment: "Label for the indication field")
        static let dosage = LocalizedStringResource(
            "detail.dosage", defaultValue: "Dosage",
            comment: "Label for the dosage field")
        static let quantity = LocalizedStringResource(
            "detail.quantity", defaultValue: "Amount / package",
            comment: "Label for the package size field")
        static let form = LocalizedStringResource(
            "detail.form", defaultValue: "Form",
            comment: "Label for the medicine form field")
        static let expiry = LocalizedStringResource(
            "detail.expiry", defaultValue: "Expiry date",
            comment: "Label for the package expiry field")
        static let openedExpiry = LocalizedStringResource(
            "detail.opened_expiry", defaultValue: "Use by after opening",
            comment: "Label for the post-opening expiry field")
        static let openedAt = LocalizedStringResource(
            "detail.opened_at", defaultValue: "Opened",
            comment: "Label for the package opening date field")
        static let notes = LocalizedStringResource(
            "detail.notes", defaultValue: "Notes",
            comment: "Label for the notes field")
        static let added = LocalizedStringResource(
            "detail.added", defaultValue: "Added",
            comment: "Label for the date the medicine was added to the cabinet")
        static let effectiveExpiry = LocalizedStringResource(
            "detail.effective_expiry", defaultValue: "Effective date",
            comment: "Label for the earlier of the two expiry dates")

        static let markOpened = LocalizedStringResource(
            "detail.mark_opened", defaultValue: "Mark as opened",
            comment: "Action that records package opening")
        static let markUnopened = LocalizedStringResource(
            "detail.mark_unopened", defaultValue: "Mark as unopened",
            comment: "Action that clears the opened mark")
        static let archive = LocalizedStringResource(
            "detail.archive", defaultValue: "Move to archive",
            comment: "Action that removes a medicine from the cabinet but keeps it in history")
        static let archiveTitle = LocalizedStringResource(
            "detail.archive.title", defaultValue: "Reason for archiving",
            comment: "Header asking why the medicine is being archived")
    }

    enum Form {
        static let titleNew = LocalizedStringResource(
            "form.title.new", defaultValue: "New medicine",
            comment: "Title of the add-medicine form")
        static let titleEdit = LocalizedStringResource(
            "form.title.edit", defaultValue: "Edit medicine",
            comment: "Title of the edit-medicine form")

        static let sectionMedicine = LocalizedStringResource(
            "form.section.medicine", defaultValue: "Medicine",
            comment: "Section header for name and package")
        static let sectionPrescription = LocalizedStringResource(
            "form.section.prescription", defaultValue: "Prescription",
            comment: "Section header for person, indication, and dosage")
        static let sectionExpiry = LocalizedStringResource(
            "form.section.expiry", defaultValue: "Expiry",
            comment: "Section header for expiry dates")
        static let sectionNotes = LocalizedStringResource(
            "form.section.notes", defaultValue: "Notes",
            comment: "Section header for extra notes")

        static let name = LocalizedStringResource(
            "form.name", defaultValue: "Medicine name",
            comment: "Label for the name field")
        static let namePrompt = LocalizedStringResource(
            "form.name.prompt", defaultValue: "e.g. Panadol",
            comment: "Example value in the name field")
        static let substancePrompt = LocalizedStringResource(
            "form.substance.prompt", defaultValue: "e.g. paracetamol",
            comment: "Example value in the active substance field")
        static let quantityPrompt = LocalizedStringResource(
            "form.quantity.prompt", defaultValue: "e.g. 20 tablets",
            comment: "Example value in the package size field")
        static let personPrompt = LocalizedStringResource(
            "form.person.prompt", defaultValue: "e.g. Anna",
            comment: "Example value in the person field")
        static let indicationPrompt = LocalizedStringResource(
            "form.indication.prompt", defaultValue: "e.g. headache",
            comment: "Example value in the indication field")
        static let dosagePrompt = LocalizedStringResource(
            "form.dosage.prompt", defaultValue: "e.g. 1 tablet every 8 hours",
            comment: "Example value in the dosage field")
        static let notesPrompt = LocalizedStringResource(
            "form.notes.prompt", defaultValue: "Additional information",
            comment: "Example value in the notes field")

        static let opened = LocalizedStringResource(
            "form.opened", defaultValue: "Package opened",
            comment: "Toggle marking the package as opened")
        static let openedAt = LocalizedStringResource(
            "form.opened_at", defaultValue: "Opening date",
            comment: "Label for choosing the opening date")
        static let daysAfterOpening = LocalizedStringResource(
            "form.days_after_opening", defaultValue: "Use within",
            comment: "Label for days of usability after opening")
        static let useCustomDate = LocalizedStringResource(
            "form.use_custom_date", defaultValue: "Set a specific date",
            comment: "Toggle that replaces the day count with a date picker")
        static let customDate = LocalizedStringResource(
            "form.custom_date", defaultValue: "Use by after opening",
            comment: "Label for a manually chosen post-opening expiry date")
        static let suggestions = LocalizedStringResource(
            "form.suggestions", defaultValue: "Suggestions",
            comment: "Header for previously entered value suggestions")

        static func days(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "form.days_value", defaultValue: "\(count) days",
                comment: "Day count for usability after opening")
        }
    }

    enum Status {
        static let valid = LocalizedStringResource(
            "status.valid", defaultValue: "Valid",
            comment: "Badge for a medicine still within date")
        static let expiringSoon = LocalizedStringResource(
            "status.expiring_soon", defaultValue: "Expiring soon",
            comment: "Badge for a medicine nearing expiry")
        static let expired = LocalizedStringResource(
            "status.expired", defaultValue: "Expired",
            comment: "Badge for an expired medicine")
        static let opened = LocalizedStringResource(
            "status.opened", defaultValue: "Opened",
            comment: "Badge for an opened package")
        static let expiresToday = LocalizedStringResource(
            "status.expires_today", defaultValue: "Expires today",
            comment: "Description when expiry is today")

        static func expiresIn(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expires_in_days", defaultValue: "Expires in \(days) days",
                comment: "Days remaining until expiry")
        }
        static func expiredAgo(days: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "status.expired_days_ago", defaultValue: "Expired \(days) days ago",
                comment: "Days since the medicine expired")
        }
    }

    enum Archive {
        static let title = LocalizedStringResource(
            "archive.title", defaultValue: "Archive",
            comment: "Title of the medicine history screen")
        static let subtitle = LocalizedStringResource(
            "archive.subtitle", defaultValue: "Medicines that used to be in the cabinet",
            comment: "Subtitle of the archive screen")
        static let emptyTitle = LocalizedStringResource(
            "archive.empty.title", defaultValue: "The archive is empty",
            comment: "Header for an empty archive")
        static let emptyMessage = LocalizedStringResource(
            "archive.empty.message",
            defaultValue: "Medicines moved to the archive are kept here as history.",
            comment: "Description for an empty archive")
        static let searchPrompt = LocalizedStringResource(
            "archive.search_prompt", defaultValue: "Search the archive",
            comment: "Archive search field placeholder")
        static let archivedAt = LocalizedStringResource(
            "archive.archived_at", defaultValue: "Archived",
            comment: "Label for the archive date")
        static let restore = LocalizedStringResource(
            "archive.restore", defaultValue: "Return to cabinet",
            comment: "Action that restores a medicine from the archive")
        static let deleteConfirmTitle = LocalizedStringResource(
            "archive.delete.confirm.title", defaultValue: "Delete permanently?",
            comment: "Title of the permanent delete confirmation")
        static let deleteConfirmMessage = LocalizedStringResource(
            "archive.delete.confirm.message",
            defaultValue: "The medicine will disappear from your history on every device. This cannot be undone.",
            comment: "Body of the permanent delete confirmation")
    }

    enum Expired {
        static let title = LocalizedStringResource(
            "expired.title", defaultValue: "Expired medicines",
            comment: "Title of the sheet shown at app launch")
        static let archiveAll = LocalizedStringResource(
            "expired.archive_all", defaultValue: "Move all to archive",
            comment: "Action that archives all expired medicines")
        static let deleteAll = LocalizedStringResource(
            "expired.delete_all", defaultValue: "Delete all",
            comment: "Action that permanently deletes expired medicines on Free")
        static let archiveOne = LocalizedStringResource(
            "expired.archive_one", defaultValue: "Archive",
            comment: "Action that archives a single medicine")
        static let later = LocalizedStringResource(
            "expired.later", defaultValue: "Not now",
            comment: "Dismisses the sheet without archiving")
        static let footnote = LocalizedStringResource(
            "expired.footnote",
            defaultValue: "Archived medicines leave the cabinet but stay in your history.",
            comment: "Explains that archiving does not delete data")

        static func message(_ count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.message",
                defaultValue: "\(count) medicines in your cabinet have expired.",
                comment: "Summary of the expired medicine count")
        }
        static func expiredOn(_ dateText: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "expired.expired_on", defaultValue: "Expired on \(dateText)",
                comment: "Expiry date in the expired-medicines sheet")
        }
    }

    enum Menu {
        static let newMedicine = LocalizedStringResource(
            "menu.new_medicine", defaultValue: "New Medicine",
            comment: "Mac menu item that opens the form")
        static let search = LocalizedStringResource(
            "menu.search", defaultValue: "Search",
            comment: "Mac menu item that focuses the search field")
    }

    enum Paywall {
        static let title = LocalizedStringResource(
            "paywall.title", defaultValue: "Aegis Pro",
            comment: "Title of the subscription sheet")
        static let headline = LocalizedStringResource(
            "paywall.headline", defaultValue: "A cabinet for the whole family",
            comment: "Paywall headline")
        static let subtitle = LocalizedStringResource(
            "paywall.subtitle",
            defaultValue: "iCloud sync, archive, and a shared family medicine cabinet.",
            comment: "Paywall subtitle")
        static let benefitSync = LocalizedStringResource(
            "paywall.benefit.sync", defaultValue: "Sync on iPhone, iPad, and Mac",
            comment: "Pro benefit: sync")
        static let benefitFamily = LocalizedStringResource(
            "paywall.benefit.family", defaultValue: "Shared family medicine cabinet",
            comment: "Pro benefit: sharing")
        static let benefitArchive = LocalizedStringResource(
            "paywall.benefit.archive", defaultValue: "Archive and restore medicines",
            comment: "Pro benefit: archive")
        static let restore = LocalizedStringResource(
            "paywall.restore", defaultValue: "Restore purchases",
            comment: "Button to restore StoreKit purchases")
        static let debugUnlock = LocalizedStringResource(
            "paywall.debug_unlock", defaultValue: "Unlock Pro (debug)",
            comment: "Temporary Pro unlock in debug builds")
    }

    enum Settings {
        static let title = LocalizedStringResource(
            "settings.title", defaultValue: "Settings",
            comment: "Title of the settings screen")
        static let subscriptionSection = LocalizedStringResource(
            "settings.subscription", defaultValue: "Subscription",
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
            "settings.upgrade", defaultValue: "Upgrade to Pro",
            comment: "Button that opens the paywall")
        static let manageSubscription = LocalizedStringResource(
            "settings.manage", defaultValue: "Manage subscription",
            comment: "Link to manage the subscription in the App Store")
        static let syncSection = LocalizedStringResource(
            "settings.sync", defaultValue: "Sync",
            comment: "iCloud status section")
        static let iCloudStatus = LocalizedStringResource(
            "settings.icloud.status", defaultValue: "iCloud account",
            comment: "iCloud account status label")
        static let iCloudAvailable = LocalizedStringResource(
            "settings.icloud.available", defaultValue: "Available",
            comment: "iCloud available")
        static let iCloudNoAccount = LocalizedStringResource(
            "settings.icloud.no_account", defaultValue: "No account",
            comment: "No signed-in iCloud account")
        static let iCloudRestricted = LocalizedStringResource(
            "settings.icloud.restricted", defaultValue: "Restricted",
            comment: "iCloud restricted")
        static let iCloudUnknown = LocalizedStringResource(
            "settings.icloud.unknown", defaultValue: "Unknown",
            comment: "Unknown iCloud status")
        static let iCloudUnavailable = LocalizedStringResource(
            "settings.icloud.unavailable",
            defaultValue: "iCloud is unavailable on this device.",
            comment: "Message when sync cannot start")
        static let syncActive = LocalizedStringResource(
            "settings.sync.active", defaultValue: "Sync active",
            comment: "CloudSync is running")
        static let syncInactive = LocalizedStringResource(
            "settings.sync.inactive", defaultValue: "Sync inactive",
            comment: "CloudSync is off")
        static let syncNow = LocalizedStringResource(
            "settings.sync.now", defaultValue: "Sync now",
            comment: "Manual CloudKit refresh")
        static let sharingSection = LocalizedStringResource(
            "settings.sharing", defaultValue: "Family",
            comment: "CKShare section")
        static let shareCabinet = LocalizedStringResource(
            "settings.share", defaultValue: "Share cabinet",
            comment: "Button that opens CKShare")
        static let shareTitle = LocalizedStringResource(
            "settings.share.title", defaultValue: "Home medicine cabinet",
            comment: "CKShare title")
        static let shareFootnote = LocalizedStringResource(
            "settings.share.footnote",
            defaultValue: "Invited family members will see the same medicines on their devices.",
            comment: "Explains sharing the medicine cabinet")
        static let shareMacUnavailable = LocalizedStringResource(
            "settings.share.mac_unavailable",
            defaultValue: "Family sharing setup is available on iPhone and iPad. You can still accept invitations on Mac.",
            comment: "Explains that CKShare UI is not available on Mac")
        static let syncStoreUnavailable = LocalizedStringResource(
            "settings.sync.store_unavailable",
            defaultValue: "The local medicine cabinet is not ready yet. Open the app and try again.",
            comment: "Error when accepting a share before the local store is wired")
        static let notificationsSection = LocalizedStringResource(
            "settings.notifications", defaultValue: "Notifications",
            comment: "Expiry reminder settings section")
        static let notificationIncludeName = LocalizedStringResource(
            "settings.notification.include_name",
            defaultValue: "Show medicine names on lock screen",
            comment: "Toggle for including medicine names in notification bodies")
        static let notificationIncludeNameFootnote = LocalizedStringResource(
            "settings.notification.include_name.footnote",
            defaultValue: "Off by default so expiry reminders stay private on the lock screen.",
            comment: "Explains why medicine names are redacted by default")
    }

    /// Notification keys are resolved only at delivery time
    /// (`NSString.localizedUserNotificationString`), so they are plain string constants here.
    enum NotificationKey {
        static let expiringTitle = "notification.expiring.title"
        static let expiredTitle = "notification.expired.title"
        static let bodyIn30Days = "notification.body.in_30_days"
        static let bodyIn7Days = "notification.body.in_7_days"
        static let bodyToday = "notification.body.today"
        static let bodyIn30DaysPrivate = "notification.body.in_30_days.private"
        static let bodyIn7DaysPrivate = "notification.body.in_7_days.private"
        static let bodyTodayPrivate = "notification.body.today.private"
    }
}
