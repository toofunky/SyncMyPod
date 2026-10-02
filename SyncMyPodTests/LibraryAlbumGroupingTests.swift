import Foundation
import Testing
@testable import SyncMyPod

struct LibraryAlbumGroupingTests {
    private func track(_ title: String, artist: String = "A", album: String = "X", albumArtist: String = "",
                       number: Int = 0, year: Int = 0, fingerprint: String? = nil) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        track.trackNumber = number
        track.year = year
        track.artworkFingerprint = fingerprint
        return track
    }

    @Test func albumArtistKeepsCompilationsTogether() {
        let albums = LibraryAlbum.albums(from: [
            track("a", artist: "One", album: "Hits", albumArtist: "Various Artists"),
            track("b", artist: "Two", album: "Hits", albumArtist: "Various Artists"),
        ])
        #expect(albums.count == 1)
        #expect(albums.first?.artist == "Various Artists")
        #expect(albums.first?.trackCount == 2)
    }

    @Test func sameAlbumNameByDifferentArtistsStaysApart() {
        let albums = LibraryAlbum.albums(from: [track("a", artist: "One", album: "Greatest Hits"),
                                                track("b", artist: "Two", album: "Greatest Hits")])
        #expect(albums.count == 2)
    }

    @Test func missingAlbumFallsBackToUnknownAlbum() {
        let albums = LibraryAlbum.albums(from: [track("a", album: "")])
        #expect(albums.first?.title == LibraryTrack.unknownAlbum)
    }

    @Test func yearIsLatestTaggedYear() {
        let albums = LibraryAlbum.albums(from: [track("a", year: 0), track("b", year: 1999), track("c", year: 1997)])
        #expect(albums.first?.year == 1999)
    }

    @Test func artworkComesFromFirstSongInPlayOrderWithCover() {
        let albums = LibraryAlbum.albums(from: [track("c", number: 3, fingerprint: "late"),
                                                track("a", number: 1),
                                                track("b", number: 2, fingerprint: "early")])
        #expect(albums.first?.artworkFingerprint == "early")
        #expect(albums.first?.artworkPath == "/Music/A/X/b.m4a")
    }
}
