import Foundation

extension PodcastEpisode {
    /// Without a `SyncSource`, a copy already on the player is never replaced, so rewriting it can't make the
    /// player forget where it was in the episode.
    func syncRequest(show: String, author: String) -> IPodSyncRequest? {
        guard let url = downloadedFileURL else { return nil }
        let artist = author.isEmpty ? show : author
        let year = publishedAt.map { Calendar(identifier: .gregorian).component(.year, from: $0) } ?? 0
        let draft = ITunesTrackDraft(title: title, artist: artist, album: show, albumArtist: artist,
                                     genre: PodcastEpisodeTags.genre, fileSize: Int(clamping: byteCount ?? 0),
                                     duration: duration ?? 0, trackNumber: episodeNumber ?? 0, year: year,
                                     dateAdded: publishedAt ?? .now, lastModified: publishedAt ?? .now,
                                     codec: Self.codec(forExtension: url.pathExtension))
        return IPodSyncRequest(sourceURL: url, draft: draft, isPodcast: true)
    }

    /// MP4 audio is tagged and copied as AAC; anything else is treated as MP3, by far the most common.
    private static func codec(forExtension fileExtension: String) -> AudioCodec {
        ["m4a", "m4b", "mp4", "aac"].contains(fileExtension.lowercased()) ? .aac : .mp3
    }
}
