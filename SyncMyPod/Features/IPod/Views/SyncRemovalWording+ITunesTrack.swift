import Foundation

nonisolated extension SyncRemovalWording {
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
}
