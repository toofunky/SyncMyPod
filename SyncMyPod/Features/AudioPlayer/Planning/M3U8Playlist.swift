import Foundation

/// An extended M3U playlist, with paths relative to the playlist's own folder.
nonisolated enum M3U8Playlist {
    /// `folder` and each entry's `path` are relative to the volume.
    static func contents(_ entries: [(tags: TrackTags, path: String)], inFolder folder: String) -> String {
        var lines = ["#EXTM3U"]
        for entry in entries {
            let artist = entry.tags.artist.isEmpty ? "" : "\(entry.tags.artist) - "
            lines.append("#EXTINF:\(Int(entry.tags.duration.rounded())),\(artist)\(entry.tags.title)")
            lines.append(relativePath(from: folder, to: entry.path))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// "../Music/Artist/Album/Song.m4a" from "Playlists" to "Music/Artist/Album/Song.m4a".
    static func relativePath(from folder: String, to path: String) -> String {
        let from = folder.split(separator: "/")
        let to = path.split(separator: "/")
        var shared = 0
        while shared < from.count, shared < to.count - 1, from[shared] == to[shared] { shared += 1 }
        let ups = Array(repeating: "..", count: from.count - shared)
        return (ups + to[shared...].map(String.init)).joined(separator: "/")
    }
}
