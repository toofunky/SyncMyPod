import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct AudiobookPlaybackTests {
    /// Held so the context's container outlives each test.
    private let container = ModelContainer.makeInMemory()
    private var context: ModelContext { container.mainContext }

    private func book(fileCount: Int = 3) throws -> Audiobook {
        let book = Audiobook(folderPath: "/Books/Book", title: "Book")
        context.insert(book)
        book.files = (1...fileCount).map { number in
            let file = AudiobookFile(filePath: "/Books/Book/\(number).mp3")
            file.trackNumber = number
            file.title = "Part \(number)"
            return file
        }
        try context.save()
        return book
    }

    @Test func startsAtTheFileWhereListeningStopped() throws {
        let book = try book()
        book.currentFilePath = "/Books/Book/2.mp3"
        #expect(NowPlayingSpoken(book)?.currentFile.title == "Part 2")
        #expect(NowPlayingSpoken(book, startingAt: book.sortedFiles[2])?.currentFile.title == "Part 3")
    }

    @Test func unstartedBooksStartAtTheFirstFile() throws {
        #expect(NowPlayingSpoken(try book())?.currentFile.title == "Part 1")
    }

    @Test func advancesThroughTheFilesInOrder() throws {
        var nowPlaying = try #require(NowPlayingSpoken(try book(fileCount: 2)))
        let advanced = nowPlaying.advance()
        #expect(advanced)
        #expect(nowPlaying.currentFile.title == "Part 2")
        let advancedPastTheEnd = nowPlaying.advance()
        #expect(!advancedPastTheEnd)
        nowPlaying.rewind()
        #expect(nowPlaying.currentFile.title == "Part 1")
    }

    @Test func savesTheFileAndPosition() throws {
        let book = try book()
        var nowPlaying = try #require(NowPlayingSpoken(book))
        _ = nowPlaying.advance()
        SpokenPositionStore.save(nowPlaying, position: 42, in: context)
        #expect(book.currentFilePath == "/Books/Book/2.mp3")
        #expect(book.playbackPosition == 42)
    }

    @Test func savingBackAtTheStartMarksTheBookUnstarted() throws {
        let book = try book()
        book.currentFilePath = "/Books/Book/3.mp3"
        book.playbackPosition = 90
        var nowPlaying = try #require(NowPlayingSpoken(book))
        nowPlaying.rewind()
        SpokenPositionStore.save(nowPlaying, position: 0, in: context)
        #expect(book.currentFilePath == nil)
        #expect(book.playbackPosition == 0)
        #expect(!book.isStarted)
    }

    @Test func episodesStillSaveTheirPosition() throws {
        let episode = PodcastEpisode(guid: "1", title: "Episode", enclosureURL: "https://example.com/1.mp3")
        episode.downloadedFilePath = "/Podcasts/Show/1.mp3"
        context.insert(episode)
        try context.save()
        let nowPlaying = try #require(NowPlayingSpoken(episode))
        SpokenPositionStore.save(nowPlaying, position: 120, in: context)
        #expect(episode.playbackPosition == 120)
    }
}
