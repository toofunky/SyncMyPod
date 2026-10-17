import Foundation

/// Where an episode downloads to: `<Show>/<yyyy-MM-dd> <Title>.<ext>`, so a show's episodes sort by date.
nonisolated enum PodcastEpisodeFileNamer {
    private static let audioExtensions: Set = ["mp3", "m4a", "m4b", "mp4", "aac", "ogg", "opus", "flac", "wav"]
    private static let mimeExtensions = ["audio/mpeg": "mp3", "audio/mp3": "mp3", "audio/x-m4a": "m4a",
                                         "audio/mp4": "m4a", "audio/m4a": "m4a", "audio/aac": "aac",
                                         "audio/ogg": "ogg", "audio/opus": "opus", "audio/flac": "flac",
                                         "audio/x-m4b": "m4b", "audio/wav": "wav", "audio/x-wav": "wav"]

    static func relativePath(show: String, title: String, publishedAt: Date?, enclosure: URL,
                             mimeType: String?) -> String {
        let folder = PlayerFileNamer.safeComponent(show, fallback: "Podcast")
        let name = PlayerFileNamer.safeComponent(title, fallback: "Episode")
        let stem = publishedAt.map { "\($0.formatted(.iso8601.year().month().day())) \(name)" } ?? name
        return "\(folder)/\(stem).\(fileExtension(for: enclosure, mimeType: mimeType))"
    }

    /// The enclosure's own extension when it's audio, else one for its MIME type; MP3 is by far the most common.
    static func fileExtension(for enclosure: URL, mimeType: String?) -> String {
        let urlExtension = enclosure.pathExtension.lowercased()
        if audioExtensions.contains(urlExtension) { return urlExtension }
        return mimeType.flatMap { mimeExtensions[$0.lowercased()] } ?? "mp3"
    }

    /// `url`, or "Title (2).mp3" and so on when a file is already there.
    static func unusedURL(for url: URL) -> URL {
        var candidate = url
        var copy = 2
        while FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            candidate = URL(filePath: PlayerFileNamer.numbered(url.path(percentEncoded: false), copy: copy))
            copy += 1
        }
        return candidate
    }
}
