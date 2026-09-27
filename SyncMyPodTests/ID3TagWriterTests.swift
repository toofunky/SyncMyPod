import CryptoKit
import Foundation
import Testing
@testable import SyncMyPod

struct ID3TagWriterTests {
    let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    private static let fixtureTags = ["TIT2": "Float On", "TPE1": "Modest Mouse", "TALB": "Good News",
                                      "TPE2": "Various", "TCON": "Indie", "TYER": "2004",
                                      "TRCK": "3/16", "TPOS": "1/2", "TCOM": "Isaac Brock"]

    @Test func growsTheTagAndKeepsEverythingElse() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), seconds: 2,
                                             tags: Self.fixtureTags)
        let audio = try Self.audioAfterTag(of: url)

        try ID3TagWriter().write(TagChanges(title: "Float On (Remastered) ☃︎", disc: TagNumberPair(number: 2, count: 2)),
                                 to: url)

        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.tags.title == "Float On (Remastered) ☃︎")
        #expect(metadata.tags.disc == TagNumberPair(number: 2, count: 2))
        #expect(metadata.tags.artist == "Modest Mouse" && metadata.tags.year == 2004)
        #expect(metadata.tags.track == TagNumberPair(number: 3, count: 16))
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(try Self.audioAfterTag(of: url) == audio)
        #expect(try Self.frameIDs(of: url).contains("TCOM"))
    }

    @Test func replacesAndRemovesTheComposer() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), tags: Self.fixtureTags)

        try ID3TagWriter().write(TagChanges(composer: "Brock/Green"), to: url)
        #expect(try #require(try await AudioMetadataReader().read(url)).tags.composer == "Brock/Green")

        try ID3TagWriter().write(TagChanges(composer: ""), to: url)
        #expect(try #require(try await AudioMetadataReader().read(url)).tags.composer == nil)
        #expect(try !Self.frameIDs(of: url).contains("TCOM"))
    }

    @Test func rewritesInPlaceWhenThePaddingFits() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), tags: Self.fixtureTags)
        try ID3TagWriter().write(TagChanges(album: "Good News for People Who Love Bad News"), to: url)
        let size = try Self.fileSize(of: url)

        try ID3TagWriter().write(TagChanges(album: "Good News", genre: "", year: 0), to: url)

        #expect(try Self.fileSize(of: url) == size)
        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.album == "Good News" && tags.genre == nil && tags.year == nil)
        #expect(tags.title == "Float On")
    }

    @Test func tagsAnUntaggedFile() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"))
        let audio = try Data(contentsOf: url)

        try ID3TagWriter().write(TagChanges(title: "New", track: TagNumberPair(number: 5)), to: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "New" && tags.track == TagNumberPair(number: 5))
        #expect(try Self.audioAfterTag(of: url) == audio)
    }

    @Test func keepsVersion4TagsAndReplacesRecordingTime() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "song.mp3")
        try MP3FixtureWriter.write(to: url)
        let audio = try Data(contentsOf: url)
        try (Self.version4Tag(["TIT2": "Old", "TDRC": "1999-01-01", "TCOM": "Somebody"]) + audio).write(to: url)

        try ID3TagWriter().write(TagChanges(year: 2004), to: url)

        #expect(try Data(contentsOf: url)[3] == 4)
        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.year == 2004 && tags.title == "Old")
        #expect(try Self.frameIDs(of: url) == ["TIT2", "TDRC", "TCOM"])
        #expect(try Self.audioAfterTag(of: url) == audio)
    }

    @Test func setsAndRemovesArtwork() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"), tags: Self.fixtureTags)
        let image = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(1, 0, 0)))

        try ID3TagWriter().write(TagChanges(artwork: .replace(image)), to: url)
        let fingerprint = SHA256.hash(data: image).map { String(format: "%02x", $0) }.joined()
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == fingerprint)

        try ID3TagWriter().write(TagChanges(artwork: .remove), to: url)
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == nil)
    }

    /// A v2.4 tag with synchsafe frame sizes and Latin-1 text.
    private static func version4Tag(_ frames: KeyValuePairs<String, String>) -> Data {
        var body = Data()
        for (id, value) in frames {
            let text = Data([0]) + Data(value.utf8)
            body.append(Data(id.utf8) + Synchsafe.encode(text.count) + [0, 0] + text)
        }
        return Data("ID3".utf8) + [4, 0, 0] + Synchsafe.encode(body.count) + body
    }

    private static func frameIDs(of url: URL) throws -> [String] {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try ID3TagParser.parse(handle).frames.map(\.id.description)
    }

    private static func audioAfterTag(of url: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let length = try ID3TagParser.parse(handle).existingLength
        return try Data(contentsOf: url).dropFirst(length)
    }

    private static func fileSize(of url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
}
