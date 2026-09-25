import Foundation
import Testing
@testable import SyncMyPod

struct IPodPlaylistSyncTests {
    private let fixture = ITunesDBFixtureBuilder(playlists: [
        FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: []),
        FixturePlaylist(id: 2, name: "On-Device", trackIDs: [])
    ], includesAlbumSection: true, includesPodcastSection: true).build()

    private func request(_ source: URL, title: String) -> IPodSyncRequest {
        IPodSyncRequest(sourceURL: source, draft: ITunesTrackDraft(title: title, fileSize: 1_024),
                        source: SyncSource(fileSize: 1_024, modificationDate: .now, artworkFingerprint: nil))
    }

    private func database(on volume: TemporaryIPodVolume) throws -> ITunesDatabase {
        try ITunesDBParser(data: Data(contentsOf: volume.databaseURL)).parse()
    }

    private func titles(of playlist: ITunesPlaylist, in database: ITunesDatabase) -> [String] {
        playlist.trackIDs.compactMap { id in database.tracks.first { $0.id == id }?.title }
    }

    @Test func writesPlaylistsOfSongsCopiedInTheSameSync() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let one = request(try volume.makeSourceFile(named: "one.m4a"), title: "One")
        let two = request(try volume.makeSourceFile(named: "two.m4a"), title: "Two")
        let playlist = IPodPlaylistRequest(id: 77, name: "Mix", createdAt: .now, tracks: [two, one])
        let outcome = try await IPodTrackSyncer(volumeURL: volume.url)
            .sync(adding: [one, two], playlists: [playlist])

        let database = try database(on: volume)
        let written = try #require(database.playlists.first { $0.id == 77 })
        #expect(titles(of: written, in: database) == ["Two", "One"])
        #expect(outcome.syncedPlaylistCount == 1)
        #expect(IPodControlFiles(volumeURL: volume.url).manifest().playlistIDs == [77])
    }

    @Test func playlistOnlySyncUsesSongsAlreadyOnTheIPod() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let one = request(try volume.makeSourceFile(named: "one.m4a"), title: "One")
        _ = try await syncer.sync(adding: [one])
        _ = try await syncer.sync(adding: [], playlists: [IPodPlaylistRequest(id: 77, name: "Mix", createdAt: .now,
                                                                              tracks: [one])])
        let database = try database(on: volume)
        let written = try #require(database.playlists.first { $0.id == 77 })
        #expect(titles(of: written, in: database) == ["One"])
    }

    @Test func removesPlaylistsNoLongerSyncedButKeepsOthers() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let one = request(try volume.makeSourceFile(named: "one.m4a"), title: "One")
        _ = try await syncer.sync(adding: [one], playlists: [IPodPlaylistRequest(id: 77, name: "Mix", createdAt: .now,
                                                                                  tracks: [one])])
        _ = try await syncer.sync(adding: [], playlists: [])
        #expect(try database(on: volume).playlists.map(\.name) == ["iPod", "On-Device"])
        #expect(IPodControlFiles(volumeURL: volume.url).manifest().playlistIDs.isEmpty)
    }

    @Test func leavesPlaylistsAloneWhenNoneAreGiven() async throws {
        let volume = try TemporaryIPodVolume(database: fixture)
        let syncer = IPodTrackSyncer(volumeURL: volume.url)
        let one = request(try volume.makeSourceFile(named: "one.m4a"), title: "One")
        _ = try await syncer.sync(adding: [one], playlists: [IPodPlaylistRequest(id: 77, name: "Mix", createdAt: .now,
                                                                                  tracks: [one])])
        let two = request(try volume.makeSourceFile(named: "two.m4a"), title: "Two")
        _ = try await syncer.sync(adding: [two])
        #expect(try database(on: volume).playlists.map(\.name) == ["iPod", "On-Device", "Mix"])
        #expect(IPodControlFiles(volumeURL: volume.url).manifest().playlistIDs == [77])
    }
}
