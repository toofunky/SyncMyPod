import Foundation

/// The manifest as the Sync tab plans with it, plus iPod tracks to remove because their library file was
/// deleted or they duplicate a library file's linked track.
nonisolated struct LoadedSyncManifest: Equatable, Sendable {
    var manifest = SyncManifest()
    var strayDatabaseIDs: Set<UInt64> = []
}
