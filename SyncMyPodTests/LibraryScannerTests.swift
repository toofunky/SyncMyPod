import AVFoundation
import SwiftData
import Testing
@testable import SyncMyPod

struct LibraryScannerTests {
    let folder: URL
    let container: ModelContainer

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
        container = try ModelContainer(for: Schema(MusicLibrarySchema.models),
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func addsAACALACAndMP3FilesAndSkipsOthers() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "Artist/one.m4a"))
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "two.m4a"),
                                            format: kAudioFormatAppleLossless)
        try MP3FixtureWriter.write(to: folder.appending(path: "three.mp3"))
        try Data("not audio".utf8).write(to: folder.appending(path: "broken.mp3"))

        let summary = try await scan()
        #expect(summary == LibraryScanSummary(added: 3, skipped: 1))
        #expect(try tracks().map(\.title) == ["one", "three", "two"])
        #expect(try tracks().map(\.codec) == [.aac, .mp3, .alac])
    }

    @Test func rescanDetectsUnchangedModifiedAndRemovedFiles() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let one = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "one.m4a"))
        let two = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "two.m4a"))
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "three.m4a"))
        _ = try await scan()

        try FileManager.default.removeItem(at: one)
        try FileManager.default.setAttributes([.modificationDate: Date.now.addingTimeInterval(60)],
                                              ofItemAtPath: two.path)
        let summary = try await scan()
        #expect(summary == LibraryScanSummary(updated: 1, unchanged: 1, removed: 1))
        #expect(try tracks().map(\.title) == ["three", "two"])
    }

    @Test func updatesCodecWhenFileIsReencoded() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        _ = try await scan()

        try FileManager.default.removeItem(at: url)
        try AudioFixtureWriter.writeSilence(to: url, format: kAudioFormatAppleLossless, seconds: 2)
        #expect(try await scan() == LibraryScanSummary(updated: 1))
        #expect(try tracks().map(\.codec) == [.alac])
    }

    @Test func removesTrackWhenFileIsNoLongerReadable() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"))
        _ = try await scan()

        try Data("not audio".utf8).write(to: url)
        #expect(try await scan() == LibraryScanSummary(removed: 1))
        #expect(try tracks().isEmpty)
    }

    private func scan() async throws -> LibraryScanSummary {
        try await LibraryScanner(modelContainer: container).scan(folderURL: folder) { _ in }
    }

    private func tracks() throws -> [LibraryTrack] {
        let descriptor = FetchDescriptor<LibraryTrack>(sortBy: [SortDescriptor(\.title)])
        return try ModelContext(container).fetch(descriptor)
    }
}
