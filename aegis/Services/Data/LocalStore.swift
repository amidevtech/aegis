//
//  LocalStore.swift
//  aegis
//

import Foundation
import SwiftData

/// Lokalny magazyn SwiftData. UI czyta przez `@Query`; zapisy idą przez ten store.
@MainActor
final class LocalStore {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func insert(_ medicine: Medicine) {
        context.insert(medicine)
        save()
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Nie udało się zapisać LocalStore: \(error)")
        }
    }

    func delete(_ medicine: Medicine) {
        context.delete(medicine)
        save()
    }

    func fetchAll() throws -> [Medicine] {
        try context.fetch(FetchDescriptor<Medicine>())
    }

    func fetchActive() throws -> [Medicine] {
        try context.fetch(
            FetchDescriptor<Medicine>(
                predicate: MedicineQueries.active,
                sortBy: MedicineQueries.byExpiry))
    }

    func medicine(uuid: UUID) throws -> Medicine? {
        let predicate = #Predicate<Medicine> { $0.uuid == uuid }
        var descriptor = FetchDescriptor<Medicine>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Wstawia lub aktualizuje lek przychodzący z CloudKit (mirror).
    func upsertFromCloud(_ snapshot: MedicineCloudSnapshot) throws {
        if let existing = try medicine(uuid: snapshot.uuid) {
            if existing.modifiedAt >= snapshot.modifiedAt { return }
            snapshot.apply(to: existing)
            save()
        } else {
            let medicine = Medicine()
            snapshot.apply(to: medicine)
            context.insert(medicine)
            save()
        }
    }

    func deleteByUUID(_ uuid: UUID) throws {
        if let medicine = try medicine(uuid: uuid) {
            context.delete(medicine)
            save()
        }
    }
}
