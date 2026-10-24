import Foundation

/// The question a sync asks before removing songs, podcast episodes and audiobook files from a device.
nonisolated enum SyncRemovalWording {
    /// "Remove 2 songs and 1 episode from the iPod?"
    static func title(songs: Int, episodes: Int, audiobookFiles: Int = 0, deviceKind: String) -> String {
        let counts = [count(songs, "song"), count(episodes, "episode"), count(audiobookFiles, "audiobook file")]
            .compactMap { $0 }
        return "Remove \(counts.isEmpty ? "0 songs" : counts.joined(separator: " and ")) from the \(deviceKind)?"
    }

    static func title(removing tracks: [ITunesTrack], deviceKind: String) -> String {
        let episodes = tracks.count { ($0.mediaType ?? 0) & TrackRecordBuilder.podcastMediaType != 0 }
        let books = tracks.count { ($0.mediaType ?? 0) & TrackRecordBuilder.audiobookMediaType != 0 }
        return title(songs: tracks.count - episodes - books, episodes: episodes, audiobookFiles: books,
                     deviceKind: deviceKind)
    }

    /// "Vertigo — U2" for each track, up to `limit`, then "and 3 more".
    static func listing(_ tracks: [ITunesTrack], limit: Int) -> [String] {
        let listed = tracks.prefix(limit).map { "\($0.title) — \($0.artist)" }
        let remainder = tracks.count - listed.count
        return listed + (remainder > 0 ? ["and \(remainder) more"] : [])
    }

    private static func count(_ number: Int, _ noun: String) -> String? {
        number == 0 ? nil : "\(number) \(noun)\(number == 1 ? "" : "s")"
    }
}
