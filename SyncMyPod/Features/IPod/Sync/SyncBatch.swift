import Foundation

/// The songs one sync copies, with the existing album art they may reuse, and the playlists it writes.
nonisolated struct SyncBatch: Sendable {
    let items: [SyncBatchItem]
    let albumTracks: [IPodAlbumKey: [UInt64]]
    /// `nil` leaves the iPod's playlists alone; otherwise these replace every playlist this app wrote before.
    let playlists: [IPodPlaylistRequest]?
    let resolver: PlaylistTrackResolver
    let progress: @Sendable (SyncProgress) async -> Void

    var isEmpty: Bool { items.isEmpty && playlists == nil }

    /// The manifest recording the copied tracks and, if playlists were written, their IDs.
    func manifest(after outcome: IPodSyncOutcome) -> SyncManifest {
        let recorded = resolver.manifest.recording(items.map(\.request), as: outcome.syncedDatabaseIDs)
        guard let playlists else { return recorded }
        return recorded.managingPlaylists(Set(playlists.map(\.id)))
    }
}
