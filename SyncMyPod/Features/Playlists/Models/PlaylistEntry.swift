import Foundation

/// One row of a playlist: its position, the file it names, and that file's library track if it's still there.
struct PlaylistEntry: Identifiable {
    let id: Int
    let path: String
    let track: LibraryTrack?

    static func entries(of playlist: LibraryPlaylist, in tracks: [LibraryTrack]) -> [PlaylistEntry] {
        let tracksByPath = Dictionary(tracks.map { ($0.filePath, $0) }, uniquingKeysWith: { first, _ in first })
        return playlist.trackPaths.enumerated().map {
            PlaylistEntry(id: $0.offset, path: $0.element, track: tracksByPath[$0.element])
        }
    }
}
