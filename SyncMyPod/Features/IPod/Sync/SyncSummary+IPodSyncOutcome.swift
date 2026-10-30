import Foundation

nonisolated extension SyncSummary {
    init(_ outcome: IPodSyncOutcome, deviceKind: DeviceKind = .iPod) {
        self.init(added: outcome.addedCount, updated: outcome.updatedCount, removed: outcome.removed,
                  skipped: outcome.skipped, syncedPlaylistCount: outcome.syncedPlaylistCount,
                  wasCancelled: outcome.wasCancelled, deviceKind: deviceKind)
    }
}
