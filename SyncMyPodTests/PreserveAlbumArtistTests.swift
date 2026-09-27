import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct PreserveAlbumArtistTests {
    private func track(artist: String, albumArtist: String) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/Lady Gaga/Mayhem/Die With A Smile.m4a")
        track.title = "Die With A Smile"
        track.artist = artist
        track.album = "Mayhem"
        track.albumArtist = albumArtist
        track.fileSize = 1_000
        track.scanVersion = LibraryTrack.currentScanVersion
        return track
    }

    @Test func movesTrackArtistIntoTitleWhenArtistsDisagree() {
        let draft = track(artist: "Bruno Mars", albumArtist: "Lady Gaga").syncRequest(preservingAlbumArtist: true).draft
        #expect(draft.title == "Die With A Smile — Bruno Mars")
        #expect(draft.artist == "Lady Gaga")
        #expect(draft.albumArtist == "Lady Gaga")
    }

    @Test func carriesSortNamesIntoTheMovedTitleAndArtist() {
        let library = track(artist: "The Weeknd", albumArtist: "The Chainsmokers")
        library.title = "The Song"
        library.sortAlbumArtistTag = "Chainsmokers, The"
        let draft = library.syncRequest(preservingAlbumArtist: true).draft
        #expect(draft.title == "The Song — The Weeknd")
        #expect(draft.sortTitle == "Song — The Weeknd")
        #expect(draft.sortArtist == "Chainsmokers, The")
        #expect(draft.sortAlbumArtist == "Chainsmokers, The")
    }

    @Test func leavesTagsAloneWhenOff() {
        let library = track(artist: "Bruno Mars", albumArtist: "Lady Gaga")
        let draft = library.syncRequest(preservingAlbumArtist: false).draft
        #expect(draft.title == "Die With A Smile" && draft.artist == "Bruno Mars")
        #expect(library.title == "Die With A Smile" && library.artist == "Bruno Mars")
    }

    @Test(arguments: [("Lady Gaga", "lady gaga "), ("Lady Gaga", ""), ("", "Lady Gaga")])
    func leavesTagsAloneWhenArtistsAgreeOrAreMissing(artist: String, albumArtist: String) {
        let request = track(artist: artist, albumArtist: albumArtist).syncRequest(preservingAlbumArtist: true)
        #expect(request.draft.title == "Die With A Smile" && request.draft.artist == artist)
        #expect(request.source?.preservedAlbumArtist == nil)
    }

    @Test func togglingUpdatesOnlyAffectedTracks() {
        let library = track(artist: "Bruno Mars", albumArtist: "Lady Gaga")
        let before = library.syncRequest(preservingAlbumArtist: false)
        let after = library.syncRequest(preservingAlbumArtist: true)
        let manifest = SyncManifest().recording([before], as: [before.sourcePath: 10])
        let device = ITunesTrack(id: 1, databaseID: 10, strings: [.title: library.title, .artist: library.artist,
                                                                  .album: library.album],
                                 duration: 0, fileSize: 1_000, trackNumber: 0, trackCount: 0, discNumber: 0,
                                 discCount: 0, year: 0, bitrate: 0, sampleRate: 0, rating: 0, playCount: 0,
                                 mediaType: 1, dateAdded: nil, lastPlayed: nil, lastModified: nil)
        let planner = SyncPlanner(manifest: manifest, onDevice: [device])
        #expect(planner.plan(selected: [before], unselected: []).updates.isEmpty)
        let update = planner.plan(selected: [after], unselected: []).updates.first
        #expect(update?.databaseID == 10 && update?.artworkChanged == false)
    }
}
