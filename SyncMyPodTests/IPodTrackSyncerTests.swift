import Foundation
import Testing
@testable import SyncMyPod

struct IPodTrackSyncerTests {
    private let fixture = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func request(_ source: URL, existingDatabaseID: UInt64? = nil) -> IPodSyncRequest {
        IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "Song", fileSize: 1_024),
                        existingDatabaseID: existingDatabaseID)
    }

    @Test func copiesFileAndRecordsItInTheDatabase() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let source = try volume.makeSourceFile()
        let added = try await IPodTrackSyncer(volumeURL: volume.url).add([request(source)])

        let track = try #require(try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks.first)
        #expect(added[source.path(percentEncoded: false)] == track.databaseID)
        #expect(track.location?.wholeMatch(of: /:iPod_Control:Music:F0[01]:[A-Z0-9]{4}\.m4a/) != nil)
        let copy = try #require(track.fileURL(onVolume: volume.url))
        #expect(try Data(contentsOf: copy) == Data(contentsOf: source))
    }

    @Test func backsUpThePreviousDatabase() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        _ = try await IPodTrackSyncer(volumeURL: volume.url).add([request(try volume.makeSourceFile())])
        let backup = ITunesDBStore(volumeURL: volume.url).backupURL
        #expect(try Data(contentsOf: backup) == fixture)
    }

    @Test func skipsTracksAlreadyOnTheIPod() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let source = try volume.makeSourceFile()
        let first = try await syncer.add([request(source)])
        let second = try await syncer.add([request(source, existingDatabaseID: first.values.first)])
        #expect(second.isEmpty)
        #expect(try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks.count == 1)
    }

    @Test func createsAMusicFolderWhenNoneExist() async throws {
        let volume = try TemporaryIPodVolume(database: fixture, musicFolders: [])
        _ = try await IPodTrackSyncer(volumeURL: volume.url).add([request(try volume.makeSourceFile())])
        let track = try #require(try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse().tracks.first)
        #expect(track.location?.hasPrefix(":iPod_Control:Music:F00:") == true)
    }

    @Test func removesCopiedFilesWhenTheDatabaseCannotBeRead() async throws {
        let volume = try TemporaryIPodVolume(database: Data("not a database".utf8))
        await #expect(throws: ITunesDBError.self) {
            try await IPodTrackSyncer(volumeURL: volume.url).add([request(try volume.makeSourceFile())])
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: volume.url.appending(path: "iPod_Control/Music/F00").path(percentEncoded: false)).isEmpty)
    }
}
