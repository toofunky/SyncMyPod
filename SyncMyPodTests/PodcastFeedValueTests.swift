import Foundation
import Testing
@testable import SyncMyPod

struct PodcastFeedValueTests {
    private static let releaseDate = Date(timeIntervalSince1970: 1_792_047_600)

    @Test(arguments: ["Thu, 15 Oct 2026 07:00:00 -0000", "Thu, 15 Oct 2026 07:00:00 GMT",
                      "Thu, 15 Oct 2026 03:00:00 EDT", "Thu, 15 Oct 2026 07:00 +0000", "15 Oct 2026 07:00:00 +0000",
                      "2026-10-15T07:00:00Z"])
    func parsesPublishedDateVariants(_ string: String) {
        #expect(PodcastDateParser.date(from: string) == Self.releaseDate)
    }

    @Test func unreadableDateIsNil() {
        #expect(PodcastDateParser.date(from: "last Tuesday") == nil)
    }

    @Test(arguments: [("3358", 3_358.0), ("55:58", 3_358), ("0:55:58", 3_358), ("1:02:03", 3_723), ("12.5", 12.5)])
    func parsesDurations(_ string: String, _ seconds: TimeInterval) {
        #expect(PodcastDuration.seconds(from: string) == seconds)
    }

    @Test(arguments: ["", "0", "a:b", "1:2:3:4", "-5"])
    func rejectsUnusableDurations(_ string: String) {
        #expect(PodcastDuration.seconds(from: string) == nil)
    }

    @Test(arguments: [("feeds.megaphone.fm/QCD4689752698", "https://feeds.megaphone.fm/QCD4689752698"),
                      ("  https://example.com/feed.xml\n", "https://example.com/feed.xml"),
                      ("feed://example.com/rss", "https://example.com/rss"),
                      ("pcast://example.com/rss", "https://example.com/rss")])
    func normalizesFeedAddresses(_ typed: String, _ expected: String) throws {
        #expect(try PodcastFeedClient.feedURL(from: typed).absoluteString == expected)
    }

    @Test(arguments: ["", "not a url", "ftp://example.com/feed"])
    func rejectsInvalidFeedAddresses(_ typed: String) {
        #expect(throws: PodcastFeedError.invalidURL) { try PodcastFeedClient.feedURL(from: typed) }
    }
}
