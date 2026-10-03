import Foundation

/// An extended M3U playlist in UTF-8, with paths relative to the playlist's own folder.
nonisolated enum M3U8Playlist {
    /// `folder` and each entry's `path` are relative to the volume.
    static func contents(_ entries: [(draft: ITunesTrackDraft, path: String)], inFolder folder: String) -> String {
        var lines = ["#EXTM3U"]
        for entry in entries {
            let artist = entry.draft.artist.isEmpty ? "" : "\(entry.draft.artist) - "
            lines.append("#EXTINF:\(Int(entry.draft.duration.rounded())),\(artist)\(entry.draft.title)")
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
