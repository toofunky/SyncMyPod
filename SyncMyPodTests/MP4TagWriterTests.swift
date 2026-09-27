import AVFoundation
import CryptoKit
import Testing
@testable import SyncMyPod

struct MP4TagWriterTests {
    let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    private static let allChanges = TagChanges(
        title: "Float On", artist: "Modest Mouse", album: "Good News", albumArtist: "Modest Mouse",
        composer: "Isaac Brock", genre: "Indie", year: 2004, track: TagNumberPair(number: 3, count: 16),
        disc: TagNumberPair(number: 1, count: 2))

    @Test func tagsAnUntaggedFile() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"), seconds: 2)
        let samples = try await Self.compressedSamples(of: url)

        try MP4TagWriter().write(Self.allChanges, to: url)

        let metadata = try #require(try await AudioMetadataReader().read(url))
        #expect(metadata.tags == AudioTags(title: "Float On", artist: "Modest Mouse", album: "Good News",
                                           albumArtist: "Modest Mouse", composer: "Isaac Brock",
                                           genre: "Indie", year: 2004,
                                           track: TagNumberPair(number: 3, count: 16),
                                           disc: TagNumberPair(number: 1, count: 2)))
        #expect(abs(metadata.duration - 2) < 0.1)
        #expect(try await Self.compressedSamples(of: url) == samples)
    }

    @Test func keepsTagsItDoesNotChange() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        try MP4TagWriter().write(Self.allChanges, to: url)

        try MP4TagWriter().write(TagChanges(album: "Good News for People Who Love Bad News", genre: "",
                                            track: TagNumberPair(number: 4, count: 16)), to: url)

        let tags = try #require(try await AudioMetadataReader().read(url)).tags
        #expect(tags.title == "Float On" && tags.artist == "Modest Mouse" && tags.year == 2004)
        #expect(tags.album == "Good News for People Who Love Bad News")
        #expect(tags.genre == nil)
        #expect(tags.track == TagNumberPair(number: 4, count: 16))
    }

    @Test func setsReplacesAndRemovesArtwork() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"))
        let red = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(1, 0, 0)))
        let blue = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(0, 0, 1)))

        try MP4TagWriter().write(TagChanges(artwork: .replace(red)), to: url)
        #expect(try await Self.artworkFingerprint(of: url) == Self.fingerprint(red))
        try MP4TagWriter().write(TagChanges(artwork: .replace(blue)), to: url)
        #expect(try await Self.artworkFingerprint(of: url) == Self.fingerprint(blue))
        try MP4TagWriter().write(TagChanges(artwork: .remove), to: url)
        #expect(try await Self.artworkFingerprint(of: url) == nil)
    }

    @Test func keepsArtworkWrittenByAVFoundation() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "source.m4a"))
        let url = folder.appending(path: "song.m4a")
        let image = TestImage.pngData(TestImage.make(width: 8, height: 8, top: TestImage.color(0, 1, 0)))
        try await AudioFixtureWriter.embedCoverArt(image, from: source, to: url)

        try MP4TagWriter().write(TagChanges(title: "Renamed"), to: url)

        #expect(try await AudioMetadataReader().read(url)?.tags.title == "Renamed")
        #expect(try await Self.artworkFingerprint(of: url) == Self.fingerprint(image))
    }

    @Test func shiftsChunkOffsetsWhenMovieBoxPrecedesMediaData() async throws {
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try AudioFixtureWriter.writeSilence(to: folder.appending(path: "source.m4a"), seconds: 2)
        let url = folder.appending(path: "faststart.m4a")
        try await Self.exportFastStart(source, to: url)
        let types = try Self.topLevelTypes(of: url)
        #expect(try #require(types.firstIndex(of: .moov)) < #require(types.firstIndex(of: FourCC("mdat"))))
        let samples = try await Self.compressedSamples(of: url)
        let image = TestImage.pngData(TestImage.make(width: 64, height: 64, top: TestImage.color(1, 1, 0)))

        try MP4TagWriter().write(TagChanges(title: "Shifted", artwork: .replace(image)), to: url)
        #expect(try await Self.compressedSamples(of: url) == samples)
        let sizeAfterGrowing = try Self.fileSize(of: url)

        try MP4TagWriter().write(TagChanges(title: "Shifted Again"), to: url)
        #expect(try Self.fileSize(of: url) == sizeAfterGrowing)
        #expect(try await Self.compressedSamples(of: url) == samples)
        #expect(try await AudioMetadataReader().read(url)?.tags.title == "Shifted Again")
    }

    private static func exportFastStart(_ source: URL, to destination: URL) async throws {
        let session = try #require(AVAssetExportSession(asset: AVURLAsset(url: source),
                                                        presetName: AVAssetExportPresetPassthrough))
        session.shouldOptimizeForNetworkUse = true
        try await session.export(to: destination, as: .m4a)
    }

    /// The encoded audio packets, which only survive intact if every chunk offset still points at them.
    private static func compressedSamples(of url: URL) async throws -> Data {
        let asset = AVURLAsset(url: url)
        let track = try #require(try await asset.loadTracks(withMediaType: .audio).first)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        let provider = reader.outputProvider(for: output)
        try reader.start()
        var data = Data()
        while let sample = try await provider.next() {
            if case .dataBuffer(let block) = sample.content { data.append(contentsOf: block) }
        }
        #expect(reader.status == .completed)
        return data
    }

    private static func artworkFingerprint(of url: URL) async throws -> String? {
        try await AudioMetadataReader().read(url)?.artworkFingerprint
    }

    private static func fingerprint(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func topLevelTypes(of url: URL) throws -> [FourCC] {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return try MP4TopLevelBox.scan(handle, fileSize: fileSize(of: url)).map(\.type)
    }

    private static func fileSize(of url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
}
