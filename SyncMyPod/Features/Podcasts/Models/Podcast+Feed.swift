import Foundation
import SwiftData

nonisolated extension Podcast {
    /// Takes the feed's show details and merges its episodes by guid. Episodes that dropped out of the feed are
    /// kept only while they're downloaded, since many feeds list just their latest episodes.
    func update(from feed: PodcastFeed, in context: ModelContext) {
        title = feed.title
        author = feed.author
        summary = feed.summary
        artworkURL = feed.artworkURL?.absoluteString
        lastRefreshed = .now
        mergeEpisodes(feed.episodes, in: context)
    }

    private func mergeEpisodes(_ feedEpisodes: [PodcastFeedEpisode], in context: ModelContext) {
        var existing = Dictionary(episodes.map { ($0.guid, $0) }, uniquingKeysWith: { first, _ in first })
        for feedEpisode in feedEpisodes {
            if let episode = existing.removeValue(forKey: feedEpisode.guid) {
                episode.update(from: feedEpisode)
            } else {
                let episode = PodcastEpisode(guid: feedEpisode.guid, title: feedEpisode.title,
                                             enclosureURL: feedEpisode.enclosureURL.absoluteString)
                episode.update(from: feedEpisode)
                episodes.append(episode)
            }
        }
        for stale in existing.values where !stale.isDownloaded {
            context.delete(stale)
        }
    }
}
