import CoreGraphics
import Foundation
import Testing
@testable import SyncMyPod

struct IPodTrackUpdateSyncTests {
    private let database = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func request(_ source: URL, title: String, version: Int,
                         fingerprint: String? = nil) throws -> IPodSyncRequest {
        let size = try Data(contentsOf: source).count
        let details = SyncSource(fileSize: size, modificationDate: Date(timeIntervalSinceReferenceDate: Double(version)),
                                 artworkFingerprint: fingerprint)
        return IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: title, album: "Album", fileSize: size),
                               source: details)
    }

    /// Writes real audio at the same path each time, with the cover (if any) embedded.
    private func song(in volume: TemporaryIPodVolume, cover: CGColor?, version: Int) async throws -> IPodSyncRequest {
        let plain = try AudioFixtureWriter.writeSilence(to: volume.url.appending(path: "source/plain-\(version).m4a"))
        let destination = volume.url.appending(path: "source/song.m4a")
        try? FileManager.default.removeItem(at: destination)
        if let cover {
            let image = TestImage.make(width: 300, height: 300, top: cover)
            try await AudioFixtureWriter.embedCoverArt(TestImage.pngData(image), from: plain, to: destination)
        } else {
            try FileManager.default.copyItem(at: plain, to: destination)
        }
        let fingerprint = cover.map { "\($0.components ?? [])" }
        return try request(destination, title: "Song", version: version, fingerprint: fingerprint)
    }

    private func onlyTrack(on volume: TemporaryIPodVolume) throws -> ITunesTrack {
        let tracks = try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks
        try #require(tracks.count == 1)
        return tracks[0]
    }

    private func mhit(on volume: TemporaryIPodVolume) throws -> ITunesDBRecord {
        let root = try DatabaseFileStore.iTunesDB(onVolume: volume.url).loadRecords()
        return try #require(root.children.first { $0.isSection(.tracks) }?.children.first?.children.first)
    }

    private func images(on volume: TemporaryIPodVolume) throws -> [ITunesDBRecord] {
        let root = try DatabaseFileStore.artworkDB(onVolume: volume.url).loadRecords()
        return try #require(root.children.first?.children.first).children
    }

    @Test func replacesTheFileAndRewritesTheTrackInPlace() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [try request(try volume.makeSourceFile(), title: "Song", version: 1)])
        let before = try onlyTrack(on: volume)
        let source = try volume.makeSourceFile(bytes: 2_048)
        let edited = try request(source, title: "Song (Remix)", version: 2)
        let outcome = try await syncer.sync(adding: [edited])

        let after = try onlyTrack(on: volume)
        #expect(outcome.updatedCount == 1 && outcome.addedCount == 0 && outcome.skipped == 0)
        #expect(after.databaseID == before.databaseID && after.id == before.id)
        #expect(after.title == "Song (Remix)" && after.fileSize == 2_048 && after.location != before.location)
        #expect(try Data(contentsOf: #require(after.fileURL(onVolume: volume.url))) == Data(contentsOf: source))
        let oldFile = try #require(before.fileURL(onVolume: volume.url))
        #expect(!FileManager.default.fileExists(atPath: oldFile.path(percentEncoded: false)))
        #expect(IPodControlFiles(volumeURL: volume.url).manifest().entry(for: edited)?.source == edited.source)
    }

    @Test func changedCoverReplacesTheImage() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [try await song(in: volume, cover: TestImage.color(1, 0, 0), version: 1)])
        let redImage = try #require(try images(on: volume).first).uint32(at: 0x10)
        _ = try await syncer.sync(adding: [try await song(in: volume, cover: TestImage.color(0, 0, 1), version: 2)])

        let images = try images(on: volume)
        let track = try onlyTrack(on: volume)
        #expect(images.count == 1)
        #expect(images[0].uint64(at: 0x14) == track.databaseID && images[0].uint32(at: 0x10) != redImage)
        #expect(try mhit(on: volume).uint32(at: 0x160) == images[0].uint32(at: 0x10))
    }

    @Test func removedCoverClearsTheArtwork() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [try await song(in: volume, cover: TestImage.color(1, 0, 0), version: 1)])
        _ = try await syncer.sync(adding: [try await song(in: volume, cover: nil, version: 2)])
        #expect(try images(on: volume).isEmpty)
        #expect(try mhit(on: volume).uint8(at: 0xA4) == 2)
    }

    @Test func unchangedCoverKeepsTheImage() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let red = TestImage.color(1, 0, 0)
        _ = try await syncer.sync(adding: [try await song(in: volume, cover: red, version: 1)])
        let before = try images(on: volume)
        let outcome = try await syncer.sync(adding: [try await song(in: volume, cover: red, version: 2)])
        #expect(outcome.updatedCount == 1)
        #expect(try images(on: volume) == before)
        #expect(try mhit(on: volume).uint32(at: 0x160) == before.first?.uint32(at: 0x10))
    }

    @Test func looselyMatchedTrackIsRewrittenFromItsEditedFile() async throws {
        let volume = try TemporaryIPodVolume(database: database)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let source = try volume.makeSourceFile()
        let original = ITunesTrackDraft(title: "The Sign", artist: "Ace of Base", album: "The Sign",
                                        fileSize: 1_024, duration: 192.445)
        _ = try await syncer.sync(adding: [IPodSyncRequest(sourceURL: source, draft: original)])
        var retagged = original
        retagged.artist = "Ace of Base Test"
        let edited = IPodSyncRequest(sourceURL: source, draft: retagged,
                                     source: SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil))
        let files = IPodControlFiles(volumeURL: volume.url)
        var manifest = files.manifest()
        _ = manifest.adoptLoosely([edited], onDevice: [try onlyTrack(on: volume)])
        try files.save(manifest)

        let outcome = try await syncer.sync(adding: [edited])
        #expect(outcome.updatedCount == 1 && outcome.addedCount == 0)
        #expect(try onlyTrack(on: volume).artist == "Ace of Base Test")
        #expect(files.manifest().entry(for: edited)?.source == edited.source)
    }
}
