import Foundation

extension PodcastEpisode {
    /// A player's request has no `SyncSource`, so a copy already on it is never replaced and the player can't
    /// forget where it was. An iPod's has one, which its manifest needs to record the track; the iPod keeps its
    /// place in the database, which an update rewrites in place. `nil` for audio an iPod can't play.
    func syncRequest(show: String, author: String, forIPod: Bool = false) -> SyncRequest? {
        guard let url = downloadedFileURL else { return nil }
        let fileCodec = codec ?? Self.codec(forExtension: url.pathExtension)
        guard !forIPod || fileCodec?.syncsToIPod == true else { return nil }
        var tags = self.tags(show: show, author: author)
        tags.codec = fileCodec ?? .mp3
        let source = forIPod ? SyncSource(fileSize: tags.fileSize, modificationDate: downloadedAt ?? .distantPast,
                                          artworkFingerprint: nil) : nil
        return SyncRequest(sourceURL: url, tags: tags, source: source, kind: .podcast)
    }

    private func tags(show: String, author: String) -> TrackTags {
        let artist = author.isEmpty ? show : author
        let year = publishedAt.map { Calendar(identifier: .gregorian).component(.year, from: $0) } ?? 0
        var tags = TrackTags(title: title, artist: artist, album: show, albumArtist: artist,
                                     genre: PodcastEpisodeTags.genre, fileSize: Int(clamping: byteCount ?? 0),
                                     duration: duration ?? 0, trackNumber: episodeNumber ?? 0, year: year,
                                     bitrate: bitrate ?? 0, sampleRate: sampleRate ?? 0,
                                     dateAdded: downloadedAt ?? .now, lastModified: downloadedAt ?? .now)
        tags.releaseDate = publishedAt
        return tags
    }

    /// MP4 audio is AAC to the iPod and MP3 is MP3; anything else is unknown until the file has been read.
    private static func codec(forExtension fileExtension: String) -> AudioCodec? {
        switch fileExtension.lowercased() {
        case "mp3": .mp3
        case "m4a", "m4b", "mp4": .aac
        default: nil
        }
    }
}
