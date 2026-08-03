//
//  MedicineQueries.swift
//  aegis
//

import Foundation
import SwiftData

/// Predicates and sort orders shared across screens.
///
/// Predicates intentionally omit dates — `@Query` freezes them when the view is
/// created, so a "today" boundary would go stale quickly. Expiry filtering
/// happens on already-fetched, sorted data.
nonisolated enum MedicineQueries {

    static var active: Predicate<Medicine> {
        #Predicate<Medicine> { medicine in
            medicine.archivedAt == nil
        }
    }

    static var archived: Predicate<Medicine> {
        #Predicate<Medicine> { medicine in
            medicine.archivedAt != nil
        }
    }

    static var byExpiry: [SortDescriptor<Medicine>] {
        [
            SortDescriptor(\Medicine.effectiveExpiryDate, order: .forward),
            SortDescriptor(\Medicine.name, comparator: .localizedStandard)
        ]
    }

    static var byName: [SortDescriptor<Medicine>] {
        [SortDescriptor(\Medicine.name, comparator: .localizedStandard)]
    }

    static var byArchiveDate: [SortDescriptor<Medicine>] {
        [
            SortDescriptor(\Medicine.archivedAt, order: .reverse),
            SortDescriptor(\Medicine.name, comparator: .localizedStandard)
        ]
    }
}
