import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct IPodHousekeepingSyncTests {
    private let database = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func song(_ name: String, album: String, in volume: TemporaryIPodVolume,
                      cover: CGColor? = nil) async throws -> IPodSyncRequest {
        let silence = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/\(name)-plain.m4a"))
        var source = silence
        if let cover {
            source = volume.url.appending(path: "source/\(name).m4a")
            let image = TestImage.make(width: 300, height: 300, top: cover)
            try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(image), from: silence, to: source)
        }
        let draft = ITunesTrackDraft(title: name, artist: "Band", album: album,
                                     fileSize: try Data(contentsOf: source).count)
        return IPodSyncRequest(sourceURL: source, draft: draft)
    }

    private func tracks(on volume: TemporaryIPodVolume) throws -> [ITunesTrack] {
        try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks
    }

    private func artwork(on volume: TemporaryIPodVolume) throws -> ArtworkDBEditor {
        ArtworkDBEditor(root: try DatabaseFileStore.artworkDB(onVolume: volume.url).loadRecords())
    }

    private func ithmb(_ id: Int, on volume: TemporaryIPodVolume) throws -> Data {
        try Data(contentsOf: volume.url.appending(path: "iPod_Control/Artwork/F\(id)_1.ithmb"))
    }

    @Test func removesTrackAndDeletesItsFile() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let first = try await song("One", album: "A", in: volume)
        let second = try await song("Two", album: "B", in: volume)
        _ = try await syncer.sync(adding: [first, second])
        let doomed = try #require(try tracks(on: volume).first { $0.title == "Two" })

        let outcome = try await syncer.sync(adding: [], removing: [doomed.databaseID])
        #expect(outcome.removed == 1)
        #expect(try tracks(on: volume).map(\.title) == ["One"])
        let doomedFile = try #require(doomed.fileURL(onVolume: volume.url))
        #expect(!FileManager.default.fileExists(atPath: doomedFile.path(percentEncoded: false)))
    }

    @Test func mergesPlayCountsAndDeletesPositionIndexedFiles() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [try await song("One", album: "A", in: volume),
                                           try await song("Two", album: "B", in: volume)])
        let files = IPodControlFiles(volumeURL: volume.url)
        try PlayCountsTests.file(entries: [(4, 0, 0, 0), (9, 0, 0, 0)]).write(to: files.playCountsURL)
        let onTheGo = volume.url.appending(path: "iPod_Control/iTunes/OTGPlaylistInfo")
        try Data([1]).write(to: onTheGo)
        let doomed = try #require(try tracks(on: volume).first { $0.title == "Two" })

        _ = try await syncer.sync(adding: [], removing: [doomed.databaseID])
        #expect(try tracks(on: volume).map(\.playCount) == [4])
        #expect(!FileManager.default.fileExists(atPath: files.playCountsURL.path(percentEncoded: false)))
        #expect(!FileManager.default.fileExists(atPath: onTheGo.path(percentEncoded: false)))
    }

    @Test func reusesAnAlbumCoverAddedInAnEarlierSync() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let red = TestImage.color(1, 0, 0)
        _ = try await syncer.sync(adding: [try await song("One", album: "A", in: volume, cover: red)])
        _ = try await syncer.sync(adding: [try await song("Two", album: "A", in: volume, cover: red)])

        #expect(try ithmb(1029, on: volume).count == 80_000)
        let ids = try tracks(on: volume).map(\.databaseID)
        let thumbnails = try artwork(on: volume).thumbnails(forTracks: ids, formats: ArtworkFormat.videoIPod)
        #expect(thumbnails.count == 2 && thumbnails[0] == thumbnails[1])
    }

    @Test func removingTracksDropsTheirArtworkAndCompactsCovers() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [try await song("One", album: "A", in: volume, cover: TestImage.color(1, 0, 0)),
                                           try await song("Two", album: "B", in: volume, cover: TestImage.color(0, 0, 1))])
        let keptPixels = try ithmb(1029, on: volume).subdata(in: 80_000..<160_000)
        let doomed = try #require(try tracks(on: volume).first { $0.title == "One" })

        _ = try await syncer.sync(adding: [], removing: [doomed.databaseID])
        let remaining = try #require(try tracks(on: volume).first)
        let thumbnails = try artwork(on: volume).thumbnails(forTracks: [doomed.databaseID, remaining.databaseID],
                                                            formats: ArtworkFormat.videoIPod)
        #expect(thumbnails.count == 1)
        #expect(thumbnails.first?.map(\.offset) == [0, 0])
        #expect(try ithmb(1029, on: volume) == keptPixels)
        #expect(try ithmb(1028, on: volume).count == 20_000)
    }
}
