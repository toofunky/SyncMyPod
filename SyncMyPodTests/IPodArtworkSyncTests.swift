import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct IPodArtworkSyncTests {
    private let database = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func song(_ name: String, in volume: TemporaryIPodVolume, cover: CGColor?) async throws -> IPodSyncRequest {
        let silence = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/\(name)-plain.m4a"))
        var source = silence
        if let cover {
            source = volume.url.appending(path: "source/\(name).m4a")
            let image = TestImage.make(width: 600, height: 600, top: cover)
            try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(image), from: silence, to: source)
        }
        let size = try Data(contentsOf: source).count
        return IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: name, fileSize: size),
                               existingDatabaseID: nil)
    }

    private func artworkImages(on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        let root = try DatabaseFileStore.artworkDB(onVolume: volume.url).loadRecords()
        return try #require(root.children.first?.children.first).children
    }

    private func ithmbSize(_ id: Int, on volume: TemporaryIPodVolume) throws -> Int {
        try Data(contentsOf: volume.url.appending(path: "iPod_Control/Artwork/F\(id)_1.ithmb")).count
    }

    @Test func createsArtworkForACoveredTrack() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let request = try await song("red", in: volume, cover: TestImage.color(1, 0, 0))
        let added = try await IPodTrackSyncer(volumeURL: volume.url).add([request])

        let image = try #require(try artworkImages(on: volume).first)
        #expect(image.uint64(at: 0x14) == added.values.first)
        #expect(try ithmbSize(1028, on: volume) == 20_000)
        #expect(try ithmbSize(1029, on: volume) == 80_000)
        let tracks = try DatabaseFileStore.iTunesDB(onVolume: volume.url).loadRecords().children
        let mhit = try #require(tracks.first { $0.isSection(.tracks) }?.children.first?.children.first)
        #expect(mhit.uint32(at: 0x160) == image.uint32(at: 0x10))
    }

    @Test func tracksSharingACoverStoreItsPixelsOnce() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let first = try await song("one", in: volume, cover: TestImage.color(0, 0, 1))
        let second = try await song("two", in: volume, cover: TestImage.color(0, 0, 1))
        let third = try await song("three", in: volume, cover: TestImage.color(0, 1, 0))
        _ = try await IPodTrackSyncer(volumeURL: volume.url).add([first, second, third])

        let images = try artworkImages(on: volume)
        #expect(images.count == 3)
        #expect(Set(images.map { $0.uint32(at: 0x10) }).count == 3)
        #expect(try ithmbSize(1029, on: volume) == 160_000)
    }

    @Test func leavesArtworkAloneForTracksWithoutCovers() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).add([try await song("plain", in: volume, cover: nil)])
        #expect(!DatabaseFileStore.artworkDB(onVolume: volume.url).exists)
    }
}
