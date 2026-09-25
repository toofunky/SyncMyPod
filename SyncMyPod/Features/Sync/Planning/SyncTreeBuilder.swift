import Foundation

/// Groups library tracks into the artist → album tree, and lists the playlists, shown for custom syncs.
enum SyncTreeBuilder {
    static func artists(from tracks: [LibraryTrack]) -> [SyncArtistNode] {
        Dictionary(grouping: tracks, by: \.syncArtist)
            .map { name, tracks in SyncArtistNode(name: name, albums: albums(from: tracks)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func playlists(from playlists: [LibraryPlaylist]) -> [SyncPlaylistNode] {
        playlists.map { SyncPlaylistNode(key: $0.syncKey, name: $0.name, trackCount: $0.trackPaths.count) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func albums(from tracks: [LibraryTrack]) -> [SyncAlbumNode] {
        Dictionary(grouping: tracks, by: \.syncAlbumKey)
            .compactMap { key, tracks in
                tracks.first.map { first in
                    SyncAlbumNode(key: key, title: first.syncAlbum, trackCount: tracks.count,
                                  byteCount: tracks.reduce(0) { $0 + Int64($1.fileSize) })
                }
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}
