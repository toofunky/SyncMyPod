import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct EmbeddedArtworkResizeTests {
    private let red = TestImage.color(1, 0, 0)

    private func config(resize: Bool, size: Int = 300) -> AudioPlayerConfig {
        var config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music")
        config.resizeCovers = resize
        config.maxCoverSize = size
        return config
    }

    /// A song whose embedded cover is `width` × `height`, as the library scan would describe it.
    private func song(in volume: TemporaryPlayerVolume, width: Int, height: Int) async throws -> SyncRequest {
        let plain = try AudioFixtureWriter.writeSilence(to: volume.root.appending(path: "plain-\(UUID()).m4a"))
        let source = volume.libraryURL.appending(path: "Song.m4a")
        try FileManager.default.createDirectory(at: volume.libraryURL, withIntermediateDirectories: true)
        let cover = TestImage.pngData(TestImage.make(width: width, height: height, top: red))
        try await AudioFixtureWriter.embedCoverArt(cover, from: plain, to: source)
        let draft = TrackTags(title: "Song", artist: "Artist", album: "Album", fileSize: 1, codec: .aac)
        return SyncRequest(sourceURL: source, tags: draft,
                               source: SyncSource(fileSize: 1, modificationDate: .now, artworkFingerprint: "cover"))
    }

    private func plan(on volume: TemporaryPlayerVolume, _ config: AudioPlayerConfig,
                      songs: [SyncRequest]) async throws -> PlayerSyncPlan {
        await PlayerDeviceContents.load(from: try volume.device).planner(for: config)
            .plan(selected: songs, playlists: nil)
    }

    @Test func oversizedEmbeddedArtworkShrinksOnlyInTheCopyWithoutCopyingCovers() async throws {
        let volume = try TemporaryPlayerVolume(config: config(resize: true))
        let request = try await song(in: volume, width: 1_200, height: 600)
        let plan = try await plan(on: volume, config(resize: true), songs: [request])
        #expect(plan.sidecarCopies.isEmpty)
        _ = try await PlayerTrackSyncer(device: volume.device).sync(plan)
        let copy = volume.volumeURL.appending(path: "Music/Artist/Album/Song.m4a")
        let copied = try #require(try await CoverArtReader().read(copy)).image
        #expect(copied.width == 300 && copied.height == 150)
        #expect(try #require(try await CoverArtReader().read(request.sourceURL)).image.width == 1_200)
    }

    @Test func artworkThatFitsIsCopiedAsItIs() async throws {
        let volume = try TemporaryPlayerVolume(config: config(resize: true))
        let request = try await song(in: volume, width: 200, height: 200)
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(resize: true), songs: [request]))
        let copy = volume.volumeURL.appending(path: "Music/Artist/Album/Song.m4a")
        let copied = try #require(try await CoverArtReader().read(copy))
        let original = try #require(try await CoverArtReader().read(request.sourceURL))
        #expect(copied.byteCount == original.byteCount && copied.image.width == 200)
    }

    @Test func changingTheSizeCopiesOnlySongsWithArtworkAgain() async throws {
        let volume = try TemporaryPlayerVolume(config: config(resize: false))
        let withArt = try await song(in: volume, width: 900, height: 900)
        let withoutArt = try volume.request("Plain")
        let songs = [withArt, withoutArt]
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(resize: false), songs: songs))
        #expect(try await plan(on: volume, config(resize: false), songs: songs).updates.isEmpty)
        let resizing = try await plan(on: volume, config(resize: true, size: 1_000), songs: songs)
        #expect(resizing.updates.map(\.request.sourcePath) == [withArt.sourcePath])
        _ = try await PlayerTrackSyncer(device: volume.device).sync(resizing)
        #expect(try await plan(on: volume, config(resize: true, size: 1_000), songs: songs).updates.isEmpty)
        #expect(try await plan(on: volume, config(resize: true, size: 500), songs: songs).updates.count == 1)
    }

    @Test func resizingCoversNoLongerNeedsCopyCovers() {
        #expect(config(resize: true, size: 800).coverPixelLimit == 800)
        #expect(config(resize: false).coverPixelLimit == nil)
    }

    @Test func encodedImagesAreFittedOrLeftAlone() throws {
        let large = TestImage.jpegData(TestImage.make(width: 2_000, height: 1_000, top: red))
        let resized = try #require(try CoverResizer.fitted(large, within: 500))
        let url = FileManager.default.temporaryDirectory.appending(path: "fitted-\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        try resized.write(to: url)
        #expect(TestImage.dimensions(at: url)?.width == 500)
        #expect(try CoverResizer.fitted(large, within: 2_000) == nil)
    }
}
