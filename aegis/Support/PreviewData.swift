//
//  PreviewData.swift
//  aegis
//

import Foundation
import SwiftData

/// Kontener w pamięci z przykładową apteczką - używany wyłącznie przez podglądy.
enum PreviewData {

    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: Medicine.self, configurations: configuration)
        else { fatalError("Nie udało się utworzyć kontenera podglądu") }

        for medicine in samples {
            container.mainContext.insert(medicine)
        }
        return container
    }()

    /// Pusta apteczka - do podglądów stanów pustych.
    static let emptyContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: Medicine.self, configurations: configuration)
        else { fatalError("Nie udało się utworzyć kontenera podglądu") }
        return container
    }()

    static var samples: [Medicine] {
        [
            Medicine(
                name: "Apap",
                activeSubstance: "Paracetamol",
                expiryDate: daysFromNow(420),
                personName: "Ania",
                indication: "Ból głowy",
                dosage: "1 tabletka co 6 godzin",
                quantity: "20 tabletek",
                form: .tablet),
            Medicine(
                name: "Ibuprom Max",
                activeSubstance: "Ibuprofen",
                expiryDate: daysFromNow(18),
                personName: "Marek",
                indication: "Gorączka",
                dosage: "1 tabletka co 8 godzin",
                quantity: "24 tabletki",
                form: .tablet),
            Medicine(
                name: "Amoksiklav",
                activeSubstance: "Amoksycylina",
                expiryDate: daysFromNow(300),
                personName: "Zosia",
                indication: "Angina",
                dosage: "5 ml dwa razy dziennie",
                quantity: "100 ml",
                form: .syrup,
                notes: "Przechowywać w lodówce.",
                isOpened: true,
                openedAt: daysFromNow(-20),
                daysAfterOpening: 14),
            Medicine(
                name: "Xylometazolin",
                activeSubstance: "Ksylometazolina",
                expiryDate: daysFromNow(-40),
                personName: "Marek",
                indication: "Katar",
                dosage: "1 dawka do każdego nozdrza",
                quantity: "10 ml",
                form: .spray),
            Medicine(
                name: "Vigantoletten",
                activeSubstance: "Cholekalcyferol",
                expiryDate: daysFromNow(560),
                personName: "Zosia",
                indication: "Niedobór witaminy D",
                dosage: "2 krople dziennie",
                quantity: "10 ml",
                form: .drops,
                isOpened: true,
                openedAt: daysFromNow(-10),
                daysAfterOpening: 180),
            {
                let archived = Medicine(
                    name: "Gripex",
                    activeSubstance: "Paracetamol, pseudoefedryna",
                    expiryDate: daysFromNow(-200),
                    personName: "Ania",
                    indication: "Przeziębienie",
                    dosage: "1 tabletka co 8 godzin",
                    quantity: "12 tabletek",
                    form: .tablet)
                archived.archive(reason: .expired, at: daysFromNow(-190))
                return archived
            }()
        ]
    }

    private static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }
}
