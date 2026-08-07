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

    @Test("Medicine snapshot ↔ CKRecord round-trip preserves fields")
    func roundTripPreservesFields() {
        let medicine = Medicine(
            name: "Apap",
            activeSubstance: "Paracetamol",
            expiryDate: Date(timeIntervalSince1970: 1_900_000_000),
            personName: "Anna",
            indication: "Pain",
            dosage: "1 tablet",
            quantity: "20 tabs",
            form: .tablet,
            notes: "After meals",
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
        #expect(decoded?.personName == "Anna")
        #expect(decoded?.indication == "Pain")
        #expect(decoded?.dosage == "1 tablet")
        #expect(decoded?.quantity == "20 tabs")
        #expect(decoded?.formRaw == MedicineForm.tablet.rawValue)
        #expect(decoded?.notes == "After meals")
        #expect(decoded?.isOpened == true)
        #expect(decoded?.daysAfterOpening == 90)
        #expect(decoded?.archiveReasonRaw == ArchiveReason.usedUp.rawValue)
        #expect(decoded?.modifiedAt == Date(timeIntervalSince1970: 1_870_000_000))
    }

    @Test("Last-write-wins: older snapshot does not overwrite newer local data")
    @MainActor
    func olderCloudSnapshotDoesNotOverwriteNewerLocal() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let store = LocalStore(container: container)

        let medicine = Medicine(name: "Local", modifiedAt: Date(timeIntervalSince1970: 200))
        store.insert(medicine)

        var older = MedicineCloudSnapshot(from: medicine)
        older.name = "Cloud"
        older.modifiedAt = Date(timeIntervalSince1970: 100)

        try store.upsertFromCloud(older)

        let stored = try #require(try store.medicine(uuid: medicine.uuid))
        #expect(stored.name == "Local")
    }

    @Test("Newer cloud snapshot overwrites local data")
    @MainActor
    func newerCloudSnapshotOverwritesLocal() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let store = LocalStore(container: container)

        let medicine = Medicine(name: "Local", modifiedAt: Date(timeIntervalSince1970: 100))
        store.insert(medicine)

        var newer = MedicineCloudSnapshot(from: medicine)
        newer.name = "Cloud"
        newer.modifiedAt = Date(timeIntervalSince1970: 200)

        try store.upsertFromCloud(newer)

        let stored = try #require(try store.medicine(uuid: medicine.uuid))
        #expect(stored.name == "Cloud")
    }

    @Test("Upload LWW helper skips equal and older local timestamps")
    func shouldUploadHelper() {
        let t = Date(timeIntervalSince1970: 100)
        #expect(MedicineRecordCoder.shouldUpload(localModifiedAt: t, cloudModifiedAt: t) == false)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: t,
                cloudModifiedAt: Date(timeIntervalSince1970: 101)) == false)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: Date(timeIntervalSince1970: 101),
                cloudModifiedAt: t) == true)
    }

    @Test("Departed shared UUID helper")
    func departedSharedHelper() {
        let kept = UUID()
        let gone = UUID()
        #expect(
            MedicineRecordCoder.departedSharedUUIDs(previous: [kept, gone], seen: [kept]) == [gone])
    }

    @Test("Tombstoned shared pull skips upsert but still counts as seen")
    func sharedPullTombstoneDisposition() {
        #expect(MedicineRecordCoder.shouldUpsertSharedPull(isTombstoned: false) == true)
        #expect(MedicineRecordCoder.shouldUpsertSharedPull(isTombstoned: true) == false)

        let uuid = UUID()
        var seen: Set<UUID> = []
        // Mimic pullShared: tombstoned hits still join `seen`.
        seen.insert(uuid)
        let shouldUpsert = MedicineRecordCoder.shouldUpsertSharedPull(isTombstoned: true)
        #expect(shouldUpsert == false)
        #expect(
            MedicineRecordCoder.departedSharedUUIDs(previous: [uuid], seen: seen).isEmpty)
    }

    @Test("Paged query results concatenate in order")
    func mergePagedResultsPreservesOrder() {
        let merged = MedicineRecordCoder.mergePagedResults([[1, 2], [3], [4, 5]])
        #expect(merged == [1, 2, 3, 4, 5])
        #expect(MedicineRecordCoder.mergePagedResults([[Int]]()) == [])
    }
}
