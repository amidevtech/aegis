//
//  MedicineRecordCoderTests.swift
//  aegisTests
//

import CloudKit
import Foundation
import SwiftData
import Testing

@testable import aegis

struct MedicineRecordCoderTests {

    @Test("Snapshot Medicine ↔ CKRecord zachowuje pola")
    func roundTripPreservesFields() {
        let medicine = Medicine(
            name: "Apap",
            activeSubstance: "Paracetamol",
            expiryDate: Date(timeIntervalSince1970: 1_900_000_000),
            personName: "Ania",
            indication: "Ból",
            dosage: "1 tabletka",
            quantity: "20 tabl.",
            form: .tablet,
            notes: "Po jedzeniu",
            isOpened: true,
            openedAt: Date(timeIntervalSince1970: 1_800_000_000),
            daysAfterOpening: 90,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            modifiedAt: Date(timeIntervalSince1970: 1_850_000_000))
        medicine.archive(reason: .usedUp, at: Date(timeIntervalSince1970: 1_860_000_000))
        medicine.touchModified(at: Date(timeIntervalSince1970: 1_870_000_000))

        let snapshot = MedicineCloudSnapshot(from: medicine)
        let record = MedicineRecordCoder.makeRecord(from: snapshot)
        let decoded = MedicineRecordCoder.snapshot(from: record)

        #expect(decoded != nil)
        #expect(decoded?.uuid == medicine.uuid)
        #expect(decoded?.name == "Apap")
        #expect(decoded?.activeSubstance == "Paracetamol")
        #expect(decoded?.personName == "Ania")
        #expect(decoded?.indication == "Ból")
        #expect(decoded?.dosage == "1 tabletka")
        #expect(decoded?.quantity == "20 tabl.")
        #expect(decoded?.formRaw == MedicineForm.tablet.rawValue)
        #expect(decoded?.notes == "Po jedzeniu")
        #expect(decoded?.isOpened == true)
        #expect(decoded?.daysAfterOpening == 90)
        #expect(decoded?.archiveReasonRaw == ArchiveReason.usedUp.rawValue)
        #expect(decoded?.modifiedAt == Date(timeIntervalSince1970: 1_870_000_000))
    }

    @Test("Last-write-wins: starszy snapshot nie nadpisuje nowszego lokalnego")
    @MainActor
    func olderCloudSnapshotDoesNotOverwriteNewerLocal() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let store = LocalStore(container: container)

        let medicine = Medicine(name: "Lokalny", modifiedAt: Date(timeIntervalSince1970: 200))
        store.insert(medicine)

        var older = MedicineCloudSnapshot(from: medicine)
        older.name = "Chmura"
        older.modifiedAt = Date(timeIntervalSince1970: 100)

        try store.upsertFromCloud(older)

        let stored = try #require(try store.medicine(uuid: medicine.uuid))
        #expect(stored.name == "Lokalny")
    }

    @Test("Nowszy snapshot z chmury nadpisuje lokalny")
    @MainActor
    func newerCloudSnapshotOverwritesLocal() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let store = LocalStore(container: container)

        let medicine = Medicine(name: "Lokalny", modifiedAt: Date(timeIntervalSince1970: 100))
        store.insert(medicine)

        var newer = MedicineCloudSnapshot(from: medicine)
        newer.name = "Chmura"
        newer.modifiedAt = Date(timeIntervalSince1970: 200)

        try store.upsertFromCloud(newer)

        let stored = try #require(try store.medicine(uuid: medicine.uuid))
        #expect(stored.name == "Chmura")
    }
}
