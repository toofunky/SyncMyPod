import Foundation

nonisolated struct IPodSyncOutcome: Equatable, Sendable {
    /// New database IDs keyed by source path.
    var addedDatabaseIDs: [String: UInt64] = [:]
    var skipped = 0
    var wasCancelled = false

    var addedCount: Int { addedDatabaseIDs.count }
}
