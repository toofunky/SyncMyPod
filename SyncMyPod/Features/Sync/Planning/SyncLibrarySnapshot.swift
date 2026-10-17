import Foundation

/// The library as the Sync tab shows and plans it, built once each time the library changes.
nonisolated struct SyncLibrarySnapshot: Equatable, Sendable {
    let tracks: [SyncTrackSnapshot]
    let playlists: [SyncPlaylistSnapshot]
    let artists: [SyncArtistNode]
    let genres: [SyncGenreNode]
    let playlistNodes: [SyncPlaylistNode]
    /// Podcasts with downloaded episodes; empty for iPods, which don't sync podcasts yet.
    let podcasts: [SyncPodcastSnapshot]

    @MainActor
    init(tracks: [LibraryTrack], playlists: [LibraryPlaylist], podcasts: [Podcast] = [], preservingAlbumArtist: Bool,
         embeddingLyricsSidecars: Bool = false) {
        self.podcasts = podcasts.compactMap { $0.syncSnapshot() }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let snapshots = tracks.map {
            $0.syncSnapshot(preservingAlbumArtist: preservingAlbumArtist, embeddingLyricsSidecar: embeddingLyricsSidecars)
        }
        let requestsByPath = Dictionary(snapshots.map { ($0.filePath, $0.request) },
                                        uniquingKeysWith: { first, _ in first })
        self.tracks = snapshots
        self.playlists = playlists.map { $0.syncSnapshot(requestsByPath: requestsByPath) }
        artists = SyncTreeBuilder.artists(from: snapshots)
        genres = SyncTreeBuilder.genres(from: snapshots)
        playlistNodes = SyncTreeBuilder.playlists(from: playlists)
    }
}
