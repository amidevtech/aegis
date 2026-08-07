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

    enum LoadError: Error, Equatable {
        case corruptData
    }

    typealias OperationEncoder = @Sendable ([Operation]) throws -> Data

    private let defaults: UserDefaults
    private let key: String
    private let encoder: OperationEncoder
    /// Last successfully decoded or saved ops; survives corrupt disk reads.
    private let memory: MemoryCache

    init(
        defaults: UserDefaults = .standard,
        key: String = "cloudSync.outbox",
        encoder: @escaping OperationEncoder = { try JSONEncoder().encode($0) }
    ) {
        self.defaults = defaults
        self.key = key
        self.encoder = encoder
        self.memory = MemoryCache()
        // Prime cache from disk when possible.
        _ = try? loadFromDisk()
    }

    /// True when disk data exists but cannot be decoded (and may lack last-good cache).
    var isCorrupt: Bool { memory.loadFailed }

    var operations: [Operation] {
        do {
            return try loadFromDisk()
        } catch {
            return memory.operations
        }
    }

    var pendingDeleteUUIDs: Set<UUID> {
        Set(operations.compactMap {
            if case .delete(let uuid) = $0 { return uuid }
            return nil
        })
    }

    /// Loads ops from disk. Throws `LoadError.corruptData` instead of pretending the queue is empty.
    func loadOperations() throws -> [Operation] {
        try loadFromDisk()
    }

    @discardableResult
    func enqueueUpsert(_ snapshot: MedicineCloudSnapshot) -> Bool {
        var ops = operations
        // Delete wins until successfully flushed — ignore upserts for tombstoned UUIDs.
        if ops.contains(where: {
            if case .delete(let uuid) = $0 { return uuid == snapshot.uuid }
            return false
        }) {
            return true
        }
        ops.removeAll {
            if case .upsert(let existing) = $0 { return existing.uuid == snapshot.uuid }
            return false
        }
        ops.append(.upsert(snapshot))
        return save(ops)
    }

    @discardableResult
    func enqueueDelete(_ uuid: UUID) -> Bool {
        var ops = operations
        ops.removeAll { $0.uuid == uuid }
        ops.append(.delete(uuid))
        return save(ops)
    }

    /// Removes the operation only if an equal op is still queued. Safe after an
    /// in-flight flush when a newer upsert/delete replaced the flushed value.
    @discardableResult
    func remove(_ operation: Operation) -> Bool {
        var ops = operations
        guard let index = ops.firstIndex(of: operation) else { return true }
        ops.remove(at: index)
        return save(ops)
    }

    func clear() {
        defaults.removeObject(forKey: key)
        memory.operations = []
        memory.loadFailed = false
    }

    @discardableResult
    private func save(_ ops: [Operation]) -> Bool {
        do {
            let data = try encoder(ops)
            defaults.set(data, forKey: key)
            memory.operations = ops
            memory.loadFailed = false
            return true
        } catch {
            return false
        }
    }

    private func loadFromDisk() throws -> [Operation] {
        guard let data = defaults.data(forKey: key) else {
            memory.operations = []
            memory.loadFailed = false
            return []
        }
        do {
            let ops = try JSONDecoder().decode([Operation].self, from: data)
            memory.operations = ops
            memory.loadFailed = false
            return ops
        } catch {
            memory.loadFailed = true
            throw LoadError.corruptData
        }
    }
}

/// Reference cache so the outbox struct can keep last-good ops across corrupt reads.
private final class MemoryCache: @unchecked Sendable {
    var operations: [CloudSyncOutbox.Operation] = []
    var loadFailed = false
}
