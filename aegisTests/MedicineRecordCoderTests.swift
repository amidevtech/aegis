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

    @Test("Incomplete pull does not depart shared medicines")
    func incompletePullDoesNotDepart() {
        let a = UUID()
        let b = UUID()
        let departed = MedicineRecordCoder.localDeletesForSharedDeparture(
            previous: [a, b],
            seen: [a],
            pullIsComplete: false)
        #expect(departed.isEmpty)
    }

    @Test("Complete pull departs only missing shared UUIDs")
    func completePullDepartsMissingOnly() {
        let a = UUID()
        let b = UUID()
        let departed = MedicineRecordCoder.localDeletesForSharedDeparture(
            previous: [a, b],
            seen: [a],
            pullIsComplete: true)
        #expect(departed == [b])
    }

    @Test("Match results with a failure are incomplete")
    func matchResultsWithFailureAreIncomplete() {
        enum SampleError: Error { case boom }
        let okID = CKRecord.ID(recordName: UUID().uuidString)
        let failID = CKRecord.ID(recordName: UUID().uuidString)
        let okRecord = CKRecord(recordType: MedicineRecordCoder.recordType, recordID: okID)

        let page = MedicineRecordCoder.parseMatchResults([
            (okID, .success(okRecord)),
            (failID, .failure(SampleError.boom)),
        ])

        #expect(page.isComplete == false)
        #expect(page.records.map(\.recordID) == [okID])
    }

    @Test("All-success match results are complete")
    func allSuccessMatchResultsAreComplete() {
        let id1 = CKRecord.ID(recordName: UUID().uuidString)
        let id2 = CKRecord.ID(recordName: UUID().uuidString)
        let r1 = CKRecord(recordType: MedicineRecordCoder.recordType, recordID: id1)
        let r2 = CKRecord(recordType: MedicineRecordCoder.recordType, recordID: id2)

        let page = MedicineRecordCoder.parseMatchResults([
            (id1, .success(r1)),
            (id2, .success(r2)),
        ])

        #expect(page.isComplete == true)
        #expect(page.records.map(\.recordID) == [id1, id2])
    }

    @Test("Incomplete flag wins over tombstone-seen departure math")
    func tombstonedStillSeenBlocksDepartureWhenIncomplete() {
        let uuid = UUID()
        var seen: Set<UUID> = []
        seen.insert(uuid)
        #expect(MedicineRecordCoder.shouldUpsertSharedPull(isTombstoned: true) == false)

        // Even if seen omitted a prior UUID, incomplete pull must not delete.
        let other = UUID()
        let departed = MedicineRecordCoder.localDeletesForSharedDeparture(
            previous: [uuid, other],
            seen: seen,
            pullIsComplete: false)
        #expect(departed.isEmpty)

        let complete = MedicineRecordCoder.localDeletesForSharedDeparture(
            previous: [uuid, other],
            seen: seen,
            pullIsComplete: true)
        #expect(complete == [other])
    }
}
