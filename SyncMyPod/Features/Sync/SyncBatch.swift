import Foundation

/// The songs one sync copies, with the existing album art they may reuse.
nonisolated struct SyncBatch: Sendable {
    let items: [SyncBatchItem]
    let albumTracks: [IPodAlbumKey: [UInt64]]
    let progress: @Sendable (IPodSyncProgress) async -> Void
}
