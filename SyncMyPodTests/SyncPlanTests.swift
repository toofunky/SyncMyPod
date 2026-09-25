import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct SyncPlanTests {
    private func track(_ title: String, artist: String, album: String, albumArtist: String = "",
                       size: Int = 1_000) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        track.fileSize = size
        return track
    }

    private var library: [LibraryTrack] {
        [track("Clocks", artist: "Coldplay", album: "A Rush of Blood", size: 7_000),
         track("Yellow", artist: "Coldplay", album: "Parachutes", size: 5_000),
         track("Hey Ya!", artist: "OutKast", album: "Speakerboxxx", size: 6_000),
         track("Crazy", artist: "Gnarls Barkley", album: "Now 24", albumArtist: "Various Artists"),
         track("Untagged", artist: "", album: "")]
    }

    @Test func matchKeyIgnoresCaseAndSurroundingSpaces() {
        let draft = ITunesTrackDraft(title: " Clocks", artist: "COLDPLAY", album: "A Rush", fileSize: 10)
        let onDevice = ITunesTrack.preview(id: 1, title: "clocks", artist: "Coldplay", album: "a rush ", duration: 0)
        #expect(IPodTrackMatchKey(draft) == IPodTrackMatchKey(title: "clocks", artist: "coldplay", album: "a rush",
                                                              fileSize: 10))
        #expect(IPodTrackMatchKey(onDevice).title == "clocks")
    }

    @Test func treeGroupsByAlbumArtistAndSortsByName() {
        let artists = SyncTreeBuilder.artists(from: library)
        #expect(artists.map(\.name) == ["Coldplay", "OutKast", "Unknown Artist", "Various Artists"])
        #expect(artists[0].albums.map(\.title) == ["A Rush of Blood", "Parachutes"])
        #expect(artists[0].albums[0].byteCount == 7_000)
        #expect(artists[2].albums.map(\.title) == ["Unknown Album"])
    }

    @Test func allSongsPlansEveryTrackNotOnTheDevice() {
        let tracks = library
        let onDevice: Set = [IPodTrackMatchKey(tracks[0].syncRequest.draft)]
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

    @Test func customPlanWithNothingSelectedIsEmpty() {
        let plan = SyncPlan.make(tracks: library, mode: .custom, selectedAlbums: [], onDevice: [])
        #expect(plan.requests.isEmpty && plan.selectedCount == 0)
    }
}
