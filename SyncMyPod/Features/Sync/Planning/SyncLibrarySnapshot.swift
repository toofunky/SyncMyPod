import Foundation

/// The library as the Sync tab shows and plans it, built once each time the library changes.
nonisolated struct SyncLibrarySnapshot: Equatable, Sendable {
    let tracks: [SyncTrackSnapshot]
    let playlists: [SyncPlaylistSnapshot]
    let artists: [SyncArtistNode]
    let genres: [SyncGenreNode]
    let playlistNodes: [SyncPlaylistNode]
    /// Podcasts with downloaded episodes, each oldest first.
    let podcasts: [SyncPodcastSnapshot]
    /// Books with files, each in listening order.
    let audiobooks: [SyncAudiobookSnapshot]

    /// `forIPod` leaves out episodes and book files an iPod can't play and gives the rest what its manifest needs.
    @MainActor
    init(tracks: [LibraryTrack], playlists: [LibraryPlaylist], podcasts: [Podcast] = [],
         audiobooks: [Audiobook] = [], forIPod: Bool = false, preservingAlbumArtist: Bool,
         embeddingLyricsSidecars: Bool = false) {
        self.podcasts = podcasts.compactMap { $0.syncSnapshot(forIPod: forIPod) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.audiobooks = audiobooks.compactMap { $0.syncSnapshot(forIPod: forIPod) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
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
