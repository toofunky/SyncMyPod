import Foundation

/// The library as the Sync tab shows and plans it, built once each time the library changes.
nonisolated struct SyncLibrarySnapshot: Equatable, Sendable {
    let tracks: [SyncTrackSnapshot]
    let playlists: [SyncPlaylistSnapshot]
    let artists: [SyncArtistNode]
    let genres: [SyncGenreNode]
    let playlistNodes: [SyncPlaylistNode]

    @MainActor
    init(tracks: [LibraryTrack], playlists: [LibraryPlaylist], preservingAlbumArtist: Bool) {
        let snapshots = tracks.map { $0.syncSnapshot(preservingAlbumArtist: preservingAlbumArtist) }
        let requestsByPath = Dictionary(snapshots.map { ($0.filePath, $0.request) },
                                        uniquingKeysWith: { first, _ in first })
        self.tracks = snapshots
        self.playlists = playlists.map { $0.syncSnapshot(requestsByPath: requestsByPath) }
        artists = SyncTreeBuilder.artists(from: snapshots)
        genres = SyncTreeBuilder.genres(from: snapshots)
        playlistNodes = SyncTreeBuilder.playlists(from: playlists)
    }
}
