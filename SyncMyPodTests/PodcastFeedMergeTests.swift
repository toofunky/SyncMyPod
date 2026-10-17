import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PodcastFeedMergeTests {
    /// Held so the context's container outlives each test.
    private let container = ModelContainer.makeInMemory()
    private var context: ModelContext { container.mainContext }

    private func episode(_ guid: String, title: String? = nil) -> PodcastFeedEpisode {
        PodcastFeedEpisode(guid: guid, title: title ?? guid, summary: "", publishedAt: nil, duration: nil,
                           enclosureURL: URL(filePath: "/\(guid).mp3"), enclosureType: "audio/mpeg", byteCount: nil,
                           episodeNumber: nil, seasonNumber: nil)
    }

    private func subscribedPodcast(with guids: [String]) -> Podcast {
        let podcast = Podcast(feedURL: "https://example.com/feed", title: "")
        context.insert(podcast)
        podcast.update(from: PodcastFeed(title: "Show", episodes: guids.map { episode($0) }), in: context)
        return podcast
    }

    @Test func addsEpisodesAndShowDetails() {
        let podcast = subscribedPodcast(with: ["a", "b"])
        #expect(podcast.title == "Show")
        #expect(Set(podcast.episodes.map(\.guid)) == ["a", "b"])
        #expect(podcast.lastRefreshed != nil)
    }

    @Test func updatesExistingEpisodesInPlace() throws {
        let podcast = subscribedPodcast(with: ["a"])
        let original = try #require(podcast.episodes.first)
        podcast.update(from: PodcastFeed(title: "Show", episodes: [episode("a", title: "Renamed")]), in: context)
        #expect(podcast.episodes.count == 1)
        #expect(podcast.episodes.first === original)
        #expect(original.title == "Renamed")
    }

    @Test func keepsDownloadedEpisodesThatLeftTheFeed() throws {
        let podcast = subscribedPodcast(with: ["old", "downloaded"])
        podcast.episodes.first { $0.guid == "downloaded" }?.downloadedFileName = "downloaded.mp3"
        podcast.update(from: PodcastFeed(title: "Show", episodes: [episode("new")]), in: context)
        try context.save()
        #expect(Set(podcast.episodes.map(\.guid)) == ["new", "downloaded"])
    }

    @Test func folderMayNotOverlapTheMusicLibrary() {
        let libraries = ["/Users/me/Music"]
        #expect(PodcastFolder.overlappingLibrary("/Users/me/Music/Podcasts", libraries) == "/Users/me/Music")
        #expect(PodcastFolder.overlappingLibrary("/Users/me", libraries) == "/Users/me/Music")
        #expect(PodcastFolder.overlappingLibrary("/Users/me/Music Podcasts", libraries) == nil)
        #expect(PodcastFolder.overlappingLibrary("/Users/me/Podcasts", libraries) == nil)
    }
}
