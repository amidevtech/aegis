//
//  MedicineActions.swift
//  aegis
//

import Foundation

/// Thin facade over `MedicineRepository` so call sites in views
/// stay readable (archive / restore / delete / setOpened).
enum MedicineActions {

    @MainActor
    static func archive(
        _ medicine: Medicine,
        reason: ArchiveReason,
        in repository: MedicineRepository
    ) -> Result<Void, MedicineRepositoryError> {
        repository.archive(medicine, reason: reason)
    }

    @MainActor
    static func archive(
        _ medicines: [Medicine],
        reason: ArchiveReason,
        in repository: MedicineRepository
    ) -> Result<Void, MedicineRepositoryError> {
        repository.archive(medicines, reason: reason)
    }

    @MainActor
    static func restore(
        _ medicine: Medicine,
        in repository: MedicineRepository
    ) -> Result<Void, MedicineRepositoryError> {
        repository.restore(medicine)
    }

    @MainActor
    static func delete(_ medicine: Medicine, in repository: MedicineRepository) {
        repository.delete(medicine)
    }

    @MainActor
    static func setOpened(
        _ isOpened: Bool,
        for medicine: Medicine,
        in repository: MedicineRepository
    ) {
        repository.setOpened(isOpened, for: medicine)
    }
}
