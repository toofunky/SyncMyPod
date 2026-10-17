import Foundation

/// A podcast's RSS feed as read from the network, before it's merged into the library.
nonisolated struct PodcastFeed: Equatable, Sendable {
    var title = ""
    var author = ""
    var summary = ""
    var artworkURL: URL?
    var episodes: [PodcastFeedEpisode] = []
}
