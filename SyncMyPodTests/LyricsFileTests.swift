import Foundation
import Testing
@testable import SyncMyPod

struct LyricsFileTests {
    let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    @Test func writesBesideSongWithSongsName() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let song = folder.appending(path: "01 Mr. Brightside.mp3").path(percentEncoded: false)
        try await LyricsFile.write("[00:01]Coming out of my cage", forSongAt: song)
        #expect(names() == ["01 Mr. Brightside.lrc"])
        #expect(try await LyricsFile.read(forSongAt: song) == "[00:01]Coming out of my cage")
    }

    @Test func replacesExistingFileRegardlessOfCase() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data("old".utf8).write(to: folder.appending(path: "clocks.LRC"))
        let song = folder.appending(path: "Clocks.m4a").path(percentEncoded: false)
        #expect(try await LyricsFile.read(forSongAt: song) == "old")
        try await LyricsFile.write("new", forSongAt: song)
        #expect(names() == ["clocks.LRC"])
        #expect(try await LyricsFile.read(forSongAt: song) == "new")
    }

    @Test func removesFileAndReadsNilWhenMissing() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data("old".utf8).write(to: folder.appending(path: "Clocks.lrc"))
        let song = folder.appending(path: "Clocks.m4a").path(percentEncoded: false)
        try await LyricsFile.remove(forSongAt: song)
        #expect(names().isEmpty)
        #expect(try await LyricsFile.read(forSongAt: song) == nil)
    }

    @Test func indexMatchesSongsRegardlessOfCase() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data().write(to: folder.appending(path: "CLOCKS.lrc"))
        let clocks = folder.appending(path: "Clocks.m4a").path(percentEncoded: false)
        let yellow = folder.appending(path: "Yellow.m4a").path(percentEncoded: false)
        let index = LyricsFileIndex(besideSongsAt: [clocks, yellow])
        #expect(index.hasLyrics(forSongAt: clocks))
        #expect(!index.hasLyrics(forSongAt: yellow))
    }

    private func names() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))) ?? []
    }
}
