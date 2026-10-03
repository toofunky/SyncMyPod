import Foundation

/// What a finished sync changed, in terms any kind of device can report.
nonisolated struct SyncSummary: Equatable, Sendable {
    var added = 0
    var updated = 0
    var removed = 0
    var skipped = 0
    var syncedPlaylistCount = 0
    var wasCancelled = false
    /// "iPod", for example, as shown in the result's title and message.
    var deviceKind: String
    /// `false` for a player synced to a folder inside a drive, which has nothing to eject.
    var suggestsEject = true

    var changedCount: Int { added + updated + removed + syncedPlaylistCount }
}

nonisolated extension SyncSummary {
    init(_ outcome: IPodSyncOutcome, deviceKind: String = "iPod") {
        self.init(added: outcome.addedCount, updated: outcome.updatedCount, removed: outcome.removed,
                  skipped: outcome.skipped, syncedPlaylistCount: outcome.syncedPlaylistCount,
                  wasCancelled: outcome.wasCancelled, deviceKind: deviceKind)
    }
}
