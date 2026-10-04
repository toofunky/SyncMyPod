import Foundation
import Testing
import UniformTypeIdentifiers
@testable import SyncMyPod

struct CoverResizeTests {
    private let red = TestImage.color(1, 0, 0)

    private func config(resize: Bool, size: Int = 300) -> AudioPlayerConfig {
        var config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music")
        config.copyCovers = true
        config.resizeCovers = resize
        config.maxCoverSize = size
        return config
    }

    private func plan(on volume: TemporaryPlayerVolume, _ config: AudioPlayerConfig,
                      song: IPodSyncRequest) async throws -> PlayerSyncPlan {
        let contents = await PlayerDeviceContents.load(from: try volume.device)
        let sidecars = await LibrarySidecarFinder.find(besideSongsAt: [song.sourcePath], covers: true, lyrics: false)
        return contents.planner(for: config, sidecars: sidecars).plan(selected: [song], playlists: [])
    }

    @Test func largeCoversShrinkToFitKeepingShapeAndFormat() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "cover-\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        try TestImage.jpegData(TestImage.make(width: 1_200, height: 600, top: red)).write(to: url)
        try CoverResizer.fit(imageAt: url, within: 300)
        let resized = try #require(TestImage.dimensions(at: url))
        #expect(resized.width == 300 && resized.height == 150)
        #expect(resized.type == UTType.jpeg.identifier)
    }

    @Test func smallCoversAreLeftUntouched() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "cover-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }
        let original = TestImage.pngData(TestImage.make(width: 200, height: 200, top: red))
        try original.write(to: url)
        try CoverResizer.fit(imageAt: url, within: 300)
        #expect(try Data(contentsOf: url) == original)
    }

    @Test func syncedCoversAreResizedOnlyOnThePlayer() async throws {
        let volume = try TemporaryPlayerVolume(config: config(resize: true))
        let song = try volume.request("Clocks", file: "Album/Clocks.mp3")
        let cover = try volume.librarySidecar("Album/cover.png")
        try TestImage.pngData(TestImage.make(width: 900, height: 900, top: red)).write(to: cover)
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(resize: true), song: song))
        let copied = try #require(TestImage.dimensions(at: volume.volumeURL.appending(path: "Music/Artist/Album/cover.png")))
        #expect(copied.width == 300 && copied.type == UTType.png.identifier)
        #expect(TestImage.dimensions(at: cover)?.width == 900)
    }

    @Test func changingTheSizeOrTurningResizingOffCopiesCoversAgain() async throws {
        let volume = try TemporaryPlayerVolume(config: config(resize: true))
        let song = try volume.request("Clocks", file: "Album/Clocks.mp3")
        try TestImage.jpegData(TestImage.make(width: 900, height: 900, top: red))
            .write(to: try volume.librarySidecar("Album/folder.jpg"))
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(resize: true), song: song))
        #expect(try await plan(on: volume, config(resize: true), song: song).sidecarCopies.isEmpty)
        #expect(try await plan(on: volume, config(resize: true, size: 500), song: song).sidecarCopies.count == 1)
        let original = try await plan(on: volume, config(resize: false), song: song)
        #expect(original.sidecarCopies.map(\.pixelLimit) == [nil])
    }

    @Test func coverSizeDefaultsTo300AndStaysInRange() {
        #expect(AudioPlayerConfig(name: "Player", rootPath: "").maxCoverSize == 300)
        var config = AudioPlayerConfig(name: "Player", rootPath: "")
        config.maxCoverSize = 0
        #expect(config.cleaned(defaultName: "Player").maxCoverSize == AudioPlayerConfig.coverSizeRange.lowerBound)
    }
}
