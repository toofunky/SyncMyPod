import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct PodcastDownloadTests {
    private let container = ModelContainer.makeInMemory()
    private var context: ModelContext { container.mainContext }
    private static let releaseDate = Date(timeIntervalSince1970: 1_792_047_600)

    @Test func namesEpisodesByShowDateAndTitle() {
        let path = PodcastEpisodeFileNamer.relativePath(show: "Show: The Sequel", title: "Why? Because.",
                                                        publishedAt: Self.releaseDate,
                                                        enclosure: URL(string: "https://cdn.example.com/a.mp3?id=1")!,
                                                        mimeType: "audio/mpeg")
        #expect(path == "Show_ The Sequel/2026-10-15 Why_ Because.mp3")
    }

    @Test(arguments: [("https://x.com/a.M4A", nil, "m4a"), ("https://x.com/episode", "audio/x-m4a", "m4a"),
                      ("https://x.com/play?id=3", "audio/mpeg", "mp3"), ("https://x.com/stream.php", nil, "mp3")])
    func picksAudioExtension(_ address: String, _ mimeType: String?, _ expected: String) {
        #expect(PodcastEpisodeFileNamer.fileExtension(for: URL(string: address)!, mimeType: mimeType) == expected)
    }

    @Test func numbersNamesAlreadyTaken() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let taken = folder.appending(path: "Episode.mp3")
        try Data().write(to: taken)
        #expect(PodcastEpisodeFileNamer.unusedURL(for: taken).lastPathComponent == "Episode (2).mp3")
    }

    @Test func tagsEpisodesUnderTheirShow() {
        let tags = PodcastEpisodeTags(title: "Episode", show: "Show", author: "", publishedAt: Self.releaseDate,
                                      episodeNumber: 12, showArtwork: nil)
        let changes = tags.changes
        #expect(changes.title == "Episode")
        #expect(changes.album == "Show")
        #expect(changes.artist == "Show")
        #expect(changes.albumArtist == "Show")
        #expect(changes.genre == "Podcast")
        #expect(changes.year == 2026)
        #expect(changes.track == TagNumberPair(number: 12))
        #expect(changes.artwork == .keep)
    }

    @Test func downloadedEpisodesKeepTheirFilesDurationAndSize() {
        let episode = PodcastEpisode(guid: "a", title: "A", enclosureURL: "https://x.com/a.mp3")
        episode.downloadedFilePath = "/Podcasts/Show/a.mp3"
        episode.duration = 95
        episode.byteCount = 1_602_472
        episode.update(from: PodcastFeedEpisode(guid: "a", title: "A", summary: "", publishedAt: nil, duration: 168,
                                                enclosureURL: URL(string: "https://x.com/a.mp3")!,
                                                enclosureType: nil, byteCount: nil, episodeNumber: nil,
                                                seasonNumber: nil))
        #expect(episode.duration == 95)
        #expect(episode.byteCount == 1_602_472)
    }

    @Test func forgetsDownloadsWhoseFilesAreGone() throws {
        let podcast = Podcast(feedURL: "https://example.com/feed", title: "Show")
        context.insert(podcast)
        let episode = PodcastEpisode(guid: "a", title: "A", enclosureURL: "https://x.com/a.mp3")
        episode.downloadedFilePath = "/nonexistent/\(UUID().uuidString).mp3"
        podcast.episodes.append(episode)
        PodcastDownloads().forgetMissingFiles(of: podcast, context: context)
        #expect(!episode.isDownloaded)
    }
}
