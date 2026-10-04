import Foundation
import Testing
@testable import SyncMyPod

struct PlayerSidecarTests {
    private func config(covers: Bool = true, lyrics: Bool = true, sorting: Bool = false) -> AudioPlayerConfig {
        var config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music")
        config.copyCovers = covers
        config.copyLyricFiles = lyrics
        config.preserveTrackSorting = sorting
        return config
    }

    private func sidecars(for requests: [IPodSyncRequest], _ config: AudioPlayerConfig) async -> LibrarySidecars {
        await LibrarySidecarFinder.find(besideSongsAt: requests.map(\.sourcePath), covers: config.copyCovers,
                                        lyrics: config.copyLyricFiles)
    }

    private func plan(on volume: TemporaryPlayerVolume, _ config: AudioPlayerConfig, selected: [IPodSyncRequest],
                      unselected: [IPodSyncRequest] = [],
                      playlists: [IPodPlaylistRequest]? = []) async throws -> PlayerSyncPlan {
        let contents = await PlayerDeviceContents.load(from: try volume.device)
        let found = await sidecars(for: selected + unselected, config)
        return contents.planner(for: config, sidecars: found)
            .plan(selected: selected, unselected: unselected, playlists: playlists)
    }

    @Test func findsCoversAndLyricsWhateverTheirCase() async throws {
        let volume = try TemporaryPlayerVolume(config: config())
        let song = try volume.request("Clocks", file: "Album/01 Clocks.mp3")
        try volume.librarySidecar("Album/Folder.JPG")
        try volume.librarySidecar("Album/COVER.png")
        try volume.librarySidecar("Album/01 clocks.LRC")
        try volume.librarySidecar("Album/back.jpg")
        let found = await sidecars(for: [song], config())
        #expect(found.covers(besideSongAt: song.sourcePath).map(\.fileName) == ["Folder.JPG", "COVER.png"])
        #expect(found.lyrics[song.sourcePath]?.fileName == "01 clocks.LRC")
    }

    @Test func lyricFilesTakeTheSongsNameOnThePlayer() async throws {
        let sorted = config(covers: false, sorting: true)
        let volume = try TemporaryPlayerVolume(config: sorted)
        let song = try volume.request("Clocks", file: "Album/clocks.mp3", track: 5)
        try volume.librarySidecar("Album/Clocks.lrc")
        let plan = try await plan(on: volume, sorted, selected: [song])
        #expect(plan.sidecarCopies.map(\.destination) == ["Music/Artist/Album/05 Clocks.lrc"])
    }

    @Test func coversGoIntoTheAlbumFolderInLowercase() async throws {
        let volume = try TemporaryPlayerVolume(config: config(lyrics: false))
        let first = try volume.request("One", file: "A/one.m4a")
        let second = try volume.request("Two", file: "B/two.m4a")
        try volume.librarySidecar("A/Cover.jpg")
        try volume.librarySidecar("B/folder.jpg")
        let plan = try await plan(on: volume, config(lyrics: false), selected: [first, second])
        #expect(plan.sidecarCopies.map(\.destination) == ["Music/Artist/Album/cover.jpg"])
    }

    @Test func nothingIsCopiedWhenTheOptionsAreOff() async throws {
        let off = config(covers: false, lyrics: false)
        let volume = try TemporaryPlayerVolume(config: off)
        let song = try volume.request("Clocks", file: "Album/Clocks.mp3")
        try volume.librarySidecar("Album/cover.jpg")
        try volume.librarySidecar("Album/Clocks.lrc")
        #expect(try await plan(on: volume, off, selected: [song]).sidecarCopies.isEmpty)
    }

    @Test func syncCopiesSidecarsThenRemovesThemWithTheSong() async throws {
        let volume = try TemporaryPlayerVolume(config: config())
        let song = try volume.request("Clocks", file: "Album/Clocks.mp3")
        try volume.librarySidecar("Album/Cover.JPG")
        try volume.librarySidecar("Album/clocks.LRC")
        let syncer = try PlayerTrackSyncer(device: volume.device)
        let summary = try await syncer.sync(try await plan(on: volume, config(), selected: [song]))
        #expect(summary.sidecarChangeCount == 2)
        #expect(volume.names(in: "Music/Artist/Album") == ["Clocks.mp3", "Clocks.lrc", "cover.jpg"])
        #expect(try await plan(on: volume, config(), selected: [song]).isEmpty)
        _ = try await syncer.sync(try await plan(on: volume, config(), selected: [], unselected: [song]))
        #expect(!volume.fileExists("Music/Artist"))
        #expect(AudioPlayerControlFiles(volumeURL: volume.volumeURL).manifest().sidecars.isEmpty)
    }

    @Test func editedLyricsAreCopiedAgain() async throws {
        let volume = try TemporaryPlayerVolume(config: config(covers: false))
        let song = try volume.request("Clocks", file: "Album/Clocks.mp3")
        let lyric = try volume.librarySidecar("Album/Clocks.lrc", contents: "[00:01]Old")
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(covers: false), selected: [song]))
        try Data("[00:01]New and longer".utf8).write(to: lyric)
        let plan = try await plan(on: volume, config(covers: false), selected: [song])
        #expect(plan.sidecarCopies.map(\.destination) == ["Music/Artist/Album/Clocks.lrc"])
    }

    @Test func addingSongsLeavesOtherSongsSidecarsAlone() async throws {
        let volume = try TemporaryPlayerVolume(config: config(covers: false))
        let first = try volume.request("One", file: "Album/One.mp3")
        let second = try volume.request("Two", file: "Album/Two.mp3")
        try volume.librarySidecar("Album/One.lrc")
        _ = try await PlayerTrackSyncer(device: volume.device)
            .sync(try await plan(on: volume, config(covers: false), selected: [first]))
        let adding = try await plan(on: volume, config(covers: false), selected: [second], playlists: nil)
        #expect(adding.sidecarRemovals.isEmpty)
    }

    @Test func manifestsSavedBeforeSidecarsStillLoad() throws {
        let older = ["entries": [String: Any](), "playlistPaths": ["Playlists/Mix.m3u8"]] as [String: Any]
        let data = try PropertyListSerialization.data(fromPropertyList: older, format: .binary, options: 0)
        let manifest = try PropertyListDecoder().decode(PlayerSyncManifest.self, from: data)
        #expect(manifest.playlistPaths == ["Playlists/Mix.m3u8"] && manifest.sidecars.isEmpty)
    }
}
