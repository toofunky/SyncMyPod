import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct IPodPositionImportTests {
    private let container = ModelContainer.makeInMemory()
    private var context: ModelContext { container.mainContext }
    private let source = SyncSource(fileSize: 1, modificationDate: .distantPast, artworkFingerprint: nil)

    private func episode(at position: TimeInterval) -> (Podcast, PodcastEpisode) {
        let podcast = Podcast(feedURL: "https://example.com/feed", title: "Show")
        context.insert(podcast)
        let episode = PodcastEpisode(guid: "1", title: "Episode", enclosureURL: "https://example.com/1.mp3")
        episode.downloadedFilePath = "/Podcasts/Show/1.mp3"
        episode.duration = 3_000
        episode.playbackPosition = position
        podcast.episodes.append(episode)
        return (podcast, episode)
    }

    private func book() -> Audiobook {
        let book = Audiobook(folderPath: "/Books/Book", title: "Book")
        context.insert(book)
        book.files = (1...3).map { number in
            let file = AudiobookFile(filePath: "/Books/Book/\(number).mp3")
            file.trackNumber = number
            file.duration = 1_000
            return file
        }
        return book
    }

    /// iPod tracks for `positions`, keyed by source path, recorded in a manifest as a sync would.
    private func iPod(_ positions: [String: TimeInterval]) -> ([ITunesTrack], SyncManifest) {
        let paths = positions.keys.sorted()
        let ids = Dictionary(uniqueKeysWithValues: paths.enumerated().map { ($1, UInt64($0 + 1)) })
        let tracks = paths.map { path in
            ITunesTrack(id: UInt32(ids[path] ?? 0), databaseID: ids[path] ?? 0, strings: [.title: path], duration: 0,
                        fileSize: 0, trackNumber: 0, trackCount: 0, discNumber: 0, discCount: 0, year: 0, bitrate: 0,
                        sampleRate: 0, rating: 0, playCount: 0, mediaType: 4, dateAdded: nil, lastPlayed: nil,
                        lastModified: nil, bookmark: positions[path] ?? 0)
        }
        let requests = paths.map { SyncRequest(sourceURL: URL(filePath: $0), tags: TrackTags(title: $0),
                                                   source: source) }
        return (tracks, SyncManifest().recording(requests, as: ids))
    }

    private func read(_ positions: [String: TimeInterval], podcasts: [Podcast] = [], books: [Audiobook] = []) {
        let (tracks, manifest) = iPod(positions)
        IPodPositionImporter(deviceID: "iPod", context: context)
            .importPositions(from: tracks, manifest: manifest, podcasts: podcasts, audiobooks: books)
    }

    @Test func anEpisodeTakesTheIPodsPositionWhenItsFurther() {
        let (podcast, episode) = episode(at: 100)
        read(["/Podcasts/Show/1.mp3": 900], podcasts: [podcast])
        #expect(episode.playbackPosition == 900)
    }

    @Test func anEpisodeKeepsSyncMyPodsPositionWhenItsFurther() {
        let (podcast, episode) = episode(at: 1_200)
        read(["/Podcasts/Show/1.mp3": 900], podcasts: [podcast])
        #expect(episode.playbackPosition == 1_200)
    }

    @Test func anUnchangedIPodPositionNeverOverridesListeningInTheApp() {
        let (podcast, episode) = episode(at: 100)
        read(["/Podcasts/Show/1.mp3": 900], podcasts: [podcast])
        episode.playbackPosition = 0
        read(["/Podcasts/Show/1.mp3": 900], podcasts: [podcast])
        #expect(episode.playbackPosition == 0)
    }

    @Test func aBookMovesToTheFurthestFileTheIPodChanged() {
        let book = book()
        read(["/Books/Book/1.mp3": 400, "/Books/Book/2.mp3": 250], books: [book])
        #expect(book.currentFilePath == "/Books/Book/2.mp3" && book.playbackPosition == 250)
    }

    @Test func aBookKeepsSyncMyPodsPlaceWhenItsFurther() {
        let book = book()
        book.currentFilePath = "/Books/Book/3.mp3"
        book.playbackPosition = 10
        read(["/Books/Book/2.mp3": 900], books: [book])
        #expect(book.currentFilePath == "/Books/Book/3.mp3" && book.playbackPosition == 10)
    }

    @Test func freshCopiesAtTheStartChangeNothing() {
        let book = book()
        book.currentFilePath = "/Books/Book/2.mp3"
        book.playbackPosition = 30
        read(["/Books/Book/1.mp3": 0], books: [book])
        #expect(book.currentFilePath == "/Books/Book/2.mp3" && book.playbackPosition == 30)
    }

    @Test func positionsSavedSinceTheLastSyncComeFromPlayCounts() {
        let (tracks, _) = iPod(["/a.mp3": 5, "/b.mp3": 0])
        let pending = IPodPositionImporter.withPendingBookmarks(tracks, playCounts: [
            PlayCountEntry(playCount: 0, lastPlayed: 0, bookmark: 0),
            PlayCountEntry(playCount: 0, lastPlayed: 0, bookmark: 42_500),
        ])
        #expect(pending.map(\.bookmark) == [5, 42.5])
        #expect(IPodPositionImporter.withPendingBookmarks(tracks, playCounts: []).map(\.bookmark) == [5, 0])
    }

    @Test func furthestAlongWins() {
        #expect(SpokenPositionMerge.episode(app: 10, device: 20, duration: 100) == 20)
        #expect(SpokenPositionMerge.episode(app: 30, device: 20, duration: 100) == nil)
        #expect(SpokenPositionMerge.episode(app: 30, device: 0, duration: 100) == 0)
        let durations: [TimeInterval] = [100, 100]
        let finishedFirst = SpokenPositionMerge.book(durations: durations, app: (0, 50), device: (0, 0))
        #expect(finishedFirst?.index == 1 && finishedFirst?.position == 0)
        let finishedBook = SpokenPositionMerge.book(durations: durations, app: (0, 50), device: (1, 0))
        #expect(finishedBook != nil && finishedBook?.index == nil)
        #expect(SpokenPositionMerge.book(durations: durations, app: (1, 50), device: (0, 70)) == nil)
    }
}
