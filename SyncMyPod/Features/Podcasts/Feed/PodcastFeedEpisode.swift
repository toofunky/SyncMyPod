import Foundation

/// One `<item>` from a podcast feed. Items without an audio enclosure are left out of the feed.
nonisolated struct PodcastFeedEpisode: Equatable, Sendable {
    let guid: String
    let title: String
    let summary: String
    let publishedAt: Date?
    let duration: TimeInterval?
    let enclosureURL: URL
    let enclosureType: String?
    let byteCount: Int64?
    let episodeNumber: Int?
    let seasonNumber: Int?
}
