import Foundation

/// The tracks one sync copies, with the existing album art they may reuse.
nonisolated struct SyncBatch: Sendable {
    let requests: [IPodSyncRequest]
    let albumTracks: [IPodAlbumKey: [UInt64]]
    let progress: @Sendable (IPodSyncProgress) async -> Void
}
