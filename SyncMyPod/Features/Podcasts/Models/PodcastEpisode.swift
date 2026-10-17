import Foundation
import SwiftData

/// One episode listed in a podcast's feed.
@Model
nonisolated final class PodcastEpisode {
    /// The feed's `guid`, or the enclosure URL when the feed has none. Unique within its podcast.
    var guid: String
    var title: String
    var summary = ""
    var publishedAt: Date?
    var duration: TimeInterval?
    var enclosureURL: String
    var enclosureType: String?
    var byteCount: Int64?
    var episodeNumber: Int?
    var seasonNumber: Int?
    /// The downloaded file's full path, or `nil` when it hasn't been downloaded. Absolute, so choosing another
    /// download folder only affects new downloads.
    var downloadedFilePath: String?
    var podcast: Podcast?

    init(guid: String, title: String, enclosureURL: String) {
        self.guid = guid
        self.title = title
        self.enclosureURL = enclosureURL
    }

    var isDownloaded: Bool { downloadedFilePath != nil }

    var downloadedFileURL: URL? { downloadedFilePath.map { URL(filePath: $0) } }

    /// A downloaded episode keeps the duration and size read from its file, which feeds often get wrong.
    func update(from episode: PodcastFeedEpisode) {
        title = episode.title
        summary = episode.summary
        publishedAt = episode.publishedAt
        enclosureURL = episode.enclosureURL.absoluteString
        enclosureType = episode.enclosureType
        episodeNumber = episode.episodeNumber
        seasonNumber = episode.seasonNumber
        if !isDownloaded {
            duration = episode.duration
            byteCount = episode.byteCount
        }
    }
}

#if DEBUG
extension PodcastEpisode {
    static var previewEpisodes: [PodcastEpisode] {
        ["Kelly Clarkson Flips the Bird", "The Week That Was", "Ask Us Anything"].enumerated().map { index, title in
            let episode = PodcastEpisode(guid: "preview-\(index)", title: title,
                                         enclosureURL: "https://example.com/\(index).mp3")
            episode.publishedAt = .now.addingTimeInterval(-Double(index) * 604_800)
            episode.duration = 3_358 - Double(index) * 420
            episode.byteCount = 53_000_000 - Int64(index) * 6_000_000
            episode.downloadedFilePath = index == 1 ? "/Users/me/Podcasts/I've Had It/The Week That Was.mp3" : nil
            return episode
        }
    }
}
#endif
