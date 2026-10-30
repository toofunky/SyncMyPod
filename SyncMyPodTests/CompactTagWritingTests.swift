import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import SyncMyPod

struct CompactTagWritingTests {
    private static let codecs: [SyncMyPod.AudioCodec] = [.alac, .mp3, .flac, .wav, .aiff]
    private let folder: URL

    init() throws {
        folder = try AudioFixtureWriter.makeTemporaryFolder()
    }

    @Test(arguments: codecs)
    func shrinkingTagsPastTheLimitCompactsThemLeavingTheAudioUnchanged(codec: SyncMyPod.AudioCodec) async throws {
        let url = try fixture(codec)
        try await TagWriter().write(TagChanges(artwork: .replace(try Self.noisePNG(side: 600))), to: url, codec: codec)
        let before = try Self.size(of: url)
        let frames = try AVAudioFile(forReading: url).length
        let compacting = TagWriter(maximumPadding: PlayerSongPreparer.maximumPadding)
        try await compacting.write(TagChanges(title: "Kept", artwork: .remove), to: url, codec: codec)
        #expect(try before - Self.size(of: url) > 1_000_000)
        #expect(try AVAudioFile(forReading: url).length == frames)
        #expect(try await AudioMetadataReader().read(url)?.tags.title == "Kept")
        let compacted = try Self.size(of: url)
        try await compacting.write(TagChanges(title: "Still Fits"), to: url, codec: codec)
        #expect(try Self.size(of: url) == compacted)
    }

    @Test(arguments: codecs)
    func withoutALimitShrinkingTagsStillWritesInPlace(codec: SyncMyPod.AudioCodec) async throws {
        let url = try fixture(codec)
        try await TagWriter().write(TagChanges(artwork: .replace(try Self.noisePNG(side: 600))), to: url, codec: codec)
        let before = try Self.size(of: url)
        try await TagWriter().write(TagChanges(artwork: .remove), to: url, codec: codec)
        #expect(try Self.size(of: url) == before)
    }

    @Test(arguments: [SyncMyPod.AudioCodec.alac, .flac, .mp3])
    func playerCopiesWithShrunkArtworkDontKeepItsSpace(codec: SyncMyPod.AudioCodec) async throws {
        var config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music")
        config.resizeCovers = true
        let volume = try TemporaryPlayerVolume(config: config)
        let source = try fixture(codec)
        try await TagWriter().write(TagChanges(artwork: .replace(try Self.noisePNG(side: 1_500))), to: source,
                                    codec: codec)
        let draft = TrackTags(title: "Song", artist: "Artist", album: "Album", fileSize: 1, codec: codec)
        let request = SyncRequest(sourceURL: source, tags: draft,
                                      source: SyncSource(fileSize: 1, modificationDate: .now, artworkFingerprint: "cover"))
        let plan = await PlayerDeviceContents.load(from: try volume.device).planner(for: config)
            .plan(selected: [request], playlists: nil)
        _ = try await PlayerTrackSyncer(device: volume.device).sync(plan)
        let copy = volume.volumeURL.appending(path: "Music/Artist/Album/\(source.lastPathComponent)")
        #expect(try Self.size(of: copy) < Self.size(of: source) / 4)
        #expect(try #require(try await CoverArtReader().read(copy)).image.width == 300)
        #expect(volume.names(in: "Music/Artist/Album") == [source.lastPathComponent])
    }

    private func fixture(_ codec: SyncMyPod.AudioCodec) throws -> URL {
        switch codec {
        case .mp3: try MP3FixtureWriter.write(to: folder.appending(path: "song.mp3"))
        case .flac: try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.flac"), format: kAudioFormatFLAC)
        case .wav, .aiff:
            try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.\(codec == .wav ? "wav" : "aiff")"),
                                                format: kAudioFormatLinearPCM)
        case .aac, .alac:
            try AudioFixtureWriter.writeSilence(to: folder.appending(path: "song.m4a"), format: kAudioFormatAppleLossless)
        }
    }

    /// Random pixels, which PNG can't compress, so the cover is over a megabyte.
    private static func noisePNG(side: Int) throws -> Data {
        var generator = SystemRandomNumberGenerator()
        var pixels = (0..<side * side * 4).map { _ in UInt8.random(in: 0...255, using: &generator) }
        let image = try #require(pixels.withUnsafeMutableBytes { buffer in
            CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                      bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)?.makeImage()
        })
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        try #require(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private static func size(of url: URL) throws -> Int {
        try #require(try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))[.size] as? Int)
    }
}
