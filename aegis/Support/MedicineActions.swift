//
//  MedicineActions.swift
//  aegis
//

import Foundation
import SwiftData

/// Operacje zmieniające stan leku, zebrane w jednym miejscu, żeby zapis do bazy
/// i przeplanowanie powiadomień nie rozjechały się między ekranami.
enum MedicineActions {

    /// Lek znika z apteczki, ale zostaje w historii. To jedyny sposób "usunięcia"
    /// z listy posiadanych leków.
    static func archive(_ medicine: Medicine, reason: ArchiveReason, in context: ModelContext) {
        medicine.archive(reason: reason)
        NotificationService.shared.cancel(for: medicine)
        save(context)
    }

    static func archive(_ medicines: [Medicine], reason: ArchiveReason, in context: ModelContext) {
        for medicine in medicines {
            medicine.archive(reason: reason)
            NotificationService.shared.cancel(for: medicine)
        }
        save(context)
    }

    static func restore(_ medicine: Medicine, in context: ModelContext) {
        medicine.restore()
        medicine.refreshEffectiveExpiry()
        save(context)
        Task { await NotificationService.shared.reschedule(for: medicine) }
    }

    /// Trwałe skasowanie - dostępne wyłącznie w archiwum, po potwierdzeniu.
    static func deletePermanently(_ medicine: Medicine, in context: ModelContext) {
        NotificationService.shared.cancel(for: medicine)
        context.delete(medicine)
        save(context)
    }

    static func setOpened(_ isOpened: Bool, for medicine: Medicine, in context: ModelContext) {
        if isOpened {
            medicine.markOpened()
        } else {
            medicine.markUnopened()
        }
        save(context)
        Task { await NotificationService.shared.reschedule(for: medicine) }
    }

    private static func save(_ context: ModelContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Zapis do lokalnego magazynu nie powinien zawieść; gdy się to zdarzy,
            // dane zostają w kontekście i trafią do bazy przy kolejnej próbie.
            assertionFailure("Nie udało się zapisać zmian: \(error)")
        }
    }
}
