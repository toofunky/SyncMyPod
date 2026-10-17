import Foundation
import Observation
import SwiftData

/// Subscribes to and refreshes podcasts, shared app-wide so refreshes keep running when the view changes.
@MainActor
@Observable
final class PodcastsModel {
    /// Feed URLs being fetched right now.
    private(set) var refreshingFeeds: Set<String> = []
    /// The last refresh failure for each feed URL, cleared when it next succeeds.
    private(set) var refreshErrors: [String: String] = [:]

    var isRefreshingAny: Bool { !refreshingFeeds.isEmpty }

    func isRefreshing(_ podcast: Podcast) -> Bool { refreshingFeeds.contains(podcast.feedURL) }

    /// Fetches the feed first, so a mistyped address never adds a podcast.
    func subscribe(to address: String, in context: ModelContext) async throws -> Podcast {
        let url = try PodcastFeedClient.feedURL(from: address)
        if let existing = Self.podcast(feedURL: url.absoluteString, in: context) {
            throw PodcastFeedError.alreadySubscribed(existing.title)
        }
        let feed = try await PodcastFeedClient.fetchFeed(url)
        let podcast = Podcast(feedURL: url.absoluteString, title: feed.title)
        context.insert(podcast)
        podcast.update(from: feed, in: context)
        try? context.save()
        await updateArtwork(of: podcast, from: feed)
        return podcast
    }

    func refresh(_ podcast: Podcast, in context: ModelContext) async {
        await refresh([podcast], in: context)
    }

    func refreshAll(in context: ModelContext) async {
        await refresh((try? context.fetch(FetchDescriptor<Podcast>())) ?? [], in: context)
    }

    /// Fetches the feeds in parallel, then merges each into its podcast here on the main actor.
    private func refresh(_ podcasts: [Podcast], in context: ModelContext) async {
        let pending = podcasts.filter { refreshingFeeds.insert($0.feedURL).inserted }
        let results = await Self.fetchFeeds(pending.map(\.feedURL))
        for podcast in pending {
            refreshingFeeds.remove(podcast.feedURL)
            guard let result = results[podcast.feedURL] else { continue }
            await apply(result, to: podcast, in: context)
        }
        try? context.save()
    }

    private func apply(_ result: Result<PodcastFeed, any Error>, to podcast: Podcast, in context: ModelContext) async {
        switch result {
        case .success(let feed):
            let artworkChanged = feed.artworkURL?.absoluteString != podcast.artworkURL || podcast.artworkData == nil
            podcast.update(from: feed, in: context)
            refreshErrors[podcast.feedURL] = nil
            if artworkChanged { await updateArtwork(of: podcast, from: feed) }
        case .failure(let error):
            refreshErrors[podcast.feedURL] = error.localizedDescription
        }
    }

    private static func fetchFeeds(_ feedURLs: [String]) async -> [String: Result<PodcastFeed, any Error>] {
        await withTaskGroup(of: (String, Result<PodcastFeed, any Error>).self) { group in
            for feedURL in feedURLs {
                group.addTask {
                    do {
                        guard let url = URL(string: feedURL) else { throw PodcastFeedError.invalidURL }
                        return (feedURL, .success(try await PodcastFeedClient.fetchFeed(url)))
                    } catch {
                        return (feedURL, .failure(error))
                    }
                }
            }
            return await group.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }
    }

    func unsubscribe(from podcast: Podcast, in context: ModelContext) {
        refreshErrors[podcast.feedURL] = nil
        context.delete(podcast)
        try? context.save()
    }

    private func updateArtwork(of podcast: Podcast, from feed: PodcastFeed) async {
        guard let url = feed.artworkURL, let data = await PodcastFeedClient.fetchArtwork(url) else { return }
        podcast.artworkData = data
    }

    private static func podcast(feedURL: String, in context: ModelContext) -> Podcast? {
        let descriptor = FetchDescriptor<Podcast>(predicate: #Predicate { $0.feedURL == feedURL })
        return try? context.fetch(descriptor).first
    }
}
