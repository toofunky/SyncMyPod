import Foundation
import Testing
@testable import SyncMyPod

struct PodcastFeedParserTests {
    private static let feed = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
             xmlns:media="http://search.yahoo.com/mrss/">
          <channel>
            <title>I've Had It</title>
            <itunes:author>Jennifer &amp; Angie</itunes:author>
            <description><![CDATA[<p>Two friends <b>talk</b>.</p>]]></description>
            <image><url>https://example.com/small.jpg</url><title>Not the show title</title></image>
            <itunes:image href="https://example.com/big.jpg"/>
            <item>
              <title>Episode Two</title>
              <media:title>Media Title</media:title>
              <guid isPermaLink="false">guid-2</guid>
              <pubDate>Thu, 15 Oct 2026 06:30:00 -0000</pubDate>
              <itunes:duration>55:58</itunes:duration>
              <itunes:episode>2</itunes:episode>
              <itunes:season>1</itunes:season>
              <itunes:image href="https://example.com/episode.jpg"/>
              <enclosure url="https://example.com/2.mp3" length="53000000" type="audio/mpeg"/>
            </item>
            <item>
              <title>Episode One</title>
              <enclosure url="https://example.com/1.mp3" length="0" type="audio/mpeg"/>
            </item>
            <item><title>Trailer without audio</title></item>
          </channel>
        </rss>
        """

    private func parsed() throws -> PodcastFeed {
        try PodcastFeedParser.parse(Data(Self.feed.utf8))
    }

    @Test func readsShowDetails() throws {
        let feed = try parsed()
        #expect(feed.title == "I've Had It")
        #expect(feed.author == "Jennifer & Angie")
        #expect(feed.summary == "Two friends talk.")
    }

    @Test func prefersITunesImageOverRSSImage() throws {
        #expect(try parsed().artworkURL == URL(string: "https://example.com/big.jpg"))
    }

    @Test func readsEpisodeDetails() throws {
        let episode = try #require(try parsed().episodes.first)
        #expect(episode.title == "Episode Two")
        #expect(episode.guid == "guid-2")
        #expect(episode.publishedAt == Date(timeIntervalSince1970: 1_792_045_800))
        #expect(episode.duration == 3_358)
        #expect(episode.byteCount == 53_000_000)
        #expect(episode.enclosureType == "audio/mpeg")
        #expect(episode.episodeNumber == 2)
        #expect(episode.seasonNumber == 1)
    }

    @Test func fallsBackToEnclosureForMissingGuidAndSkipsItemsWithoutAudio() throws {
        let episodes = try parsed().episodes
        #expect(episodes.map(\.guid) == ["guid-2", "https://example.com/1.mp3"])
        #expect(episodes[1].byteCount == nil)
    }

    @Test func rejectsPagesThatAreNotFeeds() {
        #expect(throws: PodcastFeedError.notAFeed) {
            try PodcastFeedParser.parse(Data("<html><body>Not a feed</body></html>".utf8))
        }
    }
}
