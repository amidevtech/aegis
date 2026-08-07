//
//  CloudSyncOutboxTests.swift
//  aegisTests
//

import Foundation
import SwiftData
import Testing

@testable import aegis

struct CloudSyncOutboxTests {

    private func makeOutbox() -> CloudSyncOutbox {
        let suite = "CloudSyncOutboxTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return CloudSyncOutbox(defaults: defaults, key: "test.outbox")
    }

    private func sampleSnapshot(
        uuid: UUID = UUID(),
        modifiedAt: Date = Date(timeIntervalSince1970: 100)
    ) -> MedicineCloudSnapshot {
        MedicineCloudSnapshot(
            uuid: uuid,
            name: "Test",
            activeSubstance: "",
            expiryDate: Date(timeIntervalSince1970: 200),
            personName: "",
            indication: "",
            dosage: "",
            quantity: "",
            formRaw: MedicineForm.tablet.rawValue,
            notes: "",
            isOpened: false,
            openedAt: nil,
            daysAfterOpening: nil,
            openedExpiryOverride: nil,
            effectiveExpiryDate: Date(timeIntervalSince1970: 200),
            createdAt: Date(timeIntervalSince1970: 50),
            archivedAt: nil,
            archiveReasonRaw: nil,
            modifiedAt: modifiedAt)
    }

    @Test("Duplicate upsert keeps a single latest snapshot")
    func duplicateUpsertCoalesces() {
        let outbox = makeOutbox()
        let uuid = UUID()
        var first = sampleSnapshot(uuid: uuid, modifiedAt: Date(timeIntervalSince1970: 100))
        first.name = "First"
        var second = sampleSnapshot(uuid: uuid, modifiedAt: Date(timeIntervalSince1970: 200))
        second.name = "Second"

        outbox.enqueueUpsert(first)
        outbox.enqueueUpsert(second)

        #expect(outbox.operations.count == 1)
        if case .upsert(let snapshot) = outbox.operations[0] {
            #expect(snapshot.name == "Second")
        } else {
            Issue.record("Expected upsert")
        }
    }

    @Test("Delete removes prior upsert and records delete")
    func deleteRemovesUpsert() {
        let outbox = makeOutbox()
        let uuid = UUID()
        outbox.enqueueUpsert(sampleSnapshot(uuid: uuid))
        outbox.enqueueDelete(uuid)

        #expect(outbox.operations == [.delete(uuid)])
        #expect(outbox.pendingDeleteUUIDs == [uuid])
    }

    @Test("Pending delete wins over later upsert")
    func deleteWinsUntilFlushed() {
        let outbox = makeOutbox()
        let uuid = UUID()
        outbox.enqueueDelete(uuid)
        outbox.enqueueUpsert(sampleSnapshot(uuid: uuid))

        #expect(outbox.operations == [.delete(uuid)])
    }

    @Test("Upload LWW skips when cloud is newer or equal")
    func uploadLWW() {
        let local = Date(timeIntervalSince1970: 100)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: local,
                cloudModifiedAt: Date(timeIntervalSince1970: 200)) == false)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: local,
                cloudModifiedAt: Date(timeIntervalSince1970: 100)) == false)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: local,
                cloudModifiedAt: Date(timeIntervalSince1970: 50)) == true)
        #expect(
            MedicineRecordCoder.shouldUpload(
                localModifiedAt: local,
                cloudModifiedAt: nil) == true)
    }

    @Test("Departed shared UUIDs are previous minus seen")
    func departedShared() {
        let a = UUID()
        let b = UUID()
        let c = UUID()
        let departed = MedicineRecordCoder.departedSharedUUIDs(
            previous: [a, b, c],
            seen: [a, c])
        #expect(departed == [b])
    }

    @Test("Exact remove drops matching upsert only")
    func exactRemoveMatchingUpsert() {
        let outbox = makeOutbox()
        let uuid = UUID()
        let snapshot = sampleSnapshot(uuid: uuid)
        outbox.enqueueUpsert(snapshot)
        outbox.remove(.upsert(snapshot))
        #expect(outbox.operations.isEmpty)
    }

    @Test("Exact remove of stale upsert leaves newer upsert")
    func exactRemovePreservesNewerUpsert() {
        let outbox = makeOutbox()
        let uuid = UUID()
        var v1 = sampleSnapshot(uuid: uuid, modifiedAt: Date(timeIntervalSince1970: 100))
        v1.name = "V1"
        var v2 = sampleSnapshot(uuid: uuid, modifiedAt: Date(timeIntervalSince1970: 200))
        v2.name = "V2"

        outbox.enqueueUpsert(v1)
        // Simulate in-flight flush of v1 while a newer edit replaces the outbox op.
        outbox.enqueueUpsert(v2)
        outbox.remove(.upsert(v1))

        #expect(outbox.operations.count == 1)
        if case .upsert(let snapshot) = outbox.operations[0] {
            #expect(snapshot.name == "V2")
        } else {
            Issue.record("Expected newer upsert to remain")
        }
    }

    @Test("Exact remove of stale upsert leaves newer delete tombstone")
    func exactRemovePreservesNewerDelete() {
        let outbox = makeOutbox()
        let uuid = UUID()
        let upsert = sampleSnapshot(uuid: uuid)
        outbox.enqueueUpsert(upsert)
        outbox.enqueueDelete(uuid)
        outbox.remove(.upsert(upsert))

        #expect(outbox.operations == [.delete(uuid)])
    }
}

@MainActor
struct CloudSyncTombstoneTests {

    @Test("Free-tier delete still records an outbox tombstone")
    func freeDeleteRecordsTombstone() throws {
        let suite = "CloudSyncTombstoneTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let outbox = CloudSyncOutbox(defaults: defaults, key: "test.outbox")

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Medicine.self, configurations: configuration)
        let localStore = LocalStore(container: container)
        let subscriptionStore = SubscriptionStore()
        subscriptionStore.debugProOverride = false
        let cloudSync = CloudSyncService(outbox: outbox)
        let repository = MedicineRepository(
            localStore: localStore,
            cloudSync: cloudSync,
            subscriptionStore: subscriptionStore)

        let medicine = Medicine(name: "Gone")
        let uuid = medicine.uuid
        localStore.insert(medicine)
        repository.delete(medicine)

        #expect(outbox.pendingDeleteUUIDs == [uuid])
        #expect(try localStore.medicine(uuid: uuid) == nil)
    }
}
