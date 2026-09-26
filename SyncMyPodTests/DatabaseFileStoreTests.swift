import Foundation
import Testing
@testable import SyncMyPod

struct DatabaseFileStoreTests {
    private let original = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
    ]).build()

    @Test func refusesToWriteAnInvalidDatabase() throws {
        let volume = try TemporaryIPodVolume(database: original)
        let store = DatabaseFileStore.iTunesDB(onVolume: volume.url)
        #expect(throws: ITunesDBError.self) { try store.save(Data("garbage".utf8)) }
        #expect(try Data(contentsOf: volume.databaseURL) == original)
        #expect(!FileManager.default.fileExists(atPath: store.backupURL.path(percentEncoded: false)))
    }

    @Test func writesNewDatabaseAndKeepsBackup() throws {
        let volume = try TemporaryIPodVolume(database: original)
        let store = DatabaseFileStore.iTunesDB(onVolume: volume.url)
        let updated = ITunesDBFixtureBuilder(playlists: [
            FixturePlaylist(id: 1, name: "Renamed", isMaster: true, trackIDs: [])
        ]).build()
        try store.save(updated)
        #expect(try Data(contentsOf: volume.databaseURL) == updated)
        #expect(try Data(contentsOf: store.backupURL) == original)
    }

    @Test func createsMissingArtworkDBAndCanRemoveItAgain() throws {
        let volume = try TemporaryIPodVolume(database: original)
        let store = DatabaseFileStore.artworkDB(onVolume: volume.url)
        #expect(!store.exists)
        try store.save(ArtworkDBEditor.empty(formats: ArtworkFormat.videoIPod).serialized())
        #expect(store.exists)
        try store.restore(nil)
        #expect(!store.exists)
    }
}
