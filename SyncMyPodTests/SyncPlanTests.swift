import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct SyncPlanTests {
    private func track(_ title: String, artist: String, album: String, albumArtist: String = "",
                       genre: String = "", size: Int = 1_000) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        track.genre = genre
        track.fileSize = size
        track.scanVersion = LibraryTrack.currentScanVersion
        return track
    }

    private var library: [LibraryTrack] {
        [track("Clocks", artist: "Coldplay", album: "A Rush of Blood", genre: "Rock", size: 7_000),
         track("Yellow", artist: "Coldplay", album: "Parachutes", genre: "Rock ", size: 5_000),
         track("Hey Ya!", artist: "OutKast", album: "Speakerboxxx", genre: "Hip-Hop", size: 6_000),
         track("Crazy", artist: "Gnarls Barkley", album: "Now 24", albumArtist: "Various Artists", genre: "Soul"),
         track("Untagged", artist: "", album: "")]
    }

    private var snapshots: [SyncTrackSnapshot] { library.map { $0.syncSnapshot(preservingAlbumArtist: false) } }

    private func deviceTrack(for track: LibraryTrack, id: UInt32 = 1) -> ITunesTrack {
        ITunesTrack(id: id, databaseID: UInt64(id) * 10, strings: [.title: track.title, .artist: track.artist,
                                                                   .album: track.album],
                    duration: 0, fileSize: track.fileSize, trackNumber: 0, trackCount: 0, discNumber: 0,
                    discCount: 0, year: 0, bitrate: 0, sampleRate: 0, rating: 0, playCount: 0, mediaType: 1,
                    dateAdded: nil, lastPlayed: nil, lastModified: nil)
    }

    @Test func matchKeyIgnoresCaseAndSurroundingSpaces() {
        let draft = ITunesTrackDraft(title: " Clocks", artist: "COLDPLAY", album: "A Rush", fileSize: 10)
        let onDevice = ITunesTrack.preview(id: 1, title: "clocks", artist: "Coldplay", album: "a rush ", duration: 0)
        #expect(IPodTrackMatchKey(draft) == IPodTrackMatchKey(title: "clocks", artist: "coldplay", album: "a rush",
                                                              fileSize: 10))
        #expect(IPodTrackMatchKey(onDevice).title == "clocks")
    }

    @Test func treeGroupsByAlbumArtistAndSortsByName() {
        let artists = SyncTreeBuilder.artists(from: snapshots)
        #expect(artists.map(\.name) == ["Coldplay", "OutKast", "Unknown Artist", "Various Artists"])
        #expect(artists[0].albums.map(\.title) == ["A Rush of Blood", "Parachutes"])
        #expect(artists[0].albums[0].byteCount == 7_000)
        #expect(artists[2].albums.map(\.title) == ["Unknown Album"])
    }

    @Test func allSongsPlansEveryTrackNotOnTheDevice() {
        let tracks = library
        let onDevice = [deviceTrack(for: tracks[0])]
        let plan = SyncPlan.make(tracks: tracks, mode: .allSongs, selectedAlbums: [], onDevice: onDevice)
        #expect(plan.requests.count == 4)
        #expect(plan.alreadyOnDeviceCount == 1)
        #expect(!plan.requests.map(\.draft.title).contains("Clocks"))
    }

    @Test func customPlansOnlySelectedAlbums() {
        let tracks = library
        let selected: Set = [tracks[0].syncAlbumKey, tracks[2].syncAlbumKey]
        let plan = SyncPlan.make(tracks: tracks, mode: .custom, selectedAlbums: selected, onDevice: [])
        #expect(plan.requests.map(\.draft.title) == ["Clocks", "Hey Ya!"])
        #expect(plan.byteCount == 13_000)
    }

    @Test func genresGroupTrimmedNamesAndNameUntaggedSongs() {
        let genres = SyncTreeBuilder.genres(from: snapshots)
        #expect(genres.map(\.name) == ["Hip-Hop", "Rock", "Soul", "Unknown Genre"])
        #expect(genres[1].trackCount == 2 && genres[1].byteCount == 12_000)
    }

    @Test func customPlansSelectedGenresAlongsideAlbums() {
        let tracks = library
        let plan = SyncPlan.make(tracks: tracks, mode: .custom, selectedAlbums: [tracks[2].syncAlbumKey],
                                 selectedGenres: ["Rock", "Hip-Hop"], onDevice: [])
        #expect(plan.requests.map(\.draft.title) == ["Clocks", "Yellow", "Hey Ya!"])
    }

    @Test func customPlanWithNothingSelectedIsEmpty() {
        let plan = SyncPlan.make(tracks: library, mode: .custom, selectedAlbums: [], onDevice: [])
        #expect(plan.requests.isEmpty && plan.selectedCount == 0)
    }

    @Test func customPlanRemovesUnselectedLibraryTracksOnly() {
        let tracks = library
        let stranger = ITunesTrack.preview(id: 9, title: "iTunes Song", artist: "Other", album: "Else", duration: 0)
        let onDevice = [deviceTrack(for: tracks[0], id: 1), deviceTrack(for: tracks[1], id: 2), stranger]
        let plan = SyncPlan.make(tracks: tracks, mode: .custom, selectedAlbums: [tracks[0].syncAlbumKey],
                                 onDevice: onDevice)
        #expect(plan.removals.map(\.title) == ["Yellow"])
        #expect(plan.removalIDs == [20])
        #expect(plan.requests.isEmpty)
    }

    @Test func allSongsNeverRemoves() {
        let tracks = library
        let plan = SyncPlan.make(tracks: tracks, mode: .allSongs, selectedAlbums: [],
                                 onDevice: [deviceTrack(for: tracks[1])])
        #expect(plan.removals.isEmpty)
    }

    private func adoptedManifest(_ tracks: [LibraryTrack], onDevice: [ITunesTrack]) -> SyncManifest {
        var manifest = SyncManifest()
        _ = manifest.adopt(tracks.map { $0.syncRequest(preservingAlbumArtist: false) }, onDevice: onDevice)
        return manifest
    }

    @Test func retaggedFileIsAnUpdateNotAnAddition() {
        let clocks = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let onDevice = [deviceTrack(for: clocks, id: 1)]
        let manifest = adoptedManifest([clocks], onDevice: onDevice)
        clocks.title = "Clocks (Remastered)"
        clocks.fileSize += 12
        let plan = SyncPlan.make(tracks: [clocks], mode: .allSongs, selectedAlbums: [], onDevice: onDevice,
                                 manifest: manifest)
        #expect(plan.requests.isEmpty)
        #expect(plan.updates.map(\.databaseID) == [10])
        #expect(plan.updates.first?.artworkChanged == false)
    }

    @Test func changedCoverIsAnUpdateWithNewArtwork() {
        let clocks = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let onDevice = [deviceTrack(for: clocks, id: 1)]
        let manifest = adoptedManifest([clocks], onDevice: onDevice)
        clocks.artworkFingerprint = "new cover"
        let plan = SyncPlan.make(tracks: [clocks], mode: .allSongs, selectedAlbums: [], onDevice: onDevice,
                                 manifest: manifest)
        #expect(plan.updates.first?.artworkChanged == true)
    }

    @Test func unchangedOrUnscannedFilesAreLeftAlone() {
        let tracks = library
        let onDevice = [deviceTrack(for: tracks[0], id: 1), deviceTrack(for: tracks[1], id: 2)]
        let manifest = adoptedManifest(tracks, onDevice: onDevice)
        tracks[1].scanVersion = 0
        tracks[1].fileSize += 1
        let plan = SyncPlan.make(tracks: Array(tracks.prefix(2)), mode: .allSongs, selectedAlbums: [],
                                 onDevice: onDevice, manifest: manifest)
        #expect(plan.isEmpty && plan.updates.isEmpty)
    }

    @Test func entryForAMissingTrackFallsBackToTags() {
        let clocks = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let manifest = adoptedManifest([clocks], onDevice: [deviceTrack(for: clocks, id: 1)])
        let plan = SyncPlan.make(tracks: [clocks], mode: .allSongs, selectedAlbums: [], onDevice: [],
                                 manifest: manifest)
        #expect(plan.requests.count == 1 && plan.updates.isEmpty)
    }

    @Test func unselectedRetaggedFileIsRemovedThroughItsEntry() {
        let tracks = library
        let onDevice = [deviceTrack(for: tracks[0], id: 1), deviceTrack(for: tracks[1], id: 2)]
        let manifest = adoptedManifest(tracks, onDevice: onDevice)
        tracks[1].title = "Yellow (Live)"
        let plan = SyncPlan.make(tracks: tracks, mode: .custom, selectedAlbums: [tracks[0].syncAlbumKey],
                                 onDevice: onDevice, manifest: manifest)
        #expect(plan.removalIDs == [20])
    }

    @Test func updatesAreWorkToDo() {
        let clocks = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let onDevice = [deviceTrack(for: clocks, id: 1)]
        let manifest = adoptedManifest([clocks], onDevice: onDevice)
        clocks.fileSize += 5
        let plan = SyncPlan.make(tracks: [clocks], mode: .allSongs, selectedAlbums: [], onDevice: onDevice,
                                 manifest: manifest)
        #expect(!plan.isEmpty)
        #expect(plan.alreadyOnDeviceCount == 0)
        #expect(plan.updatedByteCount == Int64(clocks.fileSize))
        #expect(plan.syncRequests.map(\.draft.title) == ["Clocks"])
    }

    @Test func strayTracksAreRemovedEvenWhenSyncingAllSongs() {
        let tracks = library
        let onDevice = [deviceTrack(for: tracks[0], id: 1), deviceTrack(for: tracks[1], id: 2)]
        let manifest = adoptedManifest(tracks, onDevice: onDevice)
        let plan = SyncPlan.make(tracks: [tracks[0]], mode: .allSongs, selectedAlbums: [], onDevice: onDevice,
                                 manifest: manifest, strayDatabaseIDs: [20])
        #expect(plan.removalIDs == [20])
    }

    @Test func fileWithTheSameTagsAsAnotherFilesCopyIsNotAddedAgain() {
        let original = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let copy = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        copy.filePath = "/Elsewhere/Clocks.m4a"
        let onDevice = [deviceTrack(for: original, id: 1)]
        let manifest = adoptedManifest([original], onDevice: onDevice)
        let plan = SyncPlan.make(tracks: [original, copy], mode: .allSongs, selectedAlbums: [], onDevice: onDevice,
                                 manifest: manifest)
        #expect(plan.isEmpty)
    }

    @Test func looselyMatchedTrackIsUpdatedWithItsCover() {
        let sign = track("The Sign", artist: "Ace of Base Test", album: "The Sign")
        sign.duration = 192.445
        let device = ITunesTrack(id: 1, databaseID: 10,
                                 strings: [.title: "The Sign", .artist: "Ace of Base", .album: "The Sign"],
                                 duration: 192.445, fileSize: sign.fileSize, trackNumber: 0, trackCount: 0,
                                 discNumber: 0, discCount: 0, year: 0, bitrate: 0, sampleRate: 0, rating: 0,
                                 playCount: 0, mediaType: 1, dateAdded: nil, lastPlayed: nil, lastModified: nil)
        var manifest = SyncManifest()
        _ = manifest.adoptLoosely([sign.syncRequest(preservingAlbumArtist: false)], onDevice: [device])
        let plan = SyncPlan.make(tracks: [sign], mode: .allSongs, selectedAlbums: [], onDevice: [device],
                                 manifest: manifest)
        #expect(plan.requests.isEmpty)
        #expect(plan.updates.map(\.databaseID) == [10])
        #expect(plan.updates.first?.artworkChanged == true)
    }

    private func playlist(_ tracks: [LibraryTrack], id: UInt64 = 77, name: String = "Mix") -> IPodPlaylistRequest {
        IPodPlaylistRequest(id: id, name: name, createdAt: .now, tracks: tracks.map { $0.syncRequest(preservingAlbumArtist: false) })
    }

    @Test func customSyncIncludesPlaylistSongs() {
        let tracks = library
        let plan = SyncPlan.make(tracks: tracks, mode: .custom, selectedAlbums: [], playlists: [playlist([tracks[2]])],
                                 onDevice: [])
        #expect(plan.requests.map(\.draft.title) == ["Hey Ya!"])
        #expect(plan.playlistChangeCount == 1)
    }

    @Test func matchingPlaylistOnTheIPodNeedsNoSync() {
        let clocks = track("Clocks", artist: "Coldplay", album: "A Rush of Blood")
        let onDevice = [deviceTrack(for: clocks, id: 1)]
        let copy = ITunesPlaylist(id: 77, name: "Mix", isMaster: false, createdAt: nil, trackIDs: [1])
        let plan = SyncPlan.make(tracks: [clocks], mode: .allSongs, selectedAlbums: [], playlists: [playlist([clocks])],
                                 onDevice: onDevice, devicePlaylists: [copy])
        #expect(plan.isEmpty)
    }

    @Test func renamedOrReorderedPlaylistNeedsSync() {
        let tracks = [track("Clocks", artist: "Coldplay", album: "A"), track("Yellow", artist: "Coldplay", album: "B")]
        let onDevice = [deviceTrack(for: tracks[0], id: 1), deviceTrack(for: tracks[1], id: 2)]
        let copy = ITunesPlaylist(id: 77, name: "Mix", isMaster: false, createdAt: nil, trackIDs: [1, 2])
        let renamed = SyncPlan.make(tracks: tracks, mode: .allSongs, selectedAlbums: [],
                                    playlists: [playlist(tracks, name: "Renamed")], onDevice: onDevice,
                                    devicePlaylists: [copy])
        let reordered = SyncPlan.make(tracks: tracks, mode: .allSongs, selectedAlbums: [],
                                      playlists: [playlist(tracks.reversed())], onDevice: onDevice,
                                      devicePlaylists: [copy])
        #expect(renamed.playlistChangeCount == 1)
        #expect(reordered.playlistChangeCount == 1)
    }

    @Test func removedPlaylistThisAppWroteNeedsSync() {
        let copy = ITunesPlaylist(id: 77, name: "Mix", isMaster: false, createdAt: nil, trackIDs: [])
        let other = ITunesPlaylist(id: 88, name: "On-The-Go", isMaster: false, createdAt: nil, trackIDs: [])
        let manifest = SyncManifest().managingPlaylists([77])
        let plan = SyncPlan.make(tracks: [], mode: .allSongs, selectedAlbums: [], onDevice: [],
                                 devicePlaylists: [copy, other], manifest: manifest)
        #expect(plan.playlistChangeCount == 1)
    }
}
