import Foundation
import Testing
@testable import SyncMyPod

@MainActor
struct IPodSortNameTests {
    private func track(artist: String, sortArtist: String? = nil) -> LibraryTrack {
        let track = LibraryTrack(filePath: "/Music/\(artist)/Album/Song.m4a")
        track.title = "Song"
        track.artist = artist
        track.album = "Album"
        track.sortArtistTag = sortArtist
        return track
    }

    private func strings(for track: LibraryTrack) throws -> [ITunesStringField: String] {
        let draft = track.syncRequest(preservingAlbumArtist: false).draft
        var editor = try ITunesDBEditor(root: ITunesDBRecordParser(data: ITunesDBFixtureBuilder(tracks: [], playlists: [
            FixturePlaylist(id: 1, name: "iPod", isMaster: true, trackIDs: [])
        ]).build()).parse())
        _ = editor.addTrack(draft)
        return try #require(try ITunesDBParser(data: editor.serialized()).parse().tracks.first).strings
    }

    @Test func generatesSortNameForLeadingArticle() throws {
        #expect(try strings(for: track(artist: "The Killers"))[.sortArtist] == "Killers")
    }

    @Test func writesNoSortNameWhenThePlainNameSortsCorrectly() throws {
        let strings = try strings(for: track(artist: "Modest Mouse"))
        #expect(strings[.sortArtist] == nil && strings[.sortTitle] == nil && strings[.sortAlbum] == nil)
    }

    @Test func prefersTheFilesSortTag() throws {
        #expect(try strings(for: track(artist: "The Beatles", sortArtist: "Beatles, The"))[.sortArtist] == "Beatles, The")
    }
}
