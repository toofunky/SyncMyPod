import Foundation
import Testing
@testable import SyncMyPod

struct AudioFileEnumeratorTests {
    @Test func findsM4AAndMP3FilesRecursivelyAndSkipsOthers() throws {
        let folder = try AudioFixtureWriter.makeTemporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["a.m4a", "Album/b.M4A", "c.mp3", "Album/d.MP3", "e.flac", ".hidden.mp3", "notes.txt"] {
            let url = folder.appending(path: name)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try Data([1, 2, 3]).write(to: url)
        }
        let names = try AudioFileEnumerator().files(in: folder).map(\.url.lastPathComponent)
        #expect(Set(names) == ["a.m4a", "b.M4A", "c.mp3", "d.MP3"])
    }

    @Test func throwsForMissingFolder() {
        let missing = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        #expect(throws: (any Error).self) { try AudioFileEnumerator().files(in: missing) }
    }
}
