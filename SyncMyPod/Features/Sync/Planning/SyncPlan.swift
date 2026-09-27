import Foundation

/// What a sync would change: tracks to add or update, and library tracks on the iPod that are no longer
/// selected, whose file is gone, or that duplicate a library song's copy; and the playlists to write.
nonisolated struct SyncPlan: Equatable, Sendable {
    let requests: [IPodSyncRequest]
    let updates: [IPodTrackUpdate]
    let removals: [ITunesTrack]
    let selectedCount: Int
    let playlists: [IPodPlaylistRequest]
    /// Playlists the iPod lacks or has out of date, plus ones it has that are no longer synced.
    let playlistChangeCount: Int

    init(requests: [IPodSyncRequest], updates: [IPodTrackUpdate] = [], removals: [ITunesTrack],
         selectedCount: Int, playlists: [IPodPlaylistRequest] = [], playlistChangeCount: Int = 0) {
        self.requests = requests
        self.updates = updates
        self.removals = removals
        self.selectedCount = selectedCount
        self.playlists = playlists
        self.playlistChangeCount = playlistChangeCount
    }

    var isEmpty: Bool { requests.isEmpty && updates.isEmpty && removals.isEmpty && playlistChangeCount == 0 }
    var alreadyOnDeviceCount: Int { selectedCount - requests.count - updates.count }
    /// What the syncer is handed: it works out again which of these are additions and which are updates.
    var syncRequests: [IPodSyncRequest] { requests + updates.map(\.request) }
    var byteCount: Int64 { requests.reduce(0) { $0 + Int64($1.draft.fileSize) } }
    var updatedByteCount: Int64 { updates.reduce(0) { $0 + Int64($1.request.draft.fileSize) } }
    var removedByteCount: Int64 { removals.reduce(0) { $0 + Int64($1.fileSize) } }
    var removalIDs: Set<UInt64> { Set(removals.map(\.databaseID)) }

    /// Songs in `playlists` are synced whatever the mode, album and genre selection.
    @MainActor
    static func make(tracks: [LibraryTrack], mode: SyncMode, selectedAlbums: Set<String>, selectedGenres: Set<String> = [],
                     preservingAlbumArtist: Bool = false, playlists: [IPodPlaylistRequest] = [], onDevice: [ITunesTrack],
                     devicePlaylists: [ITunesPlaylist] = [], manifest: SyncManifest = SyncManifest(),
                     strayDatabaseIDs: Set<UInt64> = []) -> SyncPlan {
        make(snapshots: tracks.map { $0.syncSnapshot(preservingAlbumArtist: preservingAlbumArtist) }, mode: mode,
             selectedAlbums: selectedAlbums, selectedGenres: selectedGenres, playlists: playlists,
             onDevice: onDevice, devicePlaylists: devicePlaylists, manifest: manifest,
             strayDatabaseIDs: strayDatabaseIDs)
    }

    static func make(snapshots tracks: [SyncTrackSnapshot], mode: SyncMode, selectedAlbums: Set<String>,
                     selectedGenres: Set<String>, playlists: [IPodPlaylistRequest], onDevice: [ITunesTrack],
                     devicePlaylists: [ITunesPlaylist], manifest: SyncManifest,
                     strayDatabaseIDs: Set<UInt64>) -> SyncPlan {
        let playlistPaths = Set(playlists.flatMap { $0.tracks.map(\.sourcePath) })
        let isSelected = { (track: SyncTrackSnapshot) in
            mode == .allSongs || selectedAlbums.contains(track.albumKey)
                || selectedGenres.contains(track.genre) || playlistPaths.contains(track.filePath)
        }
        let plan = SyncPlanner(manifest: manifest, onDevice: onDevice, strayDatabaseIDs: strayDatabaseIDs)
            .plan(selected: tracks.filter(isSelected).map(\.request),
                  unselected: tracks.filter { !isSelected($0) }.map(\.request))
        let resolver = PlaylistTrackResolver(manifest: manifest.valid(for: Set(onDevice.map(\.databaseID))),
                                             onDevice: onDevice)
        let changes = PlaylistChangeCounter.count(playlists, resolver: resolver, onDevice: onDevice,
                                                  devicePlaylists: devicePlaylists)
        return SyncPlan(requests: plan.requests, updates: plan.updates, removals: plan.removals,
                        selectedCount: plan.selectedCount, playlists: playlists, playlistChangeCount: changes)
    }
}
