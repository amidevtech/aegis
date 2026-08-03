//
//  MedicineTests.swift
//  aegisTests
//

import Foundation
import SwiftData
import Testing

@testable import aegis

@MainActor
struct MedicineTests {

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        return ModelContext(container)
    }

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    @Test("Otwarcie opakowania podpowiada typową przydatność dla danej postaci")
    func markingOpenedAppliesSuggestedShelfLife() {
        let medicine = Medicine(expiryDate: daysFromNow(400), form: .eyeDrops)
        medicine.markOpened()

        #expect(medicine.isOpened)
        #expect(medicine.daysAfterOpening == 28)
        #expect(medicine.status() == .expiringSoon)
    }

    @Test("Cofnięcie otwarcia przywraca termin z opakowania")
    func markingUnopenedRestoresPackageExpiry() {
        let packageExpiry = daysFromNow(400)
        let medicine = Medicine(expiryDate: packageExpiry, form: .syrup)
        medicine.markOpened()
        #expect(medicine.status() == .expiringSoon)

        medicine.markUnopened()

        #expect(!medicine.isOpened)
        #expect(medicine.openedAt == nil)
        #expect(medicine.status() == .valid)
    }

    @Test("Zapisany termin obowiązujący nadąża za zmianą dat")
    func effectiveExpiryIsKeptInSync() {
        let medicine = Medicine(expiryDate: daysFromNow(400), form: .tablet)
        let startOfDay = Calendar.current.startOfDay(for: daysFromNow(400))
        #expect(medicine.effectiveExpiryDate == startOfDay)

        medicine.expiryDate = daysFromNow(10)
        medicine.refreshEffectiveExpiry()

        #expect(medicine.effectiveExpiryDate == Calendar.current.startOfDay(for: daysFromNow(10)))
    }

    @Test("Archiwizacja zdejmuje lek z apteczki, ale zostawia go w bazie")
    func archivingKeepsMedicineInStore() throws {
        let context = try makeContext()
        let medicine = Medicine(name: "Apap", expiryDate: daysFromNow(-5))
        context.insert(medicine)
        try context.save()

        MedicineActions.archive(medicine, reason: .expired, in: context)

        let active = try context.fetch(
            FetchDescriptor<Medicine>(predicate: MedicineQueries.active))
        let archived = try context.fetch(
            FetchDescriptor<Medicine>(predicate: MedicineQueries.archived))

        #expect(active.isEmpty)
        #expect(archived.count == 1)
        #expect(archived.first?.archiveReason == .expired)
        #expect(archived.first?.name == "Apap")
    }

    @Test("Przywrócenie z archiwum kasuje powód i datę archiwizacji")
    func restoringClearsArchiveMetadata() throws {
        let context = try makeContext()
        let medicine = Medicine(name: "Ibuprom", expiryDate: daysFromNow(100))
        context.insert(medicine)
        MedicineActions.archive(medicine, reason: .usedUp, in: context)

        MedicineActions.restore(medicine, in: context)

        #expect(!medicine.isArchived)
        #expect(medicine.archiveReason == nil)

        let active = try context.fetch(
            FetchDescriptor<Medicine>(predicate: MedicineQueries.active))
        #expect(active.count == 1)
    }

    @Test("Trwałe usunięcie znika z bazy")
    func permanentDeletionRemovesRecord() throws {
        let context = try makeContext()
        let medicine = Medicine(name: "Gripex", expiryDate: daysFromNow(-300))
        context.insert(medicine)
        MedicineActions.archive(medicine, reason: .expired, in: context)

        MedicineActions.deletePermanently(medicine, in: context)

        let all = try context.fetch(FetchDescriptor<Medicine>())
        #expect(all.isEmpty)
    }

    @Test("Domyślny powód archiwizacji zależy od stanu ważności")
    func defaultArchiveReasonFollowsStatus() {
        let expired = Medicine(expiryDate: daysFromNow(-1))
        let valid = Medicine(expiryDate: daysFromNow(90))

        #expect(expired.defaultArchiveReason() == .expired)
        #expect(valid.defaultArchiveReason() == .removed)
    }

    @Test("Formularz zachowuje wszystkie pola przy edycji")
    func draftPreservesFieldsOnRoundTrip() {
        let original = Medicine(
            name: "Amoksiklav",
            activeSubstance: "Amoksycylina",
            expiryDate: daysFromNow(200),
            personName: "Zosia",
            indication: "Angina",
            dosage: "5 ml",
            quantity: "100 ml",
            form: .syrup,
            notes: "W lodówce",
            isOpened: true,
            openedAt: daysFromNow(-3),
            daysAfterOpening: 14)

        let copy = Medicine()
        MedicineDraft(from: original).apply(to: copy)

        #expect(copy.name == original.name)
        #expect(copy.activeSubstance == original.activeSubstance)
        #expect(copy.personName == original.personName)
        #expect(copy.indication == original.indication)
        #expect(copy.dosage == original.dosage)
        #expect(copy.quantity == original.quantity)
        #expect(copy.form == original.form)
        #expect(copy.notes == original.notes)
        #expect(copy.isOpened == original.isOpened)
        #expect(copy.daysAfterOpening == original.daysAfterOpening)
        #expect(copy.effectiveExpiryDate == original.effectiveExpiryDate)
    }

    @Test("Wyszukiwanie obejmuje nazwę, substancję, osobę i zastosowanie")
    func freeTextSearchCoversAllDescriptiveFields() {
        let medicine = Medicine(
            name: "Apap",
            activeSubstance: "Paracetamol",
            personName: "Ania",
            indication: "Ból głowy")

        #expect(medicine.matches(freeText: "apa"))
        #expect(medicine.matches(freeText: "paracet"))
        #expect(medicine.matches(freeText: "ania"))
        #expect(medicine.matches(freeText: "ból"))
        #expect(!medicine.matches(freeText: "ibuprofen"))
    }

    @Test("Wyszukiwanie ignoruje polskie znaki diakrytyczne i wielkość liter")
    func freeTextSearchIsDiacriticInsensitive() {
        let medicine = Medicine(name: "Zatoki", indication: "Ból gardła")

        #expect(medicine.matches(freeText: "GARDLA"))
        #expect(medicine.matches(freeText: "bol"))
    }

    @Test("Token zawęża wyniki do wybranego pola")
    func tokenNarrowsToSingleField() {
        let medicine = Medicine(
            name: "Ania",
            activeSubstance: "Ibuprofen",
            personName: "Marek",
            indication: "Gorączka")

        let personToken = MedicineSearchToken(field: .person, value: "Ania")
        #expect(!personToken.matches(medicine))

        let substanceToken = MedicineSearchToken(field: .substance, value: "Ibuprofen")
        #expect(substanceToken.matches(medicine))
    }

    @Test("Podpowiedzi tokenów nie powtarzają tych samych wartości")
    func tokenSuggestionsAreDeduplicated() {
        let medicines = [
            Medicine(personName: "Ania", indication: "Ból głowy"),
            Medicine(personName: "Ania", indication: "Ból gardła")
        ]

        let suggestions = medicines.searchTokenSuggestions(matching: "ani")

        #expect(suggestions.count == 1)
        #expect(suggestions.first?.field == .person)
    }
}
