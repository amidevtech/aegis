//
//  CloudSyncOutbox.swift
//  aegis
//

import Foundation

/// Durable CloudKit mutation queue (UserDefaults). Survives process death so
/// failed upserts/deletes retry on the next flush / Pro start.
struct CloudSyncOutbox: Sendable {
    enum Operation: Codable, Equatable, Sendable {
        case upsert(MedicineCloudSnapshot)
        case delete(UUID)

        var uuid: UUID {
            switch self {
            case .upsert(let snapshot): snapshot.uuid
            case .delete(let uuid): uuid
            }
        }
    }

    private let defaults: UserDefaults
    private let key: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "cloudSync.outbox"
    ) {
        self.defaults = defaults
        self.key = key
    }

    var operations: [Operation] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Operation].self, from: data)) ?? []
    }

    var pendingDeleteUUIDs: Set<UUID> {
        Set(operations.compactMap {
            if case .delete(let uuid) = $0 { return uuid }
            return nil
        })
    }

    func enqueueUpsert(_ snapshot: MedicineCloudSnapshot) {
        var ops = operations
        // Delete wins until successfully flushed — ignore upserts for tombstoned UUIDs.
        if ops.contains(where: {
            if case .delete(let uuid) = $0 { return uuid == snapshot.uuid }
            return false
        }) {
            return
        }
        ops.removeAll {
            if case .upsert(let existing) = $0 { return existing.uuid == snapshot.uuid }
            return false
        }
        ops.append(.upsert(snapshot))
        save(ops)
    }

    func enqueueDelete(_ uuid: UUID) {
        var ops = operations
        ops.removeAll { $0.uuid == uuid }
        ops.append(.delete(uuid))
        save(ops)
    }

    /// Removes the operation only if an equal op is still queued. Safe after an
    /// in-flight flush when a newer upsert/delete replaced the flushed value.
    func remove(_ operation: Operation) {
        var ops = operations
        guard let index = ops.firstIndex(of: operation) else { return }
        ops.remove(at: index)
        save(ops)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ ops: [Operation]) {
        if let data = try? JSONEncoder().encode(ops) {
            defaults.set(data, forKey: key)
        }
    }
}
