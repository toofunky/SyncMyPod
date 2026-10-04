import AVFoundation
import CryptoKit
import Foundation
import Testing
@testable import SyncMyPod

struct FLACTagWriterTests {
    let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    private func makeFLAC(seconds: Double = 1) throws -> URL {
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.flac"), format: kAudioFormatFLAC,
                                            seconds: seconds)
    }

    @Test func readsFLACAsItsOwnCodec() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC(seconds: 2)
        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.codec == .flac && !metadata.codec.syncsToIPod)
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.sampleRate == 44_100)
    }

    @Test func writesTagsAndKeepsTheAudio() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC()
        let audio = try Self.audioAfterMetadata(of: url)

        try FLACTagWriter().write(TagChanges(title: "Clocks ☃︎", artist: "Coldplay", album: "Rush",
                                             albumArtist: "Coldplay", composer: "Chris", genre: "Rock",
                                             year: 2002, track: TagNumberPair(number: 5, count: 11),
                                             disc: TagNumberPair(number: 1, count: 2), sortTitle: "Clocks",
                                             sortAlbumArtist: "Coldplay"), to: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Clocks ☃︎" && tags.artist == "Coldplay" && tags.album == "Rush")
        #expect(tags.albumArtist == "Coldplay" && tags.composer == "Chris" && tags.genre == "Rock")
        #expect(tags.year == 2002 && tags.sortTitle == "Clocks" && tags.sortAlbumArtist == "Coldplay")
        #expect(tags.track == TagNumberPair(number: 5, count: 11))
        #expect(tags.disc == TagNumberPair(number: 1, count: 2))
        #expect(try Self.audioAfterMetadata(of: url) == audio)
    }

    @Test func removesTagsAndRewritesInPlaceWhenThePaddingFits() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC()
        try FLACTagWriter().write(TagChanges(title: "Float On", album: "Good News for People Who Love Bad News",
                                             genre: "Indie", track: TagNumberPair(number: 3, count: 16)), to: url)
        let size = try Self.fileSize(of: url)

        try FLACTagWriter().write(TagChanges(album: "Good News", genre: "", track: TagNumberPair()), to: url)

        #expect(try Self.fileSize(of: url) == size)
        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.album == "Good News" && tags.genre == nil && tags.track == TagNumberPair())
        #expect(tags.title == "Float On")
        #expect(try !Self.comments(of: url).contains { $0.hasPrefix("TRACKTOTAL=") })
    }

    @Test func readsOtherTaggersFieldNames() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC()
        try Self.setComments(["title=Lower", "Album Artist=Spaced", "TRACKNUMBER=2", "TOTALTRACKS=9",
                              "DISCNUMBER=1/3", "YEAR=1999"], in: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Lower" && tags.albumArtist == "Spaced" && tags.year == 1999)
        #expect(tags.track == TagNumberPair(number: 2, count: 9))
        #expect(tags.disc == TagNumberPair(number: 1, count: 3))
    }

    @Test func replacesOtherTaggersFieldNames() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC()
        try Self.setComments(["Album Artist=Old", "TOTALTRACKS=9", "TRACKNUMBER=2", "COMMENT=Kept"], in: url)

        try FLACTagWriter().write(TagChanges(albumArtist: "New", track: TagNumberPair(number: 4, count: 12)), to: url)

        #expect(try Self.comments(of: url) == ["ALBUMARTIST=New", "TRACKTOTAL=12", "TRACKNUMBER=4", "COMMENT=Kept"])
    }

    @Test func setsAndRemovesArtwork() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFLAC()
        let audio = try Self.audioAfterMetadata(of: url)
        let image = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(1, 0, 0)))

        try FLACTagWriter().write(TagChanges(artwork: .replace(image)), to: url)
        let fingerprint = SHA256.hash(data: image).map { String(format: "%02x", $0) }.joined()
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == fingerprint)
        #expect(try await CoverArtReader().read(url)?.image.width == 8)

        try FLACTagWriter().write(TagChanges(artwork: .remove), to: url)
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == nil)
        #expect(try Self.audioAfterMetadata(of: url) == audio)
    }

    @Test func rejectsFilesThatArentFLAC() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        #expect(throws: TagWriterError.self) { try FLACTagWriter().write(TagChanges(title: "X"), to: url) }
    }

    private static func setComments(_ comments: [String], in url: URL) throws {
        var metadata = try metadata(of: url)
        var comment = VorbisComment()
        comment.comments = comments
        metadata.setVorbisComment(comment)
        let data = metadata.serialized(minimumLength: 0)
        try FileRegionReplacer(url: url).replace(0..<metadata.existingLength, with: data)
    }

    private static func comments(of url: URL) throws -> [String] {
        try metadata(of: url).vorbisComment.comments
    }

    private static func metadata(of url: URL) throws -> FLACMetadata {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try FLACMetadataParser.parse(handle)
    }

    private static func audioAfterMetadata(of url: URL) throws -> Data {
        try Data(contentsOf: url).dropFirst(metadata(of: url).existingLength)
    }

    private static func fileSize(of url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
}
