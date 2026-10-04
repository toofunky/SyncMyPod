import Foundation

/// Writes a library playlist as an extended M3U in UTF-8.
nonisolated enum PlaylistExporter {
    /// Paths are relative to `folder`, or absolute when it's `nil`.
    static func contents(of entries: [PlaylistEntry], relativeTo folder: URL?) -> String {
        var lines = ["#EXTM3U"]
        for entry in entries {
            if let track = entry.track { lines.append(info(for: track)) }
            lines.append(folder.map { M3U8Playlist.relativePath(from: $0.path(percentEncoded: false), to: entry.path) }
                ?? entry.path)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func info(for track: LibraryTrack) -> String {
        let artist = track.artist.isEmpty ? "" : "\(track.artist) - "
        return "#EXTINF:\(Int(track.duration.rounded())),\(artist)\(track.title)"
    }
}
