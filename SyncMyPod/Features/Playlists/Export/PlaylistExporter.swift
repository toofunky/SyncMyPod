import Foundation

/// Writes a library playlist as an extended M3U in UTF-8, with each path as "<Artist>/<Album>/<file>".
nonisolated enum PlaylistExporter {
    static func contents(of entries: [PlaylistEntry]) -> String {
        var lines = ["#EXTM3U"]
        for entry in entries {
            if let track = entry.track { lines.append(info(for: track)) }
            lines.append(path(for: entry))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Missing tracks keep the last three components of their library path.
    private static func path(for entry: PlaylistEntry) -> String {
        guard let track = entry.track else {
            return entry.path.split(separator: "/").suffix(3).joined(separator: "/")
        }
        let tagged = track.albumArtist.isEmpty ? track.artist : track.albumArtist
        let artist = PlayerFileNamer.safeComponent(tagged, fallback: LibraryTrack.unknownArtist)
        let album = PlayerFileNamer.safeComponent(track.album, fallback: LibraryTrack.unknownAlbum)
        let fileName = PlayerFileNamer.safeComponent(URL(filePath: track.filePath).lastPathComponent, fallback: "Track")
        return [artist, album, fileName].joined(separator: "/")
    }

    private static func info(for track: LibraryTrack) -> String {
        let artist = track.artist.isEmpty ? "" : "\(track.artist) - "
        return "#EXTINF:\(Int(track.duration.rounded())),\(artist)\(track.title)"
    }
}
