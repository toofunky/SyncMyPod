import Foundation

/// Finds the library song for each entry of an imported playlist by artist, album, and file name.
nonisolated enum PlaylistImporter {
    static func match(_ paths: [String], in tracks: [LibraryTrack]) -> PlaylistImportResult {
        var index: [PlaylistEntryKey: String] = [:]
        for track in tracks {
            for key in PlaylistEntryKey.keys(for: track) where index[key] == nil {
                index[key] = track.filePath
            }
        }
        let matched = paths.compactMap { PlaylistEntryKey(path: $0).flatMap { index[$0] } }
        return PlaylistImportResult(trackPaths: matched, totalCount: paths.count)
    }
}
