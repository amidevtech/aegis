//
//  CloudSyncStartFlushTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

@MainActor
struct CloudSyncStartFlushTests {

    private enum FlushTestError: Error, LocalizedError {
        case cloudUnavailable

        var errorDescription: String? { "cloud unavailable" }
    }

    private func makeOutbox() -> CloudSyncOutbox {
        let suite = "CloudSyncStartFlushTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return CloudSyncOutbox(defaults: defaults, key: "test.outbox")
    }

    private func sampleSnapshot(
        uuid: UUID = UUID(),
        name: String = "Test",
        modifiedAt: Date = Date(timeIntervalSince1970: 100)
    ) -> MedicineCloudSnapshot {
        MedicineCloudSnapshot(
            uuid: uuid,
            name: name,
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

    @Test("Ops enqueued while starting are flushed when start window finishes")
    func opsEnqueuedWhileStartingAreFlushedWhenStartFinishes() async {
        let outbox = makeOutbox()
        var deleted: [UUID] = []
        var upserted: [UUID] = []

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { deleted.append($0) },
            cloudUpsert: { upserted.append($0.uuid) })

        let deleteUUID = UUID()
        let upsertUUID = UUID()
        let snapshot = sampleSnapshot(uuid: upsertUUID)

        await sync.simulateStartWindow {
            #expect(sync.isRunning == false)
            outbox.enqueueDelete(deleteUUID)
            outbox.enqueueUpsert(snapshot)
            #expect(outbox.operations.count == 2)
        }

        #expect(sync.isRunning == true)
        #expect(outbox.operations.isEmpty)
        #expect(deleted == [deleteUUID])
        #expect(upserted == [upsertUUID])
        #expect(sync.lastErrorMessage == nil)
    }

    @Test("Failed terminal flush keeps error and pending op")
    func failedTerminalFlushKeepsErrorAndOp() async {
        let outbox = makeOutbox()
        let uuid = UUID()

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { _ in throw FlushTestError.cloudUnavailable },
            cloudUpsert: { _ in })

        await sync.simulateStartWindow {
            outbox.enqueueDelete(uuid)
        }

        #expect(sync.isRunning == true)
        #expect(outbox.operations == [.delete(uuid)])
        #expect(sync.lastErrorMessage == "cloud unavailable")
    }
}
