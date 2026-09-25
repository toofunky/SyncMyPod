import Foundation

nonisolated struct IPodSyncOutcome: Equatable, Sendable {
    /// New database IDs keyed by source path.
    var addedDatabaseIDs: [String: UInt64] = [:]
    /// Database IDs of rewritten tracks, keyed by source path.
    var updatedDatabaseIDs: [String: UInt64] = [:]
    var skipped = 0
    var removed = 0
    var wasCancelled = false

    var addedCount: Int { addedDatabaseIDs.count }
    var updatedCount: Int { updatedDatabaseIDs.count }
    var syncedDatabaseIDs: [String: UInt64] { addedDatabaseIDs.merging(updatedDatabaseIDs) { _, updated in updated } }
}
