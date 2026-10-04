import AVFoundation
import CryptoKit
import Foundation
import Testing
@testable import SyncMyPod

struct ChunkedID3TagWriterTests {
    let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    private func makeFile(_ ext: String, seconds: Double = 1) throws -> URL {
        try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.\(ext)"), format: kAudioFormatLinearPCM,
                                            seconds: seconds)
    }

    @Test(arguments: [("wav", SyncMyPod.AudioCodec.wav), ("aiff", .aiff), ("aif", .aiff)])
    func readsPCMAsItsContainersCodec(ext: String, codec: SyncMyPod.AudioCodec) async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let metadata = try #require(try await AudioMetadataReader().read(try makeFile(ext, seconds: 2)))
        #expect(metadata.codec == codec && !metadata.codec.syncsToIPod)
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(metadata.bitrate == 1_411)
    }

    @Test func otherAudioInTheseContainersIsNotSupported() {
        #expect(SyncMyPod.AudioCodec(.mpegLayer3, fileExtension: "wav") == nil)
        #expect(SyncMyPod.AudioCodec(.linearPCM, fileExtension: "AIFF") == .aiff)
        #expect(SyncMyPod.AudioCodec(.mpegLayer3, fileExtension: "mp3") == .mp3)
    }

    @Test(arguments: ["wav", "aiff"])
    func addsATagChunkAndKeepsTheAudio(ext: String) async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFile(ext)
        let audio = try Self.audio(of: url)

        try ChunkedID3TagWriter().write(TagChanges(title: "Clocks ☃︎", artist: "Coldplay", album: "Rush",
                                                   year: 2002, track: TagNumberPair(number: 5, count: 11)), to: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Clocks ☃︎" && tags.artist == "Coldplay" && tags.album == "Rush")
        #expect(tags.year == 2002 && tags.track == TagNumberPair(number: 5, count: 11))
        #expect(try Self.audio(of: url) == audio)
        try Self.expectConsistentLayout(of: url)
    }

    @Test(arguments: ["wav", "aiff"])
    func rewritesInPlaceWhenThePaddingFits(ext: String) async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFile(ext)
        try ChunkedID3TagWriter().write(TagChanges(title: "Float On", album: "Good News for People Who Love Bad News",
                                                   genre: "Indie"), to: url)
        let size = try Self.fileSize(of: url)

        try ChunkedID3TagWriter().write(TagChanges(album: "Good News", genre: ""), to: url)

        #expect(try Self.fileSize(of: url) == size)
        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.album == "Good News" && tags.genre == nil && tags.title == "Float On")
        #expect(try Self.layout(of: url).chunks.filter { $0.id.uppercased() == "ID3 " }.count == 1)
    }

    @Test func growsAChunkBeforeTheAudio() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFile("wav")
        let original = try Data(contentsOf: url)
        let tag = ID3Tag(frames: [ID3FrameBuilder.text(.id3Title, "Old")]).serialized(minimumLength: 0)
        let chunk = AudioChunkFormat.riff.chunk(id: "id3 ", body: tag)
        try Self.rebuild(url, from: original, inserting: chunk, at: AudioChunkFormat.headerLength)
        let audio = try Self.audio(of: url)

        try ChunkedID3TagWriter().write(TagChanges(album: String(repeating: "Long Album ", count: 50)), to: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Old" && tags.album?.hasPrefix("Long Album") == true)
        #expect(try Self.audio(of: url) == audio)
        try Self.expectConsistentLayout(of: url)
    }

    @Test(arguments: ["wav", "aiff"])
    func setsAndRemovesArtwork(ext: String) async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFile(ext)
        let image = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(1, 0, 0)))

        try ChunkedID3TagWriter().write(TagChanges(artwork: .replace(image)), to: url)
        let fingerprint = SHA256.hash(data: image).map { String(format: "%02x", $0) }.joined()
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == fingerprint)

        try ChunkedID3TagWriter().write(TagChanges(artwork: .remove), to: url)
        #expect(try await AudioMetadataReader().read(url)?.artworkFingerprint == nil)
    }

    @Test func readsRIFFInfoTags() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try makeFile("wav")
        let original = try Data(contentsOf: url)
        let info = Data("INFO".utf8) + AudioChunkFormat.riff.chunk(id: "INAM", body: Data("Listed\0".utf8))
            + AudioChunkFormat.riff.chunk(id: "IART", body: Data("Someone\0".utf8))
        try Self.rebuild(url, from: original, inserting: AudioChunkFormat.riff.chunk(id: "LIST", body: info),
                         at: original.count)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Listed" && tags.artist == "Someone")
    }

    @Test func rejectsFilesThatArentWAVOrAIFF() throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        #expect(throws: TagWriterError.self) { try ChunkedID3TagWriter().write(TagChanges(title: "X"), to: url) }
    }

    /// Writes `original` with `chunk` inserted at `offset` and the container size updated.
    private static func rebuild(_ url: URL, from original: Data, inserting chunk: Data, at offset: Int) throws {
        var data = original
        data.insert(contentsOf: chunk, at: offset)
        let format = try #require(AudioChunkFormat(header: data))
        data.replaceSubrange(4..<8, with: format.encoded(size: data.count - 8))
        try data.write(to: url)
    }

    private static func expectConsistentLayout(of url: URL) throws {
        let layout = try layout(of: url)
        let fileSize = try fileSize(of: url)
        #expect(layout.end == fileSize)
        #expect(layout.chunks.last.map { $0.offset + $0.paddedLength } == fileSize)
    }

    private static func layout(of url: URL) throws -> AudioChunkLayout {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try AudioChunkParser.parse(handle)
    }

    /// The body of the `data` (WAV) or `SSND` (AIFF) chunk.
    private static func audio(of url: URL) throws -> Data {
        let chunk = try #require(try layout(of: url).chunks.first { $0.id == "data" || $0.id == "SSND" })
        return try Data(contentsOf: url).subdata(in: chunk.bodyOffset..<chunk.bodyOffset + chunk.size)
    }

    private static func fileSize(of url: URL) throws -> Int {
        try Data(contentsOf: url).count
    }
}
