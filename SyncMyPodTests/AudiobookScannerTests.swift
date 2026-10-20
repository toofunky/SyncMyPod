import Foundation
import SwiftData
import Testing
@testable import SyncMyPod

struct AudiobookScannerTests {
    let folder: URL
    let container: ModelContainer

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
        container = try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func findsFolderBooksAndM4BBooks() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Shelley/Frankenstein/01.m4a"))
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Shelley/Frankenstein/02.m4a"))
        try writeM4B(at: "Austen/Emma.m4b")

        #expect(try await scan() == LibraryScanSummary(added: 3))
        let books = try books()
        #expect(books.map(\.title) == ["Emma", "Frankenstein"])
        #expect(books.map(\.author) == ["Austen", "Shelley"])
        #expect(books.map { $0.files.count } == [1, 2])
    }

    @Test func rescanKeepsTheListeningPositionUnlessItsFileIsGone() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Book/01.m4a"))
        let second = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Book/02.m4a"))
        _ = try await scan()
        try savePosition(inFileNamed: "02.m4a", at: 30)

        #expect(try await scan() == LibraryScanSummary(unchanged: 2))
        #expect(try books().first?.playbackPosition == 30)

        try FileManager.default.removeItem(at: second)
        #expect(try await scan() == LibraryScanSummary(unchanged: 1, removed: 1))
        #expect(try books().first?.currentFilePath == nil)
        #expect(try books().first?.files.count == 1)
    }

    @Test func removesBooksWhoseFilesAreGone() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Book/01.m4a"))
        _ = try await scan()
        try FileManager.default.removeItem(at: file)
        _ = try await scan()
        #expect(try books().isEmpty)
        #expect(try ModelContext(container).fetch(FetchDescriptor<AudiobookFile>()).isEmpty)
    }

    private func writeM4B(at path: String) throws {
        let m4a = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "temporary.m4a"))
        let m4b = folder.appending(path: path)
        try FileManager.default.createDirectory(at: m4b.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: m4a, to: m4b)
    }

    private func savePosition(inFileNamed name: String, at position: TimeInterval) throws {
        let context = ModelContext(container)
        let book = try #require(try context.fetch(FetchDescriptor<Audiobook>()).first)
        book.currentFilePath = try #require(book.files.first { $0.fileName == name }).filePath
        book.playbackPosition = position
        try context.save()
    }

    private func scan() async throws -> LibraryScanSummary {
        try await AudiobookScanner(modelContainer: container).scan(folderURL: folder) { _ in }
    }

    private func books() throws -> [Audiobook] {
        try ModelContext(container).fetch(FetchDescriptor<Audiobook>(sortBy: Audiobook.titleOrder))
    }
}
