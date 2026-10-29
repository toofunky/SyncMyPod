import Foundation

nonisolated extension PodcastEpisode {
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
