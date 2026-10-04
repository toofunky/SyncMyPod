import Foundation
import Testing
@testable import SyncMyPod

struct PlayerTrackSyncerTests {
    private let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music",
                                           playlistFolder: "Playlists")

    private func plan(on volume: TemporaryPlayerVolume, selected: [IPodSyncRequest],
                      unselected: [IPodSyncRequest] = [], playlists: [IPodPlaylistRequest]? = nil,
                      config: AudioPlayerConfig? = nil) async throws -> PlayerSyncPlan {
        let contents = await PlayerDeviceContents.load(from: try volume.device)
        return contents.planner(for: config ?? self.config).plan(selected: selected, unselected: unselected,
                                                                 playlists: playlists)
    }

    @Test func copiesSongsAndPlaylistsAndRecordsThem() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks")
        let mix = IPodPlaylistRequest(id: 1, name: "Mix", createdAt: .now, tracks: [song])
        let summary = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, selected: [song], playlists: [mix]))
        #expect(summary.added == 1 && summary.syncedPlaylistCount == 1)
        #expect(volume.fileExists("Music/Artist/Album/Clocks.m4a"))
        #expect(try volume.contents(of: "Playlists/Mix.m3u8").contains("../Music/Artist/Album/Clocks.m4a"))
        let manifest = AudioPlayerControlFiles(volumeURL: volume.volumeURL).manifest()
        #expect(manifest.entries[song.sourcePath]?.path == "Music/Artist/Album/Clocks.m4a")
        #expect(manifest.playlistPaths == ["Playlists/Mix.m3u8"])
    }

    @Test func secondSyncChangesNothing() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks")
        _ = try await PlayerTrackSyncer(device: volume.device).sync(try await plan(on: volume, selected: [song]))
        #expect(try await plan(on: volume, selected: [song]).isEmpty)
    }

    @Test func removingTheLastSongOfAnAlbumDeletesItsFolders() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks")
        let syncer = try PlayerTrackSyncer(device: volume.device)
        _ = try await syncer.sync(try await plan(on: volume, selected: [song]))
        let summary = try await syncer.sync(try await plan(on: volume, selected: [], unselected: [song]))
        #expect(summary.removed == 1)
        #expect(!volume.fileExists("Music/Artist"))
        #expect(volume.fileExists("Music"))
        #expect(AudioPlayerControlFiles(volumeURL: volume.volumeURL).manifest().entries.isEmpty)
    }

    @Test func turningOnNumberingRenamesInPlace() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks", track: 5)
        let syncer = try PlayerTrackSyncer(device: volume.device)
        _ = try await syncer.sync(try await plan(on: volume, selected: [song]))
        var numbered = config
        numbered.preserveTrackSorting = true
        let renaming = try await plan(on: volume, selected: [song], config: numbered)
        #expect(renaming.moves.count == 1 && renaming.copies.isEmpty)
        _ = try await syncer.sync(renaming)
        #expect(volume.fileExists("Music/Artist/Album/05 Clocks.m4a"))
        #expect(!volume.fileExists("Music/Artist/Album/Clocks.m4a"))
    }

    @Test func preservingTheAlbumArtistRetagsOnlyTheCopy() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let source = try AudioFixtureWriter.writeSilence(to: volume.libraryURL.appending(path: "Song.m4a"))
        try MP4TagWriter().write(TagChanges(title: "Song", artist: "Guest", albumArtist: "Main"), to: source)
        let draft = ITunesTrackDraft(title: "Song", artist: "Guest", album: "Album", albumArtist: "Main",
                                     fileSize: 1, codec: .aac)
        let request = IPodSyncRequest(sourceURL: source, draft: draft.preservingAlbumArtist(),
                                      source: SyncSource(fileSize: 1, modificationDate: .now, artworkFingerprint: nil,
                                                         preservedAlbumArtist: true))
        _ = try await PlayerTrackSyncer(device: volume.device).sync(try await plan(on: volume, selected: [request]))
        let copy = volume.volumeURL.appending(path: "Music/Main/Album/Song.m4a")
        let copied = try #require(try await AudioMetadataReader().read(copy)).tags
        #expect(copied.title == "Song — Guest" && copied.artist == "Main")
        #expect(try #require(try await AudioMetadataReader().read(source)).tags.artist == "Guest")
    }

    @Test func cancellingKeepsWhatWasCopied() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let songs = try (1...3).map { try volume.request("Song \($0)") }
        let plan = try await plan(on: volume, selected: songs)
        let syncer = try PlayerTrackSyncer(device: volume.device)
        let task = Task {
            try await syncer.sync(plan) { progress in
                if progress.completed == 1 { withUnsafeCurrentTask { $0?.cancel() } }
            }
        }
        let summary = try await task.value
        #expect(summary.wasCancelled && summary.added == 1)
        #expect(AudioPlayerControlFiles(volumeURL: volume.volumeURL).manifest().entries.count == 1)
    }

    @Test func missingLibraryFilesFailWithoutLosingEarlierCopies() async throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let first = try volume.request("A First")
        let gone = try volume.request("B Gone")
        try FileManager.default.removeItem(at: gone.sourceURL)
        let plan = try await plan(on: volume, selected: [first, gone])
        await #expect(throws: PlayerSyncError.missingSource("B Gone.m4a")) {
            try await PlayerTrackSyncer(device: volume.device).sync(plan)
        }
        #expect(AudioPlayerControlFiles(volumeURL: volume.volumeURL).manifest().entries.count == 1)
    }
}
