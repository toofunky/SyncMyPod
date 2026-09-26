import Foundation
import Testing
@testable import SyncMyPod

struct IPodTrackSyncerTests {
    private let fixture = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func request(_ source: URL, title: String = "Song") -> IPodSyncRequest {
        IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: title, fileSize: 1_024))
    }

    private func tracks(on volume: TemporaryIPodVolume) throws -> [ITunesTrack] {
        try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks
    }

    @Test func copiesFileAndRecordsItInTheDatabase() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let source = try volume.makeSourceFile()
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request(source)])

        let track = try #require(try tracks(on: volume).first)
        #expect(outcome.addedDatabaseIDs[source.path(percentEncoded: false)] == track.databaseID)
        #expect(track.location?.wholeMatch(of: /:iPod_Control:Music:F0[01]:[A-Z0-9]{4}\.m4a/) != nil)
        let copy = try #require(track.fileURL(onVolume: volume.url))
        #expect(try Data(contentsOf: copy) == Data(contentsOf: source))
    }

    @Test func backsUpThePreviousDatabase() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request(try volume.makeSourceFile())])
        let backup = DatabaseFileStore.iTunesDB(onVolume: volume.url).backupURL
        #expect(try Data(contentsOf: backup) == fixture)
    }

    @Test func skipsTracksAlreadyOnTheIPod() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let source = try volume.makeSourceFile()
        _ = try await syncer.sync(adding: [request(source)])
        let second = try await syncer.sync(adding: [request(source)])
        #expect(second.addedCount == 0 && second.skipped == 1)
        #expect(try tracks(on: volume).count == 1)
    }

    @Test func recordsCopiedTracksInTheManifest() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let source = try volume.makeSourceFile()
        let details = SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil)
        let request = IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Song", fileSize: 1_024),
                                      source: details)
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request])

        let entry = try #require(IPodControlFiles(volumeURL: volume.url).manifest().entry(for: request))
        #expect(entry.databaseID == outcome.addedDatabaseIDs.values.first)
        #expect(entry.source == details)
    }

    @Test func skipsARetaggedFileTheManifestKnows() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let source = try volume.makeSourceFile()
        let details = SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        _ = try await syncer.sync(adding: [IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Song",
                                                           fileSize: 1_024), source: details)])
        let retagged = IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Renamed", fileSize: 1_100),
                                       source: details)
        let second = try await syncer.sync(adding: [retagged])
        #expect(second.addedCount == 0 && second.skipped == 1)
        #expect(try tracks(on: volume).count == 1)
    }

    @Test func skipsDuplicatesWithinOneSync() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let source = try volume.makeSourceFile()
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request(source), request(source)])
        #expect(outcome.addedCount == 1 && outcome.skipped == 1)
    }

    @Test func reportsProgressForEachTrackThenTheDatabase() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let requests = try (1...3).map { request(try volume.makeSourceFile(named: "\($0).m4a"), title: "Song \($0)") }
        let recorder = ProgressRecorder()
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: requests) { await recorder.record($0) }
        let updates = await recorder.updates
        #expect(updates.map(\.completed) == [0, 1, 2, 3])
        #expect(updates.map(\.currentTitle) == ["Song 1", "Song 2", "Song 3", nil])
    }

    @Test func cancellingKeepsTheTracksAlreadyCopied() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let requests = try (1...3).map { request(try volume.makeSourceFile(named: "\($0).m4a"), title: "Song \($0)") }
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let outcome = try await Task {
            try await syncer.sync(adding: requests) { update in
                if update.completed == 2 { withUnsafeCurrentTask { $0?.cancel() } }
            }
        }.value
        #expect(outcome.wasCancelled)
        #expect(try tracks(on: volume).map(\.title) == ["Song 1", "Song 2"])
    }

    @Test func createsAMusicFolderWhenNoneExist() async throws {
        let volume = try TemporaryIPodVolume(database: fixture, musicFolders: [])
        _ = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request(try volume.makeSourceFile())])
        let track = try #require(try tracks(on: volume).first)
        #expect(track.location?.hasPrefix(":iPod_Control:Music:F00:") == true)
    }

    @Test func removesCopiedFilesWhenTheDatabaseCannotBeRead() async throws {
        let volume = try TemporaryIPodVolume(database: Data("not a database".utf8))
        await #expect(throws: ITunesDBError.self) {
            try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [request(try volume.makeSourceFile())])
        }
        let folder = volume.url.appending(path: "iPod_Control/Music/F00").path(percentEncoded: false)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder).isEmpty)
    }
}
