//
//  MedicineTests.swift
//  aegisTests
//

import Foundation
import SwiftData
import Testing

@testable import aegis

@MainActor
@Suite(.serialized)
struct MedicineTests {

    private func makeServices(isPro: Bool = true) throws -> AppServices {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let services = AppServices(modelContainer: container)
        services.subscriptionStore.debugProOverride = isPro
        return services
    }

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
    }

    @Test("Opening a package applies the typical shelf life for that form")
    func markingOpenedAppliesSuggestedShelfLife() {
        let medicine = Medicine(expiryDate: daysFromNow(400), form: .eyeDrops)
        medicine.markOpened()

        #expect(medicine.isOpened)
        #expect(medicine.daysAfterOpening == 28)
        // Suggested shelf life (28 days) is beyond the 5-day soon window.
        #expect(medicine.status() == .valid)
        #expect(medicine.daysRemaining() == 28)
    }

    @Test("Marking unopened restores the package expiry")
    func markingUnopenedRestoresPackageExpiry() {
        let packageExpiry = daysFromNow(400)
        let medicine = Medicine(expiryDate: packageExpiry, form: .syrup)
        medicine.markOpened()
        #expect(medicine.daysAfterOpening == 30)
        #expect(medicine.daysRemaining() == 30)
        #expect(medicine.status() == .valid)

        medicine.markUnopened()

        #expect(!medicine.isOpened)
        #expect(medicine.openedAt == nil)
        #expect(medicine.status() == .valid)
        #expect(
            medicine.effectiveExpiryDate
                == Calendar.current.startOfDay(for: packageExpiry))
    }

    @Test("Medicines within 5 days of expiry are marked expiring soon")
    func statusIsExpiringSoonWithinFiveDays() {
        #expect(MedicineStatus.soonThresholdInDays == 5)

        let onThreshold = Medicine(expiryDate: daysFromNow(5))
        let justOutside = Medicine(expiryDate: daysFromNow(6))
        let expiresToday = Medicine(expiryDate: daysFromNow(0))
        let expired = Medicine(expiryDate: daysFromNow(-1))

        #expect(onThreshold.status() == .expiringSoon)
        #expect(onThreshold.daysRemaining() == 5)
        #expect(justOutside.status() == .valid)
        #expect(justOutside.daysRemaining() == 6)
        #expect(expiresToday.status() == .expiringSoon)
        #expect(expired.status() == .expired)
    }

    @Test("Stored effective expiry stays in sync when dates change")
    func effectiveExpiryIsKeptInSync() {
        let medicine = Medicine(expiryDate: daysFromNow(400), form: .tablet)
        let startOfDay = Calendar.current.startOfDay(for: daysFromNow(400))
        #expect(medicine.effectiveExpiryDate == startOfDay)

        medicine.expiryDate = daysFromNow(10)
        medicine.refreshEffectiveExpiry()

        #expect(medicine.effectiveExpiryDate == Calendar.current.startOfDay(for: daysFromNow(10)))
    }

    @Test("Archiving removes the medicine from the cabinet but keeps it in the store")
    func archivingKeepsMedicineInStore() throws {
        let services = try makeServices()
        let medicine = Medicine(name: "Apap", expiryDate: daysFromNow(-5))
        services.repository.upsert(medicine, isNew: true)

        let result = MedicineActions.archive(medicine, reason: .expired, in: services.repository)
        guard case .success = result else {
            Issue.record("Expected archive to succeed")
            return
        }

        let active = try services.localStore.fetchActive()
        let archived = try services.localStore.context.fetch(
            FetchDescriptor<Medicine>(predicate: MedicineQueries.archived))

        #expect(active.isEmpty)
        #expect(archived.count == 1)
        #expect(archived.first?.archiveReason == .expired)
        #expect(archived.first?.name == "Apap")
    }

    @Test("Archiving without Pro is blocked")
    func archivingRequiresPro() throws {
        let services = try makeServices(isPro: false)
        let medicine = Medicine(name: "Apap", expiryDate: daysFromNow(-5))
        services.localStore.insert(medicine)

        let result = MedicineActions.archive(medicine, reason: .expired, in: services.repository)
        guard case .failure(.requiresPro) = result else {
            Issue.record("Expected requiresPro failure")
            return
        }
        #expect(!medicine.isArchived)
    }

    @Test("Restoring from archive clears reason and archive date")
    func restoringClearsArchiveMetadata() throws {
        let services = try makeServices()
        let medicine = Medicine(name: "Ibuprom", expiryDate: daysFromNow(100))
        services.repository.upsert(medicine, isNew: true)
        _ = MedicineActions.archive(medicine, reason: .usedUp, in: services.repository)

        let result = MedicineActions.restore(medicine, in: services.repository)
        guard case .success = result else {
            Issue.record("Expected restore to succeed")
            return
        }

        #expect(!medicine.isArchived)
        #expect(medicine.archiveReason == nil)

        let active = try services.localStore.fetchActive()
        #expect(active.count == 1)
    }

    @Test("Permanent deletion removes the record from the store")
    func permanentDeletionRemovesRecord() throws {
        let services = try makeServices()
        let medicine = Medicine(name: "Gripex", expiryDate: daysFromNow(-300))
        services.repository.upsert(medicine, isNew: true)
        _ = MedicineActions.archive(medicine, reason: .expired, in: services.repository)

        MedicineActions.delete(medicine, in: services.repository)

        let all = try services.localStore.fetchAll()
        #expect(all.isEmpty)
    }

    @Test("Free can permanently delete an active medicine")
    func freeCanDeleteActiveMedicine() throws {
        let services = try makeServices(isPro: false)
        let medicine = Medicine(name: "Gripex", expiryDate: daysFromNow(30))
        services.localStore.insert(medicine)

        MedicineActions.delete(medicine, in: services.repository)

        let all = try services.localStore.fetchAll()
        #expect(all.isEmpty)
    }

    @Test("Default archive reason follows expiry status")
    func defaultArchiveReasonFollowsStatus() {
        let expired = Medicine(expiryDate: daysFromNow(-1))
        let valid = Medicine(expiryDate: daysFromNow(90))

        #expect(expired.defaultArchiveReason() == .expired)
        #expect(valid.defaultArchiveReason() == .removed)
    }

    @Test("Draft preserves every field on edit round-trip")
    func draftPreservesFieldsOnRoundTrip() {
        let original = Medicine(
            name: "Amoksiklav",
            activeSubstance: "Amoxicillin",
            expiryDate: daysFromNow(200),
            personName: "Sophie",
            indication: "Strep throat",
            dosage: "5 ml",
            quantity: "100 ml",
            form: .syrup,
            notes: "Keep refrigerated",
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

    @Test("Free-text search covers name, substance, person, and indication")
    func freeTextSearchCoversAllDescriptiveFields() {
        let medicine = Medicine(
            name: "Apap",
            activeSubstance: "Paracetamol",
            personName: "Anna",
            indication: "Headache")

        #expect(medicine.matches(freeText: "apa"))
        #expect(medicine.matches(freeText: "paracet"))
        #expect(medicine.matches(freeText: "anna"))
        #expect(medicine.matches(freeText: "head"))
        #expect(!medicine.matches(freeText: "ibuprofen"))
    }

    @Test("Free-text search ignores Polish diacritics and letter case")
    func freeTextSearchIsDiacriticInsensitive() {
        let medicine = Medicine(name: "Zatoki", indication: "Ból gardła")

        #expect(medicine.matches(freeText: "GARDLA"))
        #expect(medicine.matches(freeText: "bol"))
    }

    @Test("Token narrows results to the chosen field")
    func tokenNarrowsToSingleField() {
        let medicine = Medicine(
            name: "Anna",
            activeSubstance: "Ibuprofen",
            personName: "Mark",
            indication: "Fever")

        let personToken = MedicineSearchToken(field: .person, value: "Anna")
        #expect(!personToken.matches(medicine))

        let substanceToken = MedicineSearchToken(field: .substance, value: "Ibuprofen")
        #expect(substanceToken.matches(medicine))
    }

    @Test("Token suggestions do not repeat the same values")
    func tokenSuggestionsAreDeduplicated() {
        let medicines = [
            Medicine(personName: "Anna", indication: "Headache"),
            Medicine(personName: "Anna", indication: "Sore throat")
        ]

        let suggestions = medicines.searchTokenSuggestions(matching: "ann")

        #expect(suggestions.count == 1)
        #expect(suggestions.first?.field == .person)
    }
}
