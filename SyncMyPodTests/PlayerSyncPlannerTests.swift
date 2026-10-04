import Foundation
import Testing
@testable import SyncMyPod

struct PlayerSyncPlannerTests {
    private let config = AudioPlayerConfig(name: "Player", rootPath: "", musicFolder: "Music",
                                           playlistFolder: "Playlists")

    private func planner(_ config: AudioPlayerConfig? = nil, entries: [String: PlayerManifestEntry] = [:],
                         present: Set<String> = [], missing: Set<String> = [],
                         playlists: [String: String] = [:], playlistPaths: Set<String> = []) -> PlayerSyncPlanner {
        let manifest = PlayerSyncManifest(entries: entries, playlistPaths: playlistPaths)
        return PlayerSyncPlanner(config: config ?? self.config, manifest: manifest,
                                 presentSizes: Dictionary(uniqueKeysWithValues: present.map { ($0, 512) }),
                                 missingSources: missing, existingPlaylists: playlists)
    }

    @Test func newSongsGoUnderAlbumArtistAndAlbumWithTheirOwnName() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks", album: "A Rush of Blood", artist: "Coldplay", file: "x/05 clocks.m4a")
        let plan = planner().plan(selected: [song], playlists: nil)
        #expect(plan.copies.map(\.destination) == ["Music/Coldplay/A Rush of Blood/05 clocks.m4a"])
    }

    @Test func numberingNamesFilesByDiscAndTrack() throws {
        var numbered = config
        numbered.preserveTrackSorting = true
        let volume = try TemporaryPlayerVolume(config: numbered)
        let single = try volume.request("Clocks", file: "a.m4a", track: 5, disc: 1, discCount: 1)
        let double = try volume.request("Yellow", file: "b.M4A", track: 3, disc: 2, discCount: 2)
        let plan = planner(numbered).plan(selected: [single, double], playlists: nil)
        #expect(plan.copies.map(\.destination) == ["Music/Artist/Album/05 Clocks.m4a",
                                                   "Music/Artist/Album/2-03 Yellow.m4a"])
    }

    @Test func blankMusicFolderUsesTheRoot() throws {
        let rooted = AudioPlayerConfig(name: "Player", rootPath: "Media/", musicFolder: " ")
        let volume = try TemporaryPlayerVolume(config: rooted)
        let plan = planner(rooted).plan(selected: [try volume.request("Song")], playlists: nil)
        #expect(plan.copies.map(\.destination) == ["Media/Artist/Album/Song.m4a"])
    }

    @Test func unchangedSongsAreSkippedChangedOnesUpdatedAndRenamedOnesMoved() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let same = try volume.request("Same")
        let edited = try volume.request("Edited")
        let retagged = try volume.request("Retagged", album: "New Album")
        let stale = SyncSource(fileSize: 1, modificationDate: .distantPast, artworkFingerprint: nil)
        let entries = [same.sourcePath: PlayerManifestEntry(path: "Music/Artist/Album/Same.m4a", source: same.source),
                       edited.sourcePath: PlayerManifestEntry(path: "Music/Artist/Album/Edited.m4a", source: stale),
                       retagged.sourcePath: PlayerManifestEntry(path: "Music/Artist/Album/Retagged.m4a",
                                                                source: retagged.source)]
        let plan = planner(entries: entries, present: Set(entries.values.map(\.path)))
            .plan(selected: [same, edited, retagged], playlists: nil)
        #expect(plan.copies.isEmpty)
        #expect(plan.updates.map(\.destination) == ["Music/Artist/Album/Edited.m4a"])
        #expect(plan.moves == [PlayerFileMove(sourcePath: retagged.sourcePath, from: "Music/Artist/Album/Retagged.m4a",
                                              to: "Music/Artist/New Album/Retagged.m4a")])
        #expect(plan.totals.alreadyOnDeviceCount == 2)
    }

    @Test func songsMissingFromThePlayerAreCopiedAgain() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Song")
        let entries = [song.sourcePath: PlayerManifestEntry(path: "Music/Artist/Album/Song.m4a", source: song.source)]
        #expect(planner(entries: entries).plan(selected: [song], playlists: nil).copies.count == 1)
    }

    @Test func onlyRecordedCopiesOfUnselectedOrDeletedSongsAreRemoved() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let unselected = try volume.request("Unselected")
        let neverSynced = try volume.request("Never Synced")
        let entries = ["/gone.m4a": PlayerManifestEntry(path: "Music/A/B/gone.m4a", source: nil),
                       "/offline.m4a": PlayerManifestEntry(path: "Music/A/B/offline.m4a", source: nil),
                       unselected.sourcePath: PlayerManifestEntry(path: "Music/A/B/Unselected.m4a", source: nil)]
        let plan = planner(entries: entries, present: Set(entries.values.map(\.path)), missing: ["/gone.m4a"])
            .plan(selected: [], unselected: [unselected, neverSynced], playlists: nil)
        #expect(plan.removals.map(\.path) == ["Music/A/B/gone.m4a", "Music/A/B/Unselected.m4a"])
        #expect(plan.totals.removeBytes == 1_024)
    }

    @Test func clashingNamesAreNumberedIgnoringCase() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let first = try volume.request("One", file: "a/Song.m4a")
        let second = try volume.request("Two", file: "b/song.m4a")
        let kept = ["/kept.m4a": PlayerManifestEntry(path: "Music/Artist/Album/SONG.m4a", source: nil)]
        let plan = planner(entries: kept).plan(selected: [first, second], playlists: nil)
        #expect(plan.copies.map(\.destination) == ["Music/Artist/Album/Song (2).m4a",
                                                   "Music/Artist/Album/song (3).m4a"])
    }

    @Test func playlistsPointAtTheSongsRelativeToThePlaylistFolder() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Clocks", artist: "Coldplay")
        let playlist = IPodPlaylistRequest(id: 1, name: "Road/Trip", createdAt: .now, tracks: [song])
        let plan = planner().plan(selected: [song], playlists: [playlist])
        #expect(plan.playlists?.map(\.path) == ["Playlists/Road_Trip.m3u8"])
        #expect(plan.playlists?.first?.contents
            == "#EXTM3U\n#EXTINF:0,Coldplay - Clocks\n../Music/Coldplay/Album/Clocks.m4a\n")
        #expect(plan.playlistChangeCount == 1)
    }

    @Test func playlistsCountOnlyRealChangesAndNeverReplaceOtherPlaylists() throws {
        let volume = try TemporaryPlayerVolume(config: config)
        let song = try volume.request("Song")
        let mix = IPodPlaylistRequest(id: 1, name: "Mix", createdAt: .now, tracks: [song])
        let ours = planner().plan(selected: [song], playlists: [mix]).playlists?.first?.contents
        let existing = ["Playlists/Mix.m3u8": "#EXTM3U\n", "Playlists/Old.m3u8": ours ?? ""]
        let plan = planner(playlists: existing, playlistPaths: ["Playlists/Old.m3u8"])
            .plan(selected: [song], playlists: [mix])
        #expect(plan.playlists?.map(\.path) == ["Playlists/Mix (2).m3u8"])
        #expect(plan.stalePlaylistPaths == ["Playlists/Old.m3u8"])
        #expect(plan.playlistChangeCount == 2)
    }
}
