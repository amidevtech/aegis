//
//  CloudSyncFlushTests.swift
//  aegisTests
//

import Foundation
import Testing

@testable import aegis

@MainActor
struct CloudSyncFlushTests {

    private enum FlushTestError: Error, LocalizedError {
        case cloudUnavailable

        var errorDescription: String? { "cloud unavailable" }
    }

    private func makeOutbox() -> CloudSyncOutbox {
        let suite = "CloudSyncFlushTests.\(UUID().uuidString)"
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

    @Test("Error policy clears message only when flush succeeded")
    func errorPolicyKeepsFlushFailure() {
        #expect(
            CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
                flushSucceeded: true,
                flushErrorMessage: "stale") == nil)
        #expect(
            CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
                flushSucceeded: false,
                flushErrorMessage: "cloud unavailable") == "cloud unavailable")
    }

    @Test("Failed delete flush keeps op and error message")
    func failedDeleteKeepsOutboxAndError() async {
        let outbox = makeOutbox()
        let uuid = UUID()
        outbox.enqueueDelete(uuid)

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { _ in throw FlushTestError.cloudUnavailable },
            cloudUpsert: { _ in })

        let succeeded = await sync.flushOutbox()
        #expect(succeeded == false)
        #expect(outbox.operations == [.delete(uuid)])
        #expect(sync.lastErrorMessage == "cloud unavailable")
    }

    @Test("Pull-now success path must not clear a failed flush error")
    func pullNowSuccessPathKeepsFlushError() async {
        let outbox = makeOutbox()
        outbox.enqueueDelete(UUID())

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { _ in throw FlushTestError.cloudUnavailable },
            cloudUpsert: { _ in })

        let flushSucceeded = await sync.flushOutbox()
        let message = CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
            flushSucceeded: flushSucceeded,
            flushErrorMessage: sync.lastErrorMessage)

        #expect(flushSucceeded == false)
        #expect(message == "cloud unavailable")
    }

    @Test("Successful flush allows clearing error")
    func successfulFlushAllowsClear() async {
        let outbox = makeOutbox()
        let uuid = UUID()
        outbox.enqueueDelete(uuid)

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { _ in },
            cloudUpsert: { _ in })

        let succeeded = await sync.flushOutbox()
        #expect(succeeded == true)
        #expect(outbox.operations.isEmpty)
        #expect(
            CloudSyncErrorPolicy.errorMessageAfterSuccessfulSteps(
                flushSucceeded: succeeded,
                flushErrorMessage: sync.lastErrorMessage) == nil)
    }

    @Test("In-flight upsert success does not drop a newer delete")
    func flushRacePreservesDeleteTombstone() async {
        let outbox = makeOutbox()
        let uuid = UUID()
        let upsert = sampleSnapshot(uuid: uuid, name: "Stale")
        outbox.enqueueUpsert(upsert)

        let started = expectationGate()
        let release = expectationGate()

        let sync = CloudSyncService(
            outbox: outbox,
            cloudDelete: { _ in },
            cloudUpsert: { _ in
                started.resume()
                await release.wait()
            })

        let flushTask = Task { await sync.flushOutbox() }
        await started.wait()

        // Concurrent edit while upsert is in flight.
        outbox.enqueueDelete(uuid)
        release.resume()

        let succeeded = await flushTask.value
        #expect(succeeded == true)
        #expect(outbox.operations == [.delete(uuid)])
    }
}

/// Tiny async gate used to interleave flush with outbox mutations in tests.
@MainActor
private final class ExpectationGate {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var isResumed = false

    func wait() async {
        if isResumed { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func resume() {
        isResumed = true
        let pending = continuations
        continuations.removeAll()
        for continuation in pending {
            continuation.resume()
        }
    }
}

@MainActor
private func expectationGate() -> ExpectationGate {
    ExpectationGate()
}
