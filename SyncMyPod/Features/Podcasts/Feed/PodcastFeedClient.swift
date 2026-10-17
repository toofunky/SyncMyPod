import Foundation

/// Fetches podcast feeds and their show artwork.
nonisolated enum PodcastFeedClient {
    /// Large enough for the app and iPod artwork; feeds often publish 3000-pixel squares.
    static let artworkPixelLimit = 600

    /// The address as typed or pasted, with podcast-app schemes such as `feed:` and `pcast:` turned into HTTPS.
    static func feedURL(from text: String) throws -> URL {
        var address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for scheme in ["feed://", "pcast://", "itpc://", "podcast://"] where address.lowercased().hasPrefix(scheme) {
            address = "https://" + address.dropFirst(scheme.count)
        }
        if !address.contains("://") { address = "https://" + address }
        guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased()),
              url.host()?.contains(".") == true else {
            throw PodcastFeedError.invalidURL
        }
        return url
    }

    @concurrent
    static func fetchFeed(_ url: URL) async throws -> PodcastFeed {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            throw PodcastFeedError.httpStatus(status)
        }
        return try PodcastFeedParser.parse(data)
    }

    /// The show's artwork scaled to `artworkPixelLimit`, or `nil` if it can't be fetched or read.
    @concurrent
    static func fetchArtwork(_ url: URL) async -> Data? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return (try? CoverResizer.fitted(data, within: artworkPixelLimit)) ?? data
    }
}
