import Foundation
import Testing
@testable import SyncMyPod

struct IPodSyncVerifierTests {
    private let fixture = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ], includesAlbumSection: true).build()

    private func request(_ source: URL) -> IPodSyncRequest {
        IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: "One", fileSize: 1_024),
                        source: SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil))
    }

    private func sync(on volume: TemporaryIPodVolume,
                      playlists: [IPodPlaylistRequest]? = nil) async throws -> IPodSyncExpectation {
        let song = request(try volume.makeSourceFile())
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url).sync(adding: [song], playlists: playlists)
        return IPodSyncExpectation(outcome: outcome, removals: [], playlists: playlists)
    }

    /// What Finder or Music does: writes back the database it read before the sync.
    private func restoreBackup(on volume: TemporaryIPodVolume) throws {
        let backup = DatabaseFileStore.iTunesDB(onVolume: volume.url).backupURL
        try FileManager.default.removeItem(at: volume.databaseURL)
        try FileManager.default.copyItem(at: backup, to: volume.databaseURL)
    }

    @Test func keptSyncIsNotOverwritten() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let expectation = try await sync(on: volume)
        #expect(!expectation.isEmpty)
        #expect(await !IPodSyncVerifier.wasOverwritten(expectation, onVolume: volume.url, after: .zero))
    }

    @Test func restoredDatabaseIsOverwritten() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let expectation = try await sync(on: volume)
        try restoreBackup(on: volume)
        #expect(await IPodSyncVerifier.wasOverwritten(expectation, onVolume: volume.url, after: .zero))
    }

    @Test func missingPlaylistIsOverwritten() {
        let expectation = IPodSyncExpectation(outcome: IPodSyncOutcome(), removals: [], playlists: [
            IPodPlaylistRequest(id: 77, name: "Mix", createdAt: .now, tracks: [])
        ])
        #expect(!expectation.isMet(by: ITunesDatabase.preview))
    }

    @Test func removedTrackThatCameBackIsOverwritten() {
        let expectation = IPodSyncExpectation(outcome: IPodSyncOutcome(removed: 1),
                                              removals: [ITunesDatabase.preview.tracks[0].databaseID],
                                              playlists: nil)
        #expect(!expectation.isMet(by: ITunesDatabase.preview))
    }

    @Test func unreadableDatabaseIsNotReportedAsOverwritten() async throws {
        let volume = try TemporaryIPodVolume(database: nil)
        let expectation = IPodSyncExpectation(outcome: IPodSyncOutcome(addedDatabaseIDs: ["/a.m4a": 1]),
                                              removals: [], playlists: nil)
        #expect(await !IPodSyncVerifier.wasOverwritten(expectation, onVolume: volume.url, after: .zero))
    }
}
