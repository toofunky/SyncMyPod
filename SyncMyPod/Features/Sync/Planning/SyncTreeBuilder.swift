import Foundation

/// Groups library tracks into the artist → album tree shown for custom syncs.
enum SyncTreeBuilder {
    static func artists(from tracks: [LibraryTrack]) -> [SyncArtistNode] {
        Dictionary(grouping: tracks, by: \.syncArtist)
            .map { name, tracks in SyncArtistNode(name: name, albums: albums(from: tracks)) }
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
