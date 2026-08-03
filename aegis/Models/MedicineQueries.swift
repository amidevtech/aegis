//
//  MedicineQueries.swift
//  aegis
//

import Foundation
import SwiftData

/// Predykaty i kolejności sortowania współdzielone przez ekrany.
///
/// Predykaty celowo nie zawierają dat - `@Query` zamraża je w chwili utworzenia widoku,
/// więc granica "dzisiaj" szybko by się zdezaktualizowała. Filtrowanie po terminach
/// odbywa się na już pobranych, posortowanych danych.
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
