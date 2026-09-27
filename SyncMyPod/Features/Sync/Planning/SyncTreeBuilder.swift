import Foundation

/// Groups library tracks into the artist → album tree and genres, and lists the playlists, shown for custom syncs.
nonisolated enum SyncTreeBuilder {
    static func artists(from tracks: [SyncTrackSnapshot]) -> [SyncArtistNode] {
        Dictionary(grouping: tracks, by: \.artist)
            .map { name, tracks in
                (SyncArtistNode(name: name, albums: albums(from: tracks)), tracks.first?.artistSortName ?? name)
            }
            .sorted { $0.1.localizedStandardCompare($1.1) == .orderedAscending }
            .map(\.0)
    }

    @MainActor
    static func playlists(from playlists: [LibraryPlaylist]) -> [SyncPlaylistNode] {
        playlists.map { SyncPlaylistNode(key: $0.syncKey, name: $0.name, trackCount: $0.trackPaths.count) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func genres(from tracks: [SyncTrackSnapshot]) -> [SyncGenreNode] {
        Dictionary(grouping: tracks, by: \.genre)
            .map { name, tracks in
                SyncGenreNode(name: name, trackCount: tracks.count, byteCount: tracks.reduce(0) { $0 + $1.byteCount })
            }
            .sorted { $0.name.sortName.localizedStandardCompare($1.name.sortName) == .orderedAscending }
    }

    private static func albums(from tracks: [SyncTrackSnapshot]) -> [SyncAlbumNode] {
        Dictionary(grouping: tracks, by: \.albumKey)
            .compactMap { key, tracks in
                tracks.first.map { first in
                    (SyncAlbumNode(key: key, title: first.album, trackCount: tracks.count,
                                   byteCount: tracks.reduce(0) { $0 + $1.byteCount }), first.albumSortName)
                }
            }
            .sorted { $0.1.localizedStandardCompare($1.1) == .orderedAscending }
            .map(\.0)
    }
}
