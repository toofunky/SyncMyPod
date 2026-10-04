import Foundation

/// What a player sync has done so far, saved even when it stops early.
nonisolated struct PlayerSyncState: Sendable {
    var manifest: PlayerSyncManifest
    var summary: SyncSummary
    /// Paths files were deleted or moved from, whose folders may now be empty.
    var vacatedPaths: [String] = []
}
