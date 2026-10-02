import Foundation
import Testing
@testable import SyncMyPod

struct LibraryArtistGroupingTests {
    private func track(_ title: String, artist: String, album: String = "X", albumArtist: String = "") -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/\(album)/\(title).m4a")
        track.title = title
        track.artist = artist
        track.album = album
        track.albumArtist = albumArtist
        return track
    }

    @Test func groupsByAlbumArtistAndCountsAlbums() {
        let artists = LibraryArtist.artists(from: [
            track("a", artist: "One", album: "Hits", albumArtist: "Various Artists"),
            track("b", artist: "Two", album: "Hits", albumArtist: "Various Artists"),
            track("c", artist: "One", album: "Solo"),
            track("d", artist: "One", album: "Debut"),
        ])
        #expect(artists.map(\.name) == ["One", "Various Artists"])
        #expect(artists.map(\.albumCount) == [2, 1])
    }

    @Test func sortsAlphabeticallyIgnoringArticles() {
        let artists = LibraryArtist.artists(from: [track("a", artist: "The Killers"), track("b", artist: "Beatles"),
                                                   track("c", artist: "Modest Mouse"), track("d", artist: "")])
        #expect(artists.map(\.name) == ["Beatles", "The Killers", "Modest Mouse", LibraryTrack.unknownArtist])
    }
}
