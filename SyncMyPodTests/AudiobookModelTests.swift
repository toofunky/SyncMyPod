import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

@MainActor
struct AudiobookModelTests {
    /// Held so the context's container outlives each test.
    private let container = ModelContainer.makeInMemory()
    private var context: ModelContext { container.mainContext }

    private func file(_ name: String, track: Int = 0, disc: Int = 0, duration: TimeInterval = 60) -> AudiobookFile {
        let file = AudiobookFile(filePath: "/Books/Author/Book/\(name)")
        file.trackNumber = track
        file.discNumber = disc
        file.duration = duration
        return file
    }

    private func book(_ files: [AudiobookFile]) -> Audiobook {
        let book = Audiobook(folderPath: "/Books/Author/Book", title: "Book")
        context.insert(book)
        book.files = files
        return book
    }

    @Test func filesPlayByDiscThenTrackThenName() {
        let book = book([file("b.mp3", track: 2, disc: 1), file("a.mp3", track: 1, disc: 2),
                         file("c.mp3", track: 1, disc: 1)])
        #expect(book.sortedFiles.map(\.fileName) == ["c.mp3", "b.mp3", "a.mp3"])
    }

    @Test func untaggedFilesPlayInNaturalNameOrder() {
        let book = book([file("Part 10.mp3"), file("Part 2.mp3"), file("Part 1.mp3")])
        #expect(book.sortedFiles.map(\.fileName) == ["Part 1.mp3", "Part 2.mp3", "Part 10.mp3"])
    }

    @Test func elapsedCountsEarlierFilesAndThePosition() {
        let book = book([file("1.mp3", track: 1, duration: 100), file("2.mp3", track: 2, duration: 200),
                         file("3.mp3", track: 3, duration: 300)])
        #expect(book.elapsed == 0)
        book.currentFilePath = "/Books/Author/Book/3.mp3"
        book.playbackPosition = 25
        #expect(book.elapsed == 325)
        #expect(book.duration == 600)
    }

    @Test func audiobookFolderMayNotOverlapTheOtherFolders() {
        #expect(FolderOverlap.first("/Users/me/Music/Books", in: ["/Users/me/Podcasts", "/Users/me/Music"])
                == "/Users/me/Music")
        #expect(FolderOverlap.first("/Users/me/Audiobooks", in: ["/Users/me/Podcasts", "/Users/me/Music"]) == nil)
    }
}
