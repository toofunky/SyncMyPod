import Foundation
import SwiftData

/// A podcast the user has subscribed to by its RSS feed.
@Model
nonisolated final class Podcast {
    @Attribute(.unique) var podcastID: UUID
    @Attribute(.unique) var feedURL: String
    var title: String
    var author = ""
    var summary = ""
    var artworkURL: String?
    @Attribute(.externalStorage) var artworkData: Data?
    var dateAdded: Date
    var lastRefreshed: Date?
    @Relationship(deleteRule: .cascade, inverse: \PodcastEpisode.podcast) var episodes: [PodcastEpisode] = []

    init(feedURL: String, title: String) {
        podcastID = UUID()
        self.feedURL = feedURL
        self.title = title
        dateAdded = .now
    }

    /// Newest first; episodes without a release date go last.
    var sortedEpisodes: [PodcastEpisode] {
        episodes.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    static let titleOrder = [SortDescriptor(\Podcast.title, comparator: .localizedStandard)]
}

#if DEBUG
extension Podcast {
    static let preview: Podcast = {
        let podcast = Podcast(feedURL: "https://example.com/feed.xml", title: "I've Had It")
        podcast.author = "Jennifer Welch and Angie \"Pumps\" Sullivan"
        podcast.summary = "Two friends from Oklahoma talk about the news, pop culture and whatever else they've had it with."
        podcast.lastRefreshed = .now.addingTimeInterval(-1_800)
        podcast.episodes = PodcastEpisode.previewEpisodes
        return podcast
    }()
}
#endif
